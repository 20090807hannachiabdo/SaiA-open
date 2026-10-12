import os
import shutil
import sqlite3
import sys
from contextlib import closing

APP_NAME = "SaiA"

# ارفع هذا الرقم كلما غيّرت database.sql (جدول جديد، نموذج جديد، أوامر جديدة...)
# فيُطبَّق السكربت تلقائياً على القواعد الموجودة عند أول تشغيل بعدها.
SCHEMA_VERSION = 3

# أعمدة جدول user_preferences المسموح بتعديلها
PREF_COLUMNS = ("theme", "language", "user_nickname", "selected_model")


def get_app_data_dir():
    """مجلد بيانات التطبيق الدائم (C:\\Users\\<user>\\AppData\\Roaming\\SaiA على ويندوز)"""
    if sys.platform == "win32":
        base = os.getenv("APPDATA") or os.path.expanduser("~")
    elif sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support")
    else:
        base = os.getenv("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    path = os.path.join(base, APP_NAME)
    os.makedirs(path, exist_ok=True)
    return path


def _resource_dir():
    """مكان ملفات القراءة فقط المضمّنة (مثل database.sql)"""
    if getattr(sys, "frozen", False):
        return os.path.join(getattr(sys, "_MEIPASS", os.path.dirname(sys.executable)), "storage")
    return os.path.dirname(os.path.abspath(__file__))


class Database:
    def __init__(self, sql_path_name="database.sql", db_path_name="database.db", DEV=False):
        self.DEV = DEV
        self.sql_path = os.path.join(_resource_dir(), sql_path_name)
        self.db_path = os.path.join(get_app_data_dir(), db_path_name)

    # ------------------------------------------------------------------
    #  إنشاء القاعدة وترقيتها
    # ------------------------------------------------------------------
    def exists(self):
        return os.path.isfile(self.db_path)

    def _read_sql(self):
        with open(self.sql_path, "r", encoding="utf-8") as f:
            return f.read()

    def _connect(self):
        conn = sqlite3.connect(self.db_path, timeout=10)
        conn.row_factory = sqlite3.Row
        return conn

    def schema_version(self):
        with closing(self._connect()) as conn:
            return conn.execute("PRAGMA user_version").fetchone()[0]

    def create_database(self, force=False):
        """
        ينشئ القاعدة إن لم تكن موجودة.
        إن كانت موجودة: لا تُمسّ بياناتها، لكن إن كان إصدارها أقدم من SCHEMA_VERSION
        يُطبَّق عليها database.sql من جديد (آمن: كله IF NOT EXISTS / INSERT OR IGNORE).
        force=True يعيد بناءها من الصفر (يحذف كل بياناتها).
        """
        if self.exists() and not force:
            self._upgrade_if_needed()
            return

        if self.DEV:
            print("Creating database...")
        sql_script = self._read_sql()

        # ننشئ في ملف مؤقت ثم نعيد التسمية، حتى لا يبقى ملف نصف مكتمل إذا فشل السكربت
        tmp_path = self.db_path + ".tmp"
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

        conn = sqlite3.connect(tmp_path)
        try:
            conn.executescript(sql_script)
            conn.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
            conn.commit()
        except Exception:
            conn.close()
            os.remove(tmp_path)
            raise
        conn.close()

        os.replace(tmp_path, self.db_path)
        if self.DEV:
            print(f"Database created successfully: {self.db_path}")

    def _upgrade_if_needed(self):
        if self.schema_version() >= SCHEMA_VERSION:
            if self.DEV:
                print(f"Database already up to date: {self.db_path}")
            return

        if self.DEV:
            print("Upgrading database...")
        sql_script = self._read_sql()

        # نسخة احتياطية قبل الترقية
        shutil.copy2(self.db_path, self.db_path + ".bak")

        conn = sqlite3.connect(self.db_path, timeout=10)
        try:
            conn.executescript(sql_script)
            conn.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
            conn.commit()
        finally:
            conn.close()

    # ------------------------------------------------------------------
    #  تفضيلات المستخدم (جدول user_preferences — صف واحد id = 1)
    # ------------------------------------------------------------------
    def get_preferences(self):
        with closing(self._connect()) as conn:
            row = conn.execute(
                "SELECT theme, language, user_nickname, selected_model "
                "FROM user_preferences WHERE id = 1"
            ).fetchone()
        return dict(row) if row else {}

    def set_preferences(self, **values):
        values = {k: v for k, v in values.items() if k in PREF_COLUMNS}
        if not values:
            return
        assignments = ", ".join(f"{col} = ?" for col in values)
        with closing(self._connect()) as conn:
            with conn:
                conn.execute(
                    f"UPDATE user_preferences SET {assignments} WHERE id = 1",
                    tuple(values.values()),
                )

    # ------------------------------------------------------------------
    #  النماذج (جدول ai_model)
    # ------------------------------------------------------------------
    def list_models(self):
        """كل النماذج الموجودة الآن في القاعدة بترتيب إضافتها"""
        with closing(self._connect()) as conn:
            rows = conn.execute(
                "SELECT id, model_name, description, version "
                "FROM ai_model ORDER BY rowid"
            ).fetchall()
        return [dict(r) for r in rows]

    def get_model(self, model_id):
        with closing(self._connect()) as conn:
            row = conn.execute(
                "SELECT id, model_name, description, version "
                "FROM ai_model WHERE id = ?",
                (model_id,),
            ).fetchone()
        return dict(row) if row else None

    def upsert_model(self, model_id, model_name, description="", version=""):
        """يضيف نموذجاً جديداً أو يحدّث نموذجاً موجوداً — فيظهر فوراً في قائمة الواجهة"""
        with closing(self._connect()) as conn:
            with conn:
                conn.execute(
                    "INSERT INTO ai_model (id, model_name, description, version) "
                    "VALUES (?, ?, ?, ?) "
                    "ON CONFLICT(id) DO UPDATE SET "
                    "model_name = excluded.model_name, "
                    "description = excluded.description, "
                    "version = excluded.version, "
                    "last_updated = CURRENT_TIMESTAMP",
                    (model_id, model_name, description, version),
                )