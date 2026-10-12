import math
import re
import sqlite3
import threading
import time
import unicodedata
from collections import Counter
from dataclasses import dataclass
from difflib import get_close_matches

from core.system_commands import SystemCommands
from storage.database import Database


# =========================================================
#  إعدادات قابلة للضبط
# =========================================================
@dataclass(frozen=True)
class VectoConfig:
    """
    كل القيم القابلة للضبط في مكان واحد. لتغيير شيء مرّر نسخة مخصصة:
        VectoEngine(config=VectoConfig(match_threshold=0.7, command_timeout=15))
    الكلاس غير قابل للتعديل بعد إنشائه (frozen) حتى لا تتغير القيم أثناء التشغيل.
    """

    # --- المطابقة ---
    match_threshold: float = 0.60    # أقل درجة تشابه (0..1) لتنفيذ أمر من قاعدة البيانات
    ambiguity_margin: float = 0.03   # أمران مختلفان بفارق درجات أقل من هذا → غامض
    confident_score: float = 0.95    # فوق هذه الدرجة لا نفحص الغموض أصلاً
    cosine_weight: float = 0.65      # وزن تشابه الجيب (cosine) في الدرجة النهائية
    coverage_weight: float = 0.35    # وزن "هل ذُكرت كل كلمات الأمر المحفوظ؟"
    fuzzy_cutoff: float = 0.84       # حساسية تصحيح الأخطاء الإملائية (كلما زادت صارت أصرم)
    fuzzy_min_length: int = 4        # لا تُصحَّح الكلمات الأقصر من هذا الطول

    # --- الفهرس وقاعدة البيانات ---
    index_max_age: float = 30.0      # أقصى عمر للفهرس قبل إعادة بنائه (ثوانٍ)
    db_timeout: float = 3.0          # أقصى انتظار لقفل قاعدة البيانات (ثوانٍ)

    # --- المهل الزمنية ---
    command_timeout: float = 30.0    # أقصى انتظار لتنفيذ أمر نظام (ثوانٍ)

    def __post_init__(self):
        for name in ("match_threshold", "ambiguity_margin", "confident_score", "fuzzy_cutoff"):
            if not 0.0 <= getattr(self, name) <= 1.0:
                raise ValueError(f"{name} must be between 0 and 1")
        if self.cosine_weight < 0 or self.coverage_weight < 0 \
                or self.cosine_weight + self.coverage_weight <= 0:
            raise ValueError("cosine_weight and coverage_weight must be >= 0 and not both zero")


CLOSE_SIGNAL = "__CLOSE__"


# =========================================================
#  تطبيع النص (عربي + إنجليزي)
# =========================================================
# التشكيل (U+0610-061A, U+064B-065F, U+0670, U+06D6-06ED) والتطويل (U+0640)
_DIACRITICS = re.compile("[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")
_TOKEN = re.compile(r"[^\W_]+")

_CHAR_MAP = {
    "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
    "ى": "ي", "ئ": "ي", "ة": "ه", "ؤ": "و",
}
for _i, (_ar, _fa) in enumerate(zip("٠١٢٣٤٥٦٧٨٩", "۰۱۲۳۴۵۶۷۸۹")):
    _CHAR_MAP[_ar] = str(_i)
    _CHAR_MAP[_fa] = str(_i)
_CHAR_MAP = str.maketrans(_CHAR_MAP)


def normalize_text(text):
    """يوحّد الأشكال: حروف صغيرة، حذف التشكيل والتطويل، توحيد الألف والياء والتاء المربوطة والأرقام"""
    text = unicodedata.normalize("NFKC", str(text)).casefold()
    return _DIACRITICS.sub("", text).translate(_CHAR_MAP)


def _stem(token):
    """تخفيف خفيف جداً: "ال" التعريف في العربية، وs/ing في الإنجليزية"""
    if token.isascii():
        if len(token) > 5 and token.endswith("ing"):
            return token[:-3]
        if len(token) > 3 and token.endswith("s") and not token.endswith("ss"):
            return token[:-1]
        return token
    if len(token) > 3 and token.startswith("ال"):
        return token[2:]
    return token


def tokenize(text):
    return [_stem(t) for t in _TOKEN.findall(normalize_text(text))]


# =========================================================
#  الفهرس: متجهات TF-IDF خفيفة (قواميس بدل متجهات كاملة)
# =========================================================
class _Entry:
    __slots__ = ("prompt_id", "payload", "vec", "norm", "total_idf")

    def __init__(self, prompt_id, payload, vec, norm, total_idf):
        self.prompt_id = prompt_id
        self.payload = payload
        self.vec = vec
        self.norm = norm
        self.total_idf = total_idf


class _Index:
    def __init__(self, rows, config):
        self.cfg = config
        docs = []
        for r in rows:
            tokens = tokenize(r["naw_query"] or "")
            if tokens and r["exec_payload"]:
                docs.append((r["prompt_id"], r["exec_payload"], tokens))

        n = len(docs)
        df = Counter()
        for _, _, tokens in docs:
            df.update(set(tokens))

        # idf مُلطَّف: الكلمة النادرة تزن أكثر من الكلمة المتكررة في كل الأوامر ("افتح" مثلاً)
        self.idf = {t: math.log((1 + n) / (1 + c)) + 1.0 for t, c in df.items()}
        self.default_idf = math.log(1 + n) + 1.0   # لكلمات المستخدم غير الموجودة في أي أمر
        self.vocab = sorted(self.idf)

        self.entries = []
        for prompt_id, payload, tokens in docs:
            vec = self._weigh(tokens)
            norm = math.sqrt(sum(v * v for v in vec.values()))
            total_idf = sum(self.idf[t] for t in vec)
            self.entries.append(_Entry(prompt_id, payload, vec, norm, total_idf))

    def _weigh(self, tokens):
        return {
            t: (1.0 + math.log(c)) * self.idf.get(t, self.default_idf)
            for t, c in Counter(tokens).items()
        }

    def _correct(self, token):
        """يصحّح الخطأ الإملائي البسيط بأقرب كلمة معروفة (للكلمات الأطول من 3 أحرف فقط)"""
        if token in self.idf or len(token) < self.cfg.fuzzy_min_length:
            return token
        close = get_close_matches(token, self.vocab, n=1, cutoff=self.cfg.fuzzy_cutoff)
        return close[0] if close else token

    def search(self, query):
        tokens = [self._correct(t) for t in tokenize(query)]
        if not tokens or not self.entries:
            return []

        qvec = self._weigh(tokens)
        qnorm = math.sqrt(sum(v * v for v in qvec.values()))
        scored = []
        cos_w, cov_w = self.cfg.cosine_weight, self.cfg.coverage_weight
        total_w = cos_w + cov_w

        for e in self.entries:
            dot = sum(w * e.vec[t] for t, w in qvec.items() if t in e.vec)
            if dot <= 0:
                continue   # لا توجد كلمة مشتركة إطلاقاً → لا يُعتبر مرشحاً
            cosine = dot / (qnorm * e.norm)
            matched = sum(self.idf[t] for t in e.vec if t in qvec)
            coverage = matched / e.total_idf
            scored.append(((cos_w * cosine + cov_w * coverage) / total_w, e))

        scored.sort(key=lambda x: x[0], reverse=True)
        return scored

    def best_match(self, query):
        """يرجّع (الأمر، الدرجة) أو None إذا لم يوجد تطابق واثق"""
        scored = self.search(query)
        if not scored:
            return None

        best_score, best = scored[0]
        if best_score < self.cfg.match_threshold:
            return None

        # أمران مختلفان بدرجتين متقاربتين = غامض → الأفضل ألا ننفّذ شيئاً بالتخمين
        if best_score < self.cfg.confident_score:
            for score, entry in scored[1:]:
                if entry.payload != best.payload:
                    if best_score - score < self.cfg.ambiguity_margin:
                        return None
                    break

        return best, best_score


# =========================================================
#  المحرك
# =========================================================
class VectoEngine:

    def __init__(self, DEV=False, db_path="database.db", config=None):
        self.DEV = DEV
        self.config = config or VectoConfig()

        # القاعدة الآن في AppData (دائمة)؛ تُنشأ من database.sql في أول تشغيل فقط
        db = Database(db_path_name=db_path, DEV=DEV)
        db.create_database()
        self.db_path = db.db_path

        # timeout: لا ننتظر قفل السيرفر (Flask) أكثر من بضع ثوانٍ بدل التعليق
        self.conn = sqlite3.connect(self.db_path, timeout=self.config.db_timeout)
        self.conn.row_factory = sqlite3.Row
        # المحرك يقرأ فقط الآن؛ هذا يمنع أي قفل كتابة من جهتنا على قاعدة يشاركها السيرفر
        self.conn.execute("PRAGMA query_only = ON")
        self.cursor = self.conn.cursor()

        self._index = None
        self._data_version = None
        self._loaded_at = 0.0

    # ---------- دوال قديمة محفوظة للتوافق (لم تعد تُستخدم في المطابقة) ----------
    def text_to_vector(self, text, vocabulary):
        words = text.lower().split()
        return [1 if word in words else 0 for word in vocabulary]

    def calculate_vector_norm(self, vec1, vec2):
        return math.sqrt(sum(math.pow(a - b, 2) for a, b in zip(vec1, vec2)))

    # ---------- الفهرس ----------
    def _get_index(self):
        """
        يبني الفهرس مرة واحدة ويعيد استخدامه. يُعاد بناؤه تلقائياً عند
        تغيّر قاعدة البيانات من اتصال آخر (مثل لوحة تحكم Flask)، أو
        بعد config.index_max_age ثانية كاحتياط.
        """
        version = self.cursor.execute("PRAGMA data_version").fetchone()[0]
        fresh = (
            self._index is not None
            and version == self._data_version
            and time.monotonic() - self._loaded_at < self.config.index_max_age
        )
        if fresh:
            return self._index

        rows = self.cursor.execute("""
            SELECT
                p.id AS prompt_id,
                p.naw_query,
                c.exec_payload
            FROM cmd_prompt p
            JOIN sys_cmd c ON p.cmd_id = c.id
        """).fetchall()

        self._index = _Index(rows, self.config)
        self._data_version = version
        self._loaded_at = time.monotonic()
        return self._index

    def _find_command(self, query):
        try:
            return self._get_index().best_match(query)
        except sqlite3.Error as e:
            # فشل القراءة (قفل/جدول ناقص) لا يجب أن يوقف المحادثة؛ نعيد بناء الفهرس لاحقاً
            self._index = None
            if self.DEV:
                print(f"[VectoEngine] DB error: {e}")
            return None

    # ---------- تشغيل دالة قد تتعلق مع مهلة زمنية ----------
    @staticmethod
    def _call_with_timeout(func, timeout, *args):
        box = {}

        def runner():
            try:
                box["value"] = func(*args)
            except BaseException as e:   # نمرّر أي خطأ للخيط الأصلي
                box["error"] = e

        t = threading.Thread(target=runner, daemon=True)
        t.start()
        t.join(timeout)
        if t.is_alive():
            raise TimeoutError()
        if "error" in box:
            raise box["error"]
        return box.get("value")

    def _run_command(self, payload):
        try:
            result = self._call_with_timeout(
                SystemCommands.execute_command, self.config.command_timeout, payload
            )
        except TimeoutError:
            return "⏱ استغرق تنفيذ الأمر وقتاً طويلاً فتوقفتُ عن انتظاره."
        except Exception as e:
            return f"⚠ تعذّر تنفيذ الأمر: {e}"

        if result is None or result == "":
            return "✓ Command executed."
        return str(result)

    # ---------- الأوامر التي تبدأ بـ / ----------
    def _handle_slash(self, query):
        parts = query.split(maxsplit=1)
        name = parts[0].lower()
        arg = parts[1].strip() if len(parts) > 1 else ""

        if name == "/help":
            return "Click on the Settings button then click on the About button to learn more."

        if name == "/close":
            return CLOSE_SIGNAL

        if name == "/cmd":
            if not arg:
                return "Usage: /cmd <command>"
            return self._run_command(arg)

        return "Unknown command. Type /help for available commands."

    # ---------- نقطة الدخول ----------
    def process_query(self, user_query: str):
        query = (user_query or "").strip()
        if not query:
            return "Please type something."

        if query.startswith("/"):
            return self._handle_slash(query)

        match = self._find_command(query)
        if match is not None:
            entry, score = match
            if self.DEV:
                print(f"[VectoEngine] matched prompt #{entry.prompt_id} score={score:.2f}")
            return self._run_command(entry.payload)

        return "Command not recognized. Type /help for available commands."

    def close(self):
        try:
            self.conn.close()
        except Exception:
            pass