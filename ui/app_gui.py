import ctypes
import json
import os
import queue
import sys
import threading
import tkinter as tk
import webbrowser
from core.vector_engine import CLOSE_SIGNAL, VectoEngine
from storage.database import Database, get_app_data_dir

try:
  from ui.i18n import LANGUAGES, STRINGS, get_language, set_language, t
except ImportError:  # عند تشغيل الملف مباشرة من داخل مجلد ui
  from i18n import LANGUAGES, STRINGS, get_language, set_language, t

try:
  from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps, ImageTk

  PIL_AVAILABLE = True
except ImportError:
  PIL_AVAILABLE = False

# مسار الشعار: ui/static/img/logo.png (نسبةً لموقع هذا الملف ui/app_gui.py)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOGO_PATH = os.path.join(BASE_DIR, "static", "img", "logo.png")

# صفحات السيرفر المحلي (Flask)
BASE_URL = "http://127.0.0.1:5000"
URL_ABOUT = BASE_URL


def _hex_to_colorref(hex_color):
  """يحوّل لون #RRGGBB إلى صيغة COLORREF التي تستخدمها Windows (0x00BBGGRR)"""
  hex_color = hex_color.lstrip("#")
  r = int(hex_color[0:2], 16)
  g = int(hex_color[2:4], 16)
  b = int(hex_color[4:6], 16)
  return r | (g << 8) | (b << 16)


def _apply_titlebar_color_now(
    window, bar_color, text_color=None, border_color=None
):
  """التنفيذ الفعلي للتلوين — منفصل حتى يمكن استدعاؤه فوراً أو مؤجلاً"""
  if sys.platform != "win32":
    return False
  try:
    window.update_idletasks()
    hwnd = ctypes.windll.user32.GetParent(window.winfo_id())
    if not hwnd:
      return False

    DWMWA_BORDER_COLOR = 34
    DWMWA_CAPTION_COLOR = 35
    DWMWA_TEXT_COLOR = 36

    caption_ref = ctypes.c_int(_hex_to_colorref(bar_color))
    result = ctypes.windll.dwmapi.DwmSetWindowAttribute(
        hwnd,
        DWMWA_CAPTION_COLOR,
        ctypes.byref(caption_ref),
        ctypes.sizeof(caption_ref),
    )

    border_ref = ctypes.c_int(_hex_to_colorref(border_color or bar_color))
    ctypes.windll.dwmapi.DwmSetWindowAttribute(
        hwnd,
        DWMWA_BORDER_COLOR,
        ctypes.byref(border_ref),
        ctypes.sizeof(border_ref),
    )

    if text_color:
      text_ref = ctypes.c_int(_hex_to_colorref(text_color))
      ctypes.windll.dwmapi.DwmSetWindowAttribute(
          hwnd,
          DWMWA_TEXT_COLOR,
          ctypes.byref(text_ref),
          ctypes.sizeof(text_ref),
      )

    return result == 0
  except Exception:
    return False


def apply_native_titlebar_color(
    window, bar_color, text_color=None, border_color=None
):
  """يلوّن إطار النافذة الأصلي بالكامل"""
  if sys.platform != "win32":
    return
  window.after(
      10,
      lambda: _apply_titlebar_color_now(
          window, bar_color, text_color, border_color
      ),
  )
  window.after(
      150,
      lambda: _apply_titlebar_color_now(
          window, bar_color, text_color, border_color
      ),
  )


def load_logo_photo(max_size=None):
  """يحمّل شعار البرنامج كصورة Tkinter جاهزة للعرض"""
  if not os.path.isfile(LOGO_PATH):
    return None
  try:
    if PIL_AVAILABLE:
      img = Image.open(LOGO_PATH)
      if max_size:
        img.thumbnail((max_size, max_size), Image.LANCZOS)
      return ImageTk.PhotoImage(img)
    photo = tk.PhotoImage(file=LOGO_PATH)
    if max_size and photo.width() > max_size:
      factor = max(1, photo.width() // max_size)
      photo = photo.subsample(factor, factor)
    return photo
  except Exception:
    return None


# =========================================================
#  الأيقونة العائمة (Ex:2) — شفافية حقيقية لكل بكسل + تدرجات
# =========================================================
def build_orb_image(size, hover=False, letter="S"):
  """يرسم كرة فضية زجاجية على خلفية شفافة تماماً"""
  S = 4
  big = size * S
  d = int(size * 0.60 * S)
  m = (big - d) // 2
  box = (m, m, m + d, m + d)

  canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))

  shadow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
  ImageDraw.Draw(shadow).ellipse(
      (box[0] + 2 * S, box[1] + 6 * S, box[2] - 2 * S, box[3] + 6 * S),
      fill=(0, 0, 0, 170),
  )
  shadow = shadow.filter(ImageFilter.GaussianBlur(9 * S))
  canvas = Image.alpha_composite(canvas, shadow)

  glow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
  g = 7 * S
  ImageDraw.Draw(glow).ellipse(
      (box[0] - g, box[1] - g, box[2] + g, box[3] + g),
      fill=(255, 255, 255, 135 if hover else 70),
  )
  glow = glow.filter(ImageFilter.GaussianBlur(11 * S))
  canvas = Image.alpha_composite(canvas, glow)

  grad = Image.radial_gradient("L").resize(
      (int(d * 1.5), int(d * 1.5)), Image.BICUBIC
  )
  left, top = int(d * 0.40), int(d * 0.45)
  grad = grad.crop((left, top, left + d, top + d))
  if hover:
    body = ImageOps.colorize(
        grad, black=(255, 255, 255), mid=(222, 222, 228), white=(96, 96, 104)
    )
  else:
    body = ImageOps.colorize(
        grad, black=(246, 246, 248), mid=(196, 196, 202), white=(72, 72, 78)
    )
  body = body.convert("RGBA")
  mask = Image.new("L", (d, d), 0)
  ImageDraw.Draw(mask).ellipse((0, 0, d - 1, d - 1), fill=255)
  canvas.paste(body, (m, m), mask)

  ring = Image.new("RGBA", (big, big), (0, 0, 0, 0))
  ImageDraw.Draw(ring).ellipse(
      box, outline=(255, 255, 255, 110), width=max(1, int(1.5 * S))
  )
  canvas = Image.alpha_composite(canvas, ring)

  gw, gh = int(d * 0.68), int(d * 0.42)
  vgrad = ImageOps.invert(Image.linear_gradient("L")).resize(
      (gw, gh), Image.BICUBIC
  )
  emask = Image.new("L", (gw, gh), 0)
  ImageDraw.Draw(emask).ellipse((0, 0, gw - 1, gh - 1), fill=255)
  gloss_alpha = ImageChops.multiply(vgrad, emask).point(lambda v: int(v * 0.62))
  gloss = Image.new("RGBA", (gw, gh), (255, 255, 255, 255))
  canvas.paste(gloss, (m + (d - gw) // 2, m + int(d * 0.06)), gloss_alpha)

  draw = ImageDraw.Draw(canvas)
  font = None
  for name in ("segoeuib.ttf", "seguisb.ttf", "arialbd.ttf", "DejaVuSans-Bold.ttf"):
    try:
      font = ImageFont.truetype(name, int(d * 0.46))
      break
    except Exception:
      continue
  if font is None:
    font = ImageFont.load_default()
  draw.text(
      (big / 2, big / 2 + d * 0.02),
      letter,
      font=font,
      fill=(18, 18, 20, 255),
      anchor="mm",
  )

  return canvas.resize((size, size), Image.LANCZOS)


def _premultiplied_bgra(img):
  """UpdateLayeredWindow يتطلب بكسلات BGRA مضروبة مسبقاً بقناة ألفا"""
  r, g, b, a = img.split()
  r = ImageChops.multiply(r, a)
  g = ImageChops.multiply(g, a)
  b = ImageChops.multiply(b, a)
  return Image.merge("RGBA", (b, g, r, a)).tobytes()


class FloatingOrb:

  KEY = "#0a0a0b"

  def __init__(self, root, size, on_click):
    self.root = root
    self.size = size
    self.on_click = on_click
    self.win = tk.Toplevel(root)
    self.win.withdraw()
    self.win.overrideredirect(True)
    self.win.wm_attributes("-topmost", True)
    self.win.geometry(f"{size}x{size}+100+100")
    self._ready = False
    self._layered = False
    self._hover = False
    self._drag = {"x": 0, "y": 0, "wx": 0, "wy": 0, "moved": False}
    self._target = self.win

  def _setup(self):
    self._ready = True
    if sys.platform == "win32" and PIL_AVAILABLE:
      try:
        self._setup_layered()
        self._layered = True
      except Exception:
        self._layered = False
    if not self._layered:
      self._setup_fallback()
    t = self._target
    t.configure(cursor="fleur")
    t.bind("<Enter>", self._on_enter)
    t.bind("<Leave>", self._on_leave)
    t.bind("<ButtonPress-1>", self._press)
    t.bind("<B1-Motion>", self._motion)
    t.bind("<ButtonRelease-1>", self._release)

  def _setup_layered(self):
    from ctypes import wintypes

    user32, gdi32 = ctypes.windll.user32, ctypes.windll.gdi32

    class POINT(ctypes.Structure):
      _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]

    class SIZE(ctypes.Structure):
      _fields_ = [("cx", ctypes.c_long), ("cy", ctypes.c_long)]

    class BLENDFUNCTION(ctypes.Structure):
      _fields_ = [
          ("BlendOp", ctypes.c_ubyte),
          ("BlendFlags", ctypes.c_ubyte),
          ("SourceConstantAlpha", ctypes.c_ubyte),
          ("AlphaFormat", ctypes.c_ubyte),
      ]

    class BITMAPINFOHEADER(ctypes.Structure):
      _fields_ = [
          ("biSize", wintypes.DWORD),
          ("biWidth", ctypes.c_long),
          ("biHeight", ctypes.c_long),
          ("biPlanes", wintypes.WORD),
          ("biBitCount", wintypes.WORD),
          ("biCompression", wintypes.DWORD),
          ("biSizeImage", wintypes.DWORD),
          ("biXPelsPerMeter", ctypes.c_long),
          ("biYPelsPerMeter", ctypes.c_long),
          ("biClrUsed", wintypes.DWORD),
          ("biClrImportant", wintypes.DWORD),
      ]

    user32.GetParent.argtypes = [wintypes.HWND]
    user32.GetParent.restype = wintypes.HWND
    user32.GetWindowLongW.argtypes = [wintypes.HWND, ctypes.c_int]
    user32.GetWindowLongW.restype = ctypes.c_long
    user32.SetWindowLongW.argtypes = [
        wintypes.HWND,
        ctypes.c_int,
        ctypes.c_long,
    ]
    user32.SetWindowLongW.restype = ctypes.c_long
    user32.GetDC.argtypes = [wintypes.HWND]
    user32.GetDC.restype = wintypes.HDC
    user32.UpdateLayeredWindow.argtypes = [
        wintypes.HWND,
        wintypes.HDC,
        ctypes.POINTER(POINT),
        ctypes.POINTER(SIZE),
        wintypes.HDC,
        ctypes.POINTER(POINT),
        wintypes.DWORD,
        ctypes.POINTER(BLENDFUNCTION),
        wintypes.DWORD,
    ]
    user32.UpdateLayeredWindow.restype = wintypes.BOOL
    gdi32.CreateCompatibleDC.argtypes = [wintypes.HDC]
    gdi32.CreateCompatibleDC.restype = wintypes.HDC
    gdi32.CreateDIBSection.argtypes = [
        wintypes.HDC,
        ctypes.POINTER(BITMAPINFOHEADER),
        wintypes.UINT,
        ctypes.POINTER(ctypes.c_void_p),
        wintypes.HANDLE,
        wintypes.DWORD,
    ]
    gdi32.CreateDIBSection.restype = wintypes.HBITMAP
    gdi32.SelectObject.argtypes = [wintypes.HDC, wintypes.HGDIOBJ]
    gdi32.SelectObject.restype = wintypes.HGDIOBJ

    self.win.update_idletasks()
    inner = self.win.winfo_id()
    self._hwnd = user32.GetParent(inner) or inner

    GWL_EXSTYLE, WS_EX_LAYERED, WS_EX_TOOLWINDOW = -20, 0x80000, 0x80
    style = user32.GetWindowLongW(self._hwnd, GWL_EXSTYLE)
    user32.SetWindowLongW(
        self._hwnd, GWL_EXSTYLE, style | WS_EX_LAYERED | WS_EX_TOOLWINDOW
    )

    screen_dc = user32.GetDC(None)
    n = self.size
    bmi = BITMAPINFOHEADER()
    bmi.biSize = ctypes.sizeof(BITMAPINFOHEADER)
    bmi.biWidth, bmi.biHeight = n, -n
    bmi.biPlanes, bmi.biBitCount, bmi.biCompression = 1, 32, 0

    self._dcs = {}
    for hover in (False, True):
      data = _premultiplied_bgra(build_orb_image(n, hover))
      bits = ctypes.c_void_p()
      hbmp = gdi32.CreateDIBSection(
          screen_dc, ctypes.byref(bmi), 0, ctypes.byref(bits), None, 0
      )
      if not hbmp or not bits.value:
        raise RuntimeError("CreateDIBSection failed")
      ctypes.memmove(bits, data, len(data))
      memdc = gdi32.CreateCompatibleDC(screen_dc)
      gdi32.SelectObject(memdc, hbmp)
      self._dcs[hover] = (memdc, hbmp)

    self._screen_dc = screen_dc
    self._sz = SIZE(n, n)
    self._src = POINT(0, 0)
    self._blend = BLENDFUNCTION(0, 0, 255, 1)
    self._ulw = user32.UpdateLayeredWindow
    self._byref = ctypes.byref
    if not self._present(False):
      raise RuntimeError("UpdateLayeredWindow failed")

  def _present(self, hover):
    memdc = self._dcs[hover][0]
    return bool(
        self._ulw(
            self._hwnd,
            self._screen_dc,
            None,
            self._byref(self._sz),
            memdc,
            self._byref(self._src),
            0,
            self._byref(self._blend),
            2,
        )
    )

  def _setup_fallback(self):
    n = self.size
    self.win.configure(bg=self.KEY)
    try:
      self.win.wm_attributes("-transparentcolor", self.KEY)
    except tk.TclError:
      pass
    cv = tk.Canvas(
        self.win, width=n, height=n, bg=self.KEY, highlightthickness=0, bd=0
    )
    cv.pack()
    steps = 14
    r0 = n * 0.30
    for i in range(steps):
      t = i / (steps - 1)
      shade = int(250 - 170 * t)
      r = r0 * (1 - t * 0.85)
      cx, cy = n / 2 - t * 6, n / 2 - t * 6
      cv.create_oval(
          cx - r,
          cy - r,
          cx + r,
          cy + r,
          outline="",
          fill=f"#{shade:02x}{shade:02x}{shade + 4 if shade < 251 else 255:02x}",
      )
    cv.create_text(
        n / 2, n / 2, text="S", fill="#121214", font=("Segoe UI", 22, "bold")
    )
    self._canvas = cv
    self._target = cv

  def _on_enter(self, _e):
    if self._layered and not self._hover:
      self._hover = True
      self._present(True)

  def _on_leave(self, _e):
    if self._layered and self._hover:
      self._hover = False
      self._present(False)

  def _press(self, e):
    self._drag = {
        "x": e.x_root,
        "y": e.y_root,
        "wx": self.win.winfo_x(),
        "wy": self.win.winfo_y(),
        "moved": False,
    }

  def _motion(self, e):
    dx, dy = e.x_root - self._drag["x"], e.y_root - self._drag["y"]
    if abs(dx) > 3 or abs(dy) > 3:
      self._drag["moved"] = True
    self.win.geometry(f"+{self._drag['wx'] + dx}+{self._drag['wy'] + dy}")

  def _release(self, _e):
    if not self._drag.get("moved"):
      self.on_click()

  @property
  def visible(self):
    return self.win.winfo_viewable()

  def position(self):
    return self.win.winfo_x(), self.win.winfo_y()

  def show(self, x=None, y=None):
    if x is not None:
      self.win.geometry(f"{self.size}x{self.size}+{x}+{y}")
    self.win.deiconify()
    self.win.update_idletasks()
    if not self._ready:
      self._setup()
    elif self._layered:
      self._hover = False
      self._present(False)
    self.win.wm_attributes("-topmost", True)

  def hide(self):
    self.win.withdraw()


class QueryWorker(threading.Thread):

  def __init__(self, model_id=None):
    super().__init__(daemon=True)
    self._queue = queue.Queue()
    self.results = queue.Queue()
    self.engine = None
    self.model_id = model_id
    self._applied_model = None

  def set_model(self, model_id):
    """يُطبَّق على المحرك قبل أول استعلام بعد التغيير"""
    self.model_id = model_id

  def _apply_model(self):
    if self.model_id == self._applied_model:
      return
    setter = getattr(self.engine, "set_model", None)  # اختياري في VectoEngine
    if callable(setter) and self.model_id:
      setter(self.model_id)
    self._applied_model = self.model_id

  def _ensure_engine(self):
    if self.engine is None:
      self.engine = VectoEngine()

  def run(self):
    while True:
      query, entry_widget = self._queue.get()
      try:
        self._ensure_engine()
        self._apply_model()
        result = self.engine.process_query(query)
      except Exception as e:
        result = t("error_exec", error=e)
      self.results.put((result, entry_widget))

  def submit(self, query, entry_widget):
    self._queue.put((query, entry_widget))


# =========================================================
#  نظام الألوان والخطوط - هوية بصرية فاخرة
# =========================================================
class Theme:
  # لوحتان بنفس الأسماء: داكنة ومضيئة. كل قيمة فريدة حتى يمكن التحويل بينهما
  PALETTES = {
      "dark": {
          "BG_DARK": "#0b0b0c",
          "BG_PANEL": "#141416",
          "BG_FIELD": "#1c1c1f",
          "BORDER": "#2a2a2d",
          "BORDER_LIGHT": "#3a3a3e",
          "TEXT_PRIMARY": "#f5f5f7",
          "TEXT_SECONDARY": "#9a9a9e",
          "TEXT_MUTED": "#5f5f63",
          "ACCENT": "#e8e8ea",
          "ACCENT_HOVER": "#ffffff",
          "ACCENT_DIM": "#3a3a3d",
          "DANGER_HOVER": "#2a1d1d",
      },
      "light": {
          "BG_DARK": "#ececef",
          "BG_PANEL": "#f8f8fa",
          "BG_FIELD": "#fdfdfe",
          "BORDER": "#d2d2d8",
          "BORDER_LIGHT": "#b4b4bc",
          "TEXT_PRIMARY": "#1a1a1d",
          "TEXT_SECONDARY": "#5c5c63",
          "TEXT_MUTED": "#8e8e95",
          "ACCENT": "#1d1d20",
          "ACCENT_HOVER": "#000000",
          "ACCENT_DIM": "#c9c9ce",
          "DANGER_HOVER": "#f3dede",
      },
  }
  mode = "dark"

  FONT_UI = ("Segoe UI", 10)
  FONT_UI_BOLD = ("Segoe UI Semibold", 10)
  FONT_TITLE = ("Segoe UI", 15, "bold")
  FONT_LABEL = ("Segoe UI", 9)
  FONT_MONO = ("Cascadia Mono", 10)

  @classmethod
  def apply(cls, mode):
    """يفعّل لوحة ألوان: بعدها Theme.BG_DARK وغيرها تعطي ألوان هذا الوضع"""
    if mode not in cls.PALETTES:
      mode = "dark"
    cls.mode = mode
    for name, value in cls.PALETTES[mode].items():
      setattr(cls, name, value)

  @classmethod
  def mapping(cls, old_mode, new_mode):
    """خريطة لون قديم -> لون جديد لإعادة تلوين العناصر الموجودة"""
    old, new = cls.PALETTES[old_mode], cls.PALETTES[new_mode]
    return {old[name].lower(): new[name] for name in old}

  @classmethod
  def live(cls, color):
    """يحوّل أي لون من اللوحتين إلى ما يقابله في الوضع الحالي (لأحداث مثل hover)"""
    name = cls._TOKEN_OF.get(str(color).lower())
    return cls.PALETTES[cls.mode][name] if name else color


Theme._TOKEN_OF = {
    value.lower(): name
    for palette in Theme.PALETTES.values()
    for name, value in palette.items()
}
Theme.apply("dark")


class UserSettings:
  """يحفظ اختيارات المستخدم (الوضع واللغة والاسم المستعار والنموذج) في جدول user_preferences"""

  DEFAULTS = {
      "theme": "light",
      "language": "en",
      "user_nickname": "",
      "selected_model": "saia-1",
  }

  def __init__(self):
    self.db = Database()
    self.data = dict(self.DEFAULTS)
    try:
      self.db.create_database()  # ينشئ القاعدة أو يرقّيها إن كانت قديمة
      self.data.update(self.db.get_preferences())
    except Exception:
      pass
    self._import_legacy_json()
    self._sanitize()

  def _import_legacy_json(self):
    """ينقل مرة واحدة إعدادات settings.json القديمة إلى القاعدة"""
    try:
      path = os.path.join(get_app_data_dir(), "settings.json")
      if not os.path.isfile(path):
        return
      with open(path, encoding="utf-8") as f:
        old = json.load(f)
      if isinstance(old, dict):
        if old.get("theme") in Theme.PALETTES:
          self.data["theme"] = old["theme"]
        if old.get("language") in STRINGS:
          self.data["language"] = old["language"]
        if isinstance(old.get("user_name"), str):
          self.data["user_nickname"] = old["user_name"]
        self._save(self.data)
      os.replace(path, path + ".migrated")
    except (OSError, ValueError):
      pass

  def _sanitize(self):
    """يتأكد أن القيم المحفوظة صالحة، وأن النموذج المختار ما زال موجوداً في القاعدة"""
    if self.data.get("theme") not in Theme.PALETTES:
      self.data["theme"] = self.DEFAULTS["theme"]
    if self.data.get("language") not in STRINGS:
      self.data["language"] = self.DEFAULTS["language"]
    if not isinstance(self.data.get("user_nickname"), str):
      self.data["user_nickname"] = ""
    try:
      ids = [m["id"] for m in self.db.list_models()]
    except Exception:
      ids = []
    if ids and self.data.get("selected_model") not in ids:
      self.data["selected_model"] = ids[0]
      self._save({"selected_model": ids[0]})

  def _save(self, values):
    try:
      self.db.set_preferences(**values)
    except Exception:
      pass

  def get(self, key):
    return self.data[key]

  def set(self, **values):
    self.data.update(values)
    self._save(values)


_COLOR_OPTIONS = (
    "bg",
    "fg",
    "activebackground",
    "activeforeground",
    "selectcolor",
    "insertbackground",
    "highlightbackground",
    "highlightcolor",
    "disabledbackground",
    "disabledforeground",
    "readonlybackground",
)


def recolor_tree(widget, mapping):
  """يعيد تلوين العنصر وكل أبنائه (بما فيها النوافذ الفرعية) حسب خريطة قديم -> جديد"""
  for option in _COLOR_OPTIONS:
    try:
      current = str(widget.cget(option)).lower()
    except tk.TclError:
      continue
    new = mapping.get(current)
    if new:
      try:
        widget.configure(**{option: new})
      except tk.TclError:
        pass
  if isinstance(widget, MinimalScrollbar):
    widget._draw()
  for child in widget.winfo_children():
    recolor_tree(child, mapping)


class LiveText:
  """يربط نص كل عنصر بدالة ترجمة، فيتحدّث فوراً عند تغيير اللغة أو الوضع"""

  def __init__(self):
    self._items = []

  def bind(self, widget, text_fn, option="text"):
    self._items.append((widget, option, text_fn))
    widget.configure(**{option: text_fn()})
    return widget

  def refresh(self):
    alive = []
    for widget, option, text_fn in self._items:
      try:
        widget.configure(**{option: text_fn()})
      except tk.TclError:   # العنصر أُغلقت نافذته
        continue
      alive.append((widget, option, text_fn))
    self._items = alive


def add_hover(widget, normal_bg, hover_bg, normal_fg=None, hover_fg=None):

  def on_enter(e):
    widget.configure(bg=Theme.live(hover_bg))
    if hover_fg:
      widget.configure(fg=Theme.live(hover_fg))

  def on_leave(e):
    widget.configure(bg=Theme.live(normal_bg))
    if normal_fg:
      widget.configure(fg=Theme.live(normal_fg))

  widget.bind("<Enter>", on_enter)
  widget.bind("<Leave>", on_leave)


def ghost_button(
    parent,
    text,
    command,
    fg=None,
    hover_fg=None,
    font=None,
    bg=None,
    hover_bg=None,
    padx=10,
    pady=6,
):
  # القيم الافتراضية تُقرأ وقت الإنشاء حتى تطابق الوضع الحالي (مضيء/داكن)
  fg = fg or Theme.TEXT_SECONDARY
  hover_fg = hover_fg or Theme.TEXT_PRIMARY
  font = font or Theme.FONT_UI
  bg = bg or Theme.BG_DARK
  hover_bg = hover_bg or Theme.BG_PANEL
  btn = tk.Button(
      parent,
      text=text,
      font=font,
      bg=bg,
      fg=fg,
      activebackground=hover_bg,
      activeforeground=hover_fg,
      relief="flat",
      bd=0,
      cursor="hand2",
      padx=padx,
      pady=pady,
      command=command,
  )
  add_hover(btn, bg, hover_bg, fg, hover_fg)
  return btn


def solid_button(parent, text, command, padx=16, pady=5):
  """زر ممتلئ بلون التمييز (مثل زر Send)"""
  btn = tk.Button(
      parent,
      text=text,
      font=Theme.FONT_UI_BOLD,
      bg=Theme.ACCENT,
      fg=Theme.BG_DARK,
      activebackground=Theme.ACCENT_HOVER,
      activeforeground=Theme.BG_DARK,
      relief="flat",
      bd=0,
      cursor="hand2",
      padx=padx,
      pady=pady,
      command=command,
  )
  add_hover(btn, Theme.ACCENT, Theme.ACCENT_HOVER, Theme.BG_DARK, Theme.BG_DARK)
  return btn


def outline_button(parent, text, command, padx=14, pady=5):
  """زر هادئ بإطار رفيع"""
  btn = ghost_button(
      parent,
      text,
      command,
      fg=Theme.TEXT_PRIMARY,
      bg=Theme.BG_FIELD,
      hover_bg=Theme.BORDER,
      padx=padx,
      pady=pady,
  )
  btn.configure(
      highlightthickness=1,
      highlightbackground=Theme.BORDER,
      highlightcolor=Theme.BORDER_LIGHT,
  )
  return btn


def divider(parent, orient="h"):
  if orient == "h":
    line = tk.Frame(parent, bg=Theme.BORDER, height=1)
  else:
    line = tk.Frame(parent, bg=Theme.BORDER, width=1)
  return line


class MinimalScrollbar(tk.Canvas):
  """شريط تمرير رفيع ومسطح ينسجم مع ألوان الواجهة"""

  def __init__(self, parent, command=None, width=8, min_thumb=32):
    super().__init__(
        parent, width=width, bg=Theme.BG_PANEL, highlightthickness=0, bd=0
    )
    self.command = command
    self._bar_w = width
    self._min = min_thumb
    self._lo, self._hi = 0.0, 1.0
    self._hover = False
    self._offset = None

    self.bind("<Configure>", lambda e: self._draw())
    self.bind("<Enter>", lambda e: self._set_hover(True))
    self.bind("<Leave>", lambda e: self._set_hover(False))
    self.bind("<ButtonPress-1>", self._press)
    self.bind("<B1-Motion>", self._motion)
    self.bind("<ButtonRelease-1>", self._release)

  def set(self, lo, hi):
    self._lo, self._hi = float(lo), float(hi)
    self._draw()

  def _bounds(self):
    h = self.winfo_height()
    top, bot = self._lo * h, self._hi * h
    if bot - top < self._min:
      bot = min(h, top + self._min)
      top = bot - self._min
    return top, bot, h

  def _draw(self):
    self.delete("all")
    if self._hi - self._lo >= 0.999:
      return
    top, bot, h = self._bounds()
    if h <= 1:
      return
    r = self._bar_w / 2
    active = self._hover or self._offset is not None
    color = Theme.TEXT_MUTED if active else Theme.BORDER_LIGHT
    self.create_line(
        self._bar_w / 2,
        top + r,
        self._bar_w / 2,
        bot - r,
        width=self._bar_w - 2,
        capstyle="round",
        fill=color,
    )

  def _set_hover(self, value):
    self._hover = value
    self._draw()

  def _press(self, e):
    top, bot, h = self._bounds()
    if top <= e.y <= bot:
      self._offset = e.y - top
    else:
      self._offset = (bot - top) / 2
      self._motion(e)
    self._draw()

  def _motion(self, e):
    if self._offset is None or not self.command:
      return
    h = self.winfo_height()
    if h > 1:
      self.command("moveto", max(0.0, (e.y - self._offset) / h))

  def _release(self, _e):
    self._offset = None
    self._draw()


class ModelPicker(tk.Menubutton):
  """
  زر اختيار النموذج. القائمة تُقرأ من جدول ai_model في كل مرة تُفتح،
  فأي نموذج يُضاف إلى القاعدة يظهر فوراً دون تعديل الكود.
  """

  def __init__(self, parent, app, width=18):
    self.app = app
    super().__init__(
        parent,
        text="",
        font=Theme.FONT_UI,
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        activebackground=Theme.BORDER,
        activeforeground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        highlightthickness=1,
        highlightbackground=Theme.BORDER,
        highlightcolor=Theme.BORDER_LIGHT,
        cursor="hand2",
        padx=10,
        pady=5,
        anchor="w",
        width=width,
    )
    self.menu = tk.Menu(
        self,
        tearoff=0,
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        activebackground=Theme.BORDER_LIGHT,
        activeforeground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        font=Theme.FONT_UI,
        postcommand=self._rebuild_menu,
    )
    self.configure(menu=self.menu)
    add_hover(self, Theme.BG_FIELD, Theme.BORDER)
    app.model_pickers.append(self)
    self.refresh_label()

  @staticmethod
  def _title(model):
    name = model.get("model_name") or model["id"]
    return f"{name}  ·  v{model['version']}" if model.get("version") else name

  def _rebuild_menu(self):
    self.menu.delete(0, "end")
    models = self.app.models()
    if not models:
      self.menu.add_command(label=t("no_models"), state="disabled")
      return
    current = self.app.settings.get("selected_model")
    for model in models:
      mark = "✓  " if model["id"] == current else "      "
      label = mark + self._title(model)
      if model.get("description"):
        label += f"   —   {model['description']}"
      self.menu.add_command(
          label=label,
          command=lambda mid=model["id"]: self.app.change_model(mid),
      )

  def refresh_label(self):
    model = self.app.model_by_id(self.app.settings.get("selected_model"))
    text = self._title(model) if model else t("no_models")
    self.configure(text=f"{text}  ▾")


def _language_label(code):
  for label, lang_code in LANGUAGES.items():
    if lang_code == code:
      return label
  return next(iter(LANGUAGES))


class SettingsWindow:

  def __init__(self, parent, app):
    self.app = app
    live = app.live

    self.window = tk.Toplevel(parent)
    self.window.title(t("settings_title"))
    self.window.geometry("600x480")
    self.window.configure(bg=Theme.BG_DARK)
    self.window.resizable(False, False)

    apply_native_titlebar_color(self.window, "#ffffff", text_color="#000000")

    header = tk.Frame(self.window, bg=Theme.BG_DARK)
    header.pack(fill="x", padx=20, pady=(18, 6))

    self.back_btn = ghost_button(
        header, "", self.window.destroy, padx=6, pady=2
    )
    live.bind(self.back_btn, lambda: t("back"))
    self.back_btn.pack(side="left")

    title_lbl = tk.Label(
        header,
        text="",
        font=("Segoe UI", 10, "bold"),
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_MUTED,
    )
    live.bind(title_lbl, lambda: t("settings"))
    title_lbl.pack(side="left", expand=True)

    self.about_btn = solid_button(header, "", self.open_about_web)
    live.bind(self.about_btn, lambda: t("about"))
    self.about_btn.pack(side="right")

    header_div = divider(self.window)
    header_div.pack(fill="x", padx=20, pady=(10, 18))

    body = tk.Frame(self.window, bg=Theme.BG_DARK)
    body.pack(fill="both", expand=True, padx=20)

    # ---------- العمود الأيسر: عام ----------
    left_col = tk.Frame(body, bg=Theme.BG_DARK)
    left_col.pack(side="left", fill="y", padx=(0, 24))

    section_label = tk.Label(
        left_col,
        text="",
        font=("Segoe UI", 8, "bold"),
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_MUTED,
    )
    live.bind(section_label, lambda: t("general"))
    section_label.pack(anchor="w", pady=(0, 12))

    # زر تبديل الوضع: يعرض الوضع الذي سينتقل إليه
    self.theme_btn = outline_button(left_col, "", app.toggle_theme)
    live.bind(
        self.theme_btn,
        lambda: t("theme_to_light") if Theme.mode == "dark" else t("theme_to_dark"),
    )
    self.theme_btn.pack(anchor="w", pady=(0, 20))

    self.lang_label = tk.Label(
        left_col,
        text="",
        font=Theme.FONT_LABEL,
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_SECONDARY,
    )
    live.bind(self.lang_label, lambda: t("language"))
    self.lang_label.pack(anchor="w", pady=(0, 6))

    self.lang_var = tk.StringVar(value=_language_label(get_language()))
    lang_field = tk.Frame(
        left_col,
        bg=Theme.BG_FIELD,
        highlightthickness=1,
        highlightbackground=Theme.BORDER,
        highlightcolor=Theme.BORDER,
    )
    lang_field.pack(anchor="w")

    self.lang_dropdown = tk.OptionMenu(
        lang_field,
        self.lang_var,
        *LANGUAGES.keys(),
        command=self._on_language,
    )
    self.lang_dropdown.config(
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        activebackground=Theme.BORDER_LIGHT,
        activeforeground=Theme.TEXT_PRIMARY,
        highlightthickness=0,
        font=Theme.FONT_UI,
        width=12,
        anchor="w",
    )
    self.lang_dropdown["menu"].config(
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        activebackground=Theme.BORDER_LIGHT,
        activeforeground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
    )
    self.lang_dropdown.pack(ipady=5, padx=4)

    # ---------- اختيار النموذج (ديناميكي من جدول ai_model) ----------
    model_label = tk.Label(
        left_col,
        text="",
        font=("Segoe UI", 8, "bold"),
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_MUTED,
    )
    live.bind(model_label, lambda: t("ai_model"))
    model_label.pack(anchor="w", pady=(24, 8))

    self.model_picker = ModelPicker(left_col, app, width=20)
    self.model_picker.pack(anchor="w")

    vdiv = divider(body, orient="v")
    vdiv.pack(side="left", fill="y", pady=4)

    # ---------- العمود الأيمن: الملف الشخصي والحساب ----------
    right_col = tk.Frame(body, bg=Theme.BG_DARK)
    right_col.pack(side="left", fill="both", expand=True, padx=(24, 0))

    profile_label = tk.Label(
        right_col,
        text="",
        font=("Segoe UI", 8, "bold"),
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_MUTED,
    )
    live.bind(profile_label, lambda: t("profile"))
    profile_label.pack(anchor="w", pady=(0, 12))

    name_label = tk.Label(
        right_col,
        text="",
        font=Theme.FONT_LABEL,
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_SECONDARY,
    )
    live.bind(name_label, lambda: t("user_nickname"))
    name_label.pack(anchor="w", pady=(0, 6))

    wrap = tk.Frame(
        right_col,
        bg=Theme.BG_FIELD,
        highlightthickness=1,
        highlightbackground=Theme.BORDER,
        highlightcolor=Theme.BORDER_LIGHT,
    )
    wrap.pack(fill="x", pady=(0, 12))

    self.user_entry = tk.Entry(
        wrap,
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        insertbackground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        font=Theme.FONT_UI,
    )
    self.user_entry.pack(fill="x", ipady=7, padx=10)
    self.user_entry.insert(0, app.settings.get("user_nickname"))
    self.user_entry.bind("<Return>", lambda e: self.save_name())

    buttons_row = tk.Frame(right_col, bg=Theme.BG_DARK)
    buttons_row.pack(fill="x")

    self.save_btn = outline_button(buttons_row, "", self.save_name)
    live.bind(self.save_btn, lambda: t("save"))
    self.save_btn.pack(side="left")


  def _on_language(self, label):
    self.app.change_language(LANGUAGES.get(label))

  def save_name(self):
    self.app.set_nickname(self.user_entry.get())
    self.save_btn.configure(text=t("saved"))
    self.window.after(1500, self._restore_save_label)

  def _restore_save_label(self):
    try:
      self.save_btn.configure(text=t("save"))
    except tk.TclError:
      pass

  def open_about_web(self):
    webbrowser.open(URL_ABOUT)


class SaiAApp:

  def __init__(self):
    self.settings = UserSettings()
    Theme.apply(self.settings.get("theme"))
    set_language(self.settings.get("language"))
    self.live = LiveText()
    self._settings_win = None
    self.model_pickers = []

    self.root = tk.Tk()
    self.root.title("SaiA")
    self.root.geometry("460x580")
    self.root.configure(bg=Theme.BG_DARK)

    self.EX2_SIZE = 110

    self._app_icon = load_logo_photo()
    if self._app_icon:
      self.root.iconphoto(True, self._app_icon)

    apply_native_titlebar_color(self.root, "#ffffff", text_color="#000000")

    self._pending = set()
    self._think_tick = 0
    self._think_job = None

    self.worker = QueryWorker(self.settings.get("selected_model"))
    self.worker.start()
    self._poll_results()

    self.setup_ex1_full_window()
    self.setup_ex2_floating_icon()
    self.setup_ex3_compact_bar()

    self.show_ex1()

  # --- 1. بناء النافذة الكاملة (Ex:1) ---
  def setup_ex1_full_window(self):
    self.frame_ex1 = tk.Frame(self.root, bg=Theme.BG_DARK)

    # --- الشريط العلوي ---
    header = tk.Frame(self.frame_ex1, bg=Theme.BG_DARK)
    header.pack(fill="x", pady=(18, 0), padx=20)

    self._header_logo = load_logo_photo(max_size=30)
    if self._header_logo:
      logo_lbl = tk.Label(header, image=self._header_logo, bg=Theme.BG_DARK)
      logo_lbl.pack(side="left", padx=(0, 8))

    title_lbl = tk.Label(
        header,
        text="SaiA",
        font=Theme.FONT_TITLE,
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_PRIMARY,
    )
    title_lbl.pack(side="left")

    subtitle_lbl = tk.Label(
        header,
        text="",
        font=("Segoe UI", 8, "bold"),
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_MUTED,
    )
    subtitle_lbl.pack(side="left", pady=(6, 0))
    self.live.bind(subtitle_lbl, lambda: "  " + t("assistant"))

    controls = tk.Frame(header, bg=Theme.BG_DARK)
    controls.pack(side="right")

    btn_ex4 = ghost_button(
        controls,
        "⚙",
        self.open_settings,
        padx=8,
        pady=4,
        font=("Segoe UI", 11),
    )
    btn_ex4.pack(side="right", padx=(6, 0))

    btn_ex3 = ghost_button(
        controls, "▭", self.show_ex3, padx=8, pady=4, font=("Segoe UI", 11)
    )
    btn_ex3.pack(side="right", padx=(6, 0))

    btn_ex2 = ghost_button(
        controls, "⤢", self.show_ex2, padx=8, pady=4, font=("Segoe UI", 11)
    )
    btn_ex2.pack(side="right", padx=(6, 0))

    top_div = divider(self.frame_ex1)
    top_div.pack(fill="x", padx=20, pady=(14, 12))

    # --- صف اختيار النموذج ---
    model_row = tk.Frame(self.frame_ex1, bg=Theme.BG_DARK)
    model_row.pack(fill="x", padx=20, pady=(0, 12))

    model_lbl = tk.Label(
        model_row,
        text="",
        font=("Segoe UI", 8, "bold"),
        bg=Theme.BG_DARK,
        fg=Theme.TEXT_MUTED,
    )
    self.live.bind(model_lbl, lambda: t("model").upper())
    model_lbl.pack(side="left", padx=(0, 10))

    ModelPicker(model_row, self, width=24).pack(side="left", fill="x", expand=True)

    # --- شاشة العرض والسجل المباشر مع شريط التمرير (Scrollbar) ---
    console_wrap = tk.Frame(
        self.frame_ex1,
        bg=Theme.BG_PANEL,
        highlightthickness=1,
        highlightbackground=Theme.BORDER,
    )
    console_wrap.pack(fill="both", expand=True, padx=20)

    console_label = tk.Label(
        console_wrap,
        text="",
        font=("Segoe UI", 8, "bold"),
        bg=Theme.BG_PANEL,
        fg=Theme.TEXT_MUTED,
        anchor="w",
    )
    console_label.pack(fill="x", pady=(10, 4), padx=6)
    self.live.bind(console_label, lambda: "  " + t("session_log"))

    # إطار حاوٍ لصندوق النص وشريط التمرير
    text_frame = tk.Frame(console_wrap, bg=Theme.BG_PANEL)
    text_frame.pack(fill="both", expand=True, padx=4, pady=(0, 4))

    # 1. شريط تمرير رفيع ومسطح بدل الشريط الافتراضي
    scrollbar = MinimalScrollbar(text_frame, width=8)
    scrollbar.pack(side="right", fill="y", padx=(0, 4), pady=4)

    # 2. إنشاء مربع النص وربطه بشريط التمرير
    self.output_box = tk.Text(
        text_frame,
        height=16,
        bg=Theme.BG_PANEL,
        fg=Theme.TEXT_PRIMARY,
        insertbackground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        font=Theme.FONT_MONO,
        wrap="word",
        padx=10,
        pady=4,
        highlightthickness=0,
        yscrollcommand=scrollbar.set,
    )

    # 3. ربط حركة شريط التمرير بمربع النص
    scrollbar.command = self.output_box.yview

    self.output_box.tag_configure("user_tag", foreground=Theme.TEXT_SECONDARY)
    self.output_box.tag_configure("bot_tag", foreground=Theme.ACCENT_HOVER)
    self.output_box.tag_configure("thinking", foreground=Theme.TEXT_MUTED)
    self.output_box.pack(side="left", fill="both", expand=True)

    # --- إطار الإدخال المباشر للـ Prompt ---
    input_frame = tk.Frame(self.frame_ex1, bg=Theme.BG_DARK)
    input_frame.pack(fill="x", padx=20, pady=16)

    entry_wrap = tk.Frame(
        input_frame,
        bg=Theme.BG_FIELD,
        highlightthickness=1,
        highlightbackground=Theme.BORDER,
        highlightcolor=Theme.BORDER_LIGHT,
    )
    entry_wrap.pack(side="left", fill="x", expand=True)

    self.entry_ex1 = tk.Entry(
        entry_wrap,
        disabledbackground=Theme.BG_FIELD,
        disabledforeground=Theme.TEXT_MUTED,
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        insertbackground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        font=Theme.FONT_UI,
    )
    self.entry_ex1.pack(fill="x", ipady=9, padx=12)
    self.entry_ex1.bind(
        "<Return>", lambda event: self.send_prompt(self.entry_ex1)
    )

    send_btn = tk.Button(
        input_frame,
        text="",
        font=Theme.FONT_UI_BOLD,
        bg=Theme.ACCENT,
        fg=Theme.BG_DARK,
        activebackground=Theme.ACCENT_HOVER,
        activeforeground=Theme.BG_DARK,
        relief="flat",
        bd=0,
        cursor="hand2",
        padx=18,
        command=lambda: self.send_prompt(self.entry_ex1),
    )
    add_hover(
        send_btn,
        Theme.ACCENT,
        Theme.ACCENT_HOVER,
        Theme.BG_DARK,
        Theme.BG_DARK,
    )
    send_btn.pack(side="right", padx=(10, 0), ipady=8)
    self.live.bind(send_btn, lambda: t("send"))

  # --- 2. الأيقونة العائمة (Ex:2) ---
  def setup_ex2_floating_icon(self):
    self.orb = FloatingOrb(self.root, self.EX2_SIZE, on_click=self.show_ex1)

  # --- 3. بناء الشريط المصغر (Ex:3) ---
  def setup_ex3_compact_bar(self):
    self.frame_ex3 = tk.Frame(self.root, bg=Theme.BG_DARK)

    bar_container = tk.Frame(
        self.frame_ex3,
        bg=Theme.BG_FIELD,
        highlightthickness=1,
        highlightbackground=Theme.BORDER,
    )
    bar_container.pack(fill="both", expand=True, pady=10, padx=10)

    left_icon = tk.Label(
        bar_container,
        text=" S ",
        font=("Segoe UI", 11, "bold"),
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_SECONDARY,
    )
    left_icon.pack(side="left", padx=(6, 2))

    icon_div = divider(bar_container, orient="v")
    icon_div.pack(side="left", fill="y", pady=8)

    self.entry_ex3 = tk.Entry(
        bar_container,
        disabledbackground=Theme.BG_FIELD,
        disabledforeground=Theme.TEXT_MUTED,
        bg=Theme.BG_FIELD,
        fg=Theme.TEXT_PRIMARY,
        insertbackground=Theme.TEXT_PRIMARY,
        relief="flat",
        bd=0,
        font=Theme.FONT_UI,
    )
    self.entry_ex3.pack(side="left", fill="x", expand=True, padx=10, ipady=6)
    self.entry_ex3.bind(
        "<Return>", lambda event: self.send_prompt(self.entry_ex3)
    )

    btn_expand_box = ghost_button(
        bar_container,
        "⤢",
        self.show_ex1,
        bg=Theme.BG_FIELD,
        hover_bg=Theme.BORDER,
        padx=10,
        pady=4,
    )
    btn_expand_box.pack(side="right", padx=6)

  def send_prompt(self, entry_widget):
    query = entry_widget.get().strip()
    if not query:
      return

    who = self.settings.get("user_nickname") or t("you")
    self.output_box.insert(tk.END, f"{who}  ›  ", "user_tag")
    self.output_box.insert(tk.END, f"{query}\n")
    self.output_box.see(tk.END)

    self._start_thinking(entry_widget)
    self.worker.submit(query, entry_widget)

  def _poll_results(self):
    try:
      while True:
        result, entry_widget = self.worker.results.get_nowait()
        self._show_result(result, entry_widget)
    except queue.Empty:
      pass
    self.root.after(100, self._poll_results)

  THINK_FRAMES = ("●○○", "○●○", "○○●", "○●○")

  def _start_thinking(self, entry_widget):
    self._pending.add(entry_widget)
    if self._think_job is None:
      self._think_tick = 0
      self._animate_thinking()

  def _stop_thinking(self, entry_widget):
    self._pending.discard(entry_widget)
    entry_widget.configure(state="normal")
    entry_widget.delete(0, tk.END)
    ranges = self.output_box.tag_ranges("thinking")
    if ranges:
      self.output_box.delete(ranges[0], ranges[1])

  def _animate_thinking(self):
    if not self._pending:
      self._think_job = None
      return
    frame = self.THINK_FRAMES[self._think_tick % len(self.THINK_FRAMES)]
    text = f"{t('thinking')}  {frame}"

    # داخل الحقل (يظهر في الوضعين Ex:1 و Ex:3)
    for e in self._pending:
      e.configure(state="normal")
      e.delete(0, tk.END)
      e.insert(0, text)
      e.configure(state="disabled")

    # سطر في السجل يُحدَّث في مكانه (لا يقفز التمرير)
    box = self.output_box
    line = f"SaiA ›  {text}\n"
    ranges = box.tag_ranges("thinking")
    if ranges:
      start = str(ranges[0])
      box.delete(ranges[0], ranges[1])
      box.insert(start, line, "thinking")
    else:
      box.insert(tk.END, line, "thinking")
      box.see(tk.END)

    self._think_tick += 1
    self._think_job = self.root.after(350, self._animate_thinking)

  def _show_result(self, result, entry_widget):
    if result == CLOSE_SIGNAL:
      self.root.destroy()
      return

    if result is None:
      result = t("done")

    self._stop_thinking(entry_widget)

    self.output_box.insert(tk.END, "SaiA ›  ", "bot_tag")
    self.output_box.insert(tk.END, f"{result}\n\n")
    self.output_box.see(tk.END)

    entry_widget.focus_set()

  def _place_root(self, width, height):
    geo = f"{width}x{height}"
    if self.orb.visible:
      x, y = self.orb.position()
      x = max(0, min(x, self.root.winfo_screenwidth() - width))
      y = max(0, min(y, self.root.winfo_screenheight() - height - 40))
      geo += f"+{x}+{y}"
      self.orb.hide()
    self.root.geometry(geo)

  def _reveal_root(self):
    self.root.deiconify()
    self.root.lift()
    apply_native_titlebar_color(self.root, "#ffffff", text_color="#000000")

  def show_ex1(self):
    self.frame_ex3.pack_forget()
    self._place_root(460, 580)
    self.frame_ex1.pack(fill="both", expand=True)
    self._reveal_root()

  def show_ex2(self):
    x, y = self.root.winfo_x(), self.root.winfo_y()
    self.root.withdraw()
    self.orb.show(x, y)

  def show_ex3(self):
    self.frame_ex1.pack_forget()
    self._place_root(420, 60)
    self.frame_ex3.pack(fill="both", expand=True)
    self._reveal_root()

  def _settings_alive(self):
    win = self._settings_win
    try:
      return win is not None and bool(win.window.winfo_exists())
    except tk.TclError:
      return False

  def open_settings(self):
    if self._settings_alive():
      self._settings_win.window.lift()
      self._settings_win.window.focus_force()
      return
    self._settings_win = SettingsWindow(self.root, self)

  def _apply_tag_colors(self):
    self.output_box.tag_configure("user_tag", foreground=Theme.TEXT_SECONDARY)
    self.output_box.tag_configure("bot_tag", foreground=Theme.ACCENT_HOVER)
    self.output_box.tag_configure("thinking", foreground=Theme.TEXT_MUTED)

  def toggle_theme(self):
    """يبدّل بين الوضع المضيء والداكن لكل النوافذ المفتوحة ويحفظ الاختيار"""
    old = Theme.mode
    new = "light" if old == "dark" else "dark"
    mapping = Theme.mapping(old, new)
    Theme.apply(new)
    recolor_tree(self.root, mapping)
    self._apply_tag_colors()
    self.live.refresh()
    self.settings.set(theme=new)

  def change_language(self, code):
    set_language(code)
    self.settings.set(language=get_language())
    self.live.refresh()
    self.refresh_model_pickers()
    if self._settings_alive():
      self._settings_win.window.title(t("settings_title"))

  def set_nickname(self, name):
    self.settings.set(user_nickname=name.strip())

  # --- النماذج: تُقرأ دائماً من قاعدة البيانات ---
  def models(self):
    try:
      return self.settings.db.list_models()
    except Exception:
      return []

  def model_by_id(self, model_id):
    for model in self.models():
      if model["id"] == model_id:
        return model
    return None

  def refresh_model_pickers(self):
    alive = []
    for picker in self.model_pickers:
      try:
        picker.refresh_label()
      except tk.TclError:  # أُغلقت نافذته
        continue
      alive.append(picker)
    self.model_pickers = alive

  def change_model(self, model_id):
    self.settings.set(selected_model=model_id)
    self.worker.set_model(model_id)
    self.refresh_model_pickers()


def start_app():
  app = SaiAApp()
  app.root.mainloop()


if __name__ == "__main__":
  start_app()