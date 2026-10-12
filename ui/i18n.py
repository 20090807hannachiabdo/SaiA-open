"""
ui/i18n.py — كل نصوص الواجهة في مكان واحد.

لإضافة لغة جديدة:
  1) أضف اسمها في LANGUAGES  (الاسم الظاهر في القائمة  ->  رمز اللغة)
  2) أضف قاموساً جديداً في STRINGS تحت نفس الرمز وبنفس مفاتيح "en"
أي مفتاح ناقص في لغة ما يرجع تلقائياً للإنجليزية.

لإضافة نص جديد: أضف مفتاحه في كل اللغات، ثم استعمله في الواجهة بـ t("المفتاح").
"""

DEFAULT_LANG = "en"

# الاسم الظاهر في القائمة -> رمز اللغة
LANGUAGES = {
    "English": "en",
    "العربية": "ar",
    "Français": "fr",
}

STRINGS = {
    "en": {
        "assistant": "ASSISTANT",
        "session_log": "SESSION LOG",
        "send": "Send",
        "thinking": "Thinking",
        "you": "You",
        "done": "✓ Done.",
        "error_exec": "⚠ Error while executing: {error}",
        "settings_title": "SaiA — Settings",
        "settings": "SETTINGS",
        "back": "←  Back",
        "about": "About",
        "general": "GENERAL",
        "theme_to_light": "☀  Light mode",
        "theme_to_dark": "☾  Dark mode",
        "language": "Language",
        "profile": "PROFILE",
        "user_nickname": "Nickname",
        "save": "Save",
        "saved": "Saved ✓",
        "subscription": "Subscription",
        "account": "ACCOUNT",
        "login": "Log in",
        "sign_up": "Create account",
        "ai_model": "AI MODEL",
        "model": "Model",
        "no_models": "No models available",
    },
    "ar": {
        "assistant": "المساعد",
        "session_log": "سجل الجلسة",
        "send": "إرسال",
        "thinking": "يفكر",
        "you": "أنت",
        "done": "✓ تم.",
        "error_exec": "⚠ خطأ أثناء التنفيذ: {error}",
        "settings_title": "SaiA — الإعدادات",
        "settings": "الإعدادات",
        "back": "←  رجوع",
        "about": "حول",
        "general": "عام",
        "theme_to_light": "☀  الوضع المضيء",
        "theme_to_dark": "☾  الوضع الداكن",
        "language": "اللغة",
        "profile": "الملف الشخصي",
        "user_nickname": "التلقيب",
        "save": "حفظ",
        "saved": "تم الحفظ ✓",
        "subscription": "الاشتراك",
        "account": "الحساب",
        "login": "تسجيل الدخول",
        "sign_up": "إنشاء حساب",
        "ai_model": "نموذج الذكاء الاصطناعي",
        "model": "النموذج",
        "no_models": "لا توجد نماذج متاحة",
    },
    "fr": {
        "assistant": "ASSISTANT",
        "session_log": "JOURNAL DE SESSION",
        "send": "Envoyer",
        "thinking": "Réflexion",
        "you": "Vous",
        "done": "✓ Terminé.",
        "error_exec": "⚠ Erreur lors de l'exécution : {error}",
        "settings_title": "SaiA — Paramètres",
        "settings": "PARAMÈTRES",
        "back": "←  Retour",
        "about": "À propos",
        "general": "GÉNÉRAL",
        "theme_to_light": "☀  Mode clair",
        "theme_to_dark": "☾  Mode sombre",
        "language": "Langue",
        "profile": "PROFIL",
        "user_nickname": "Pseudo",
        "save": "Enregistrer",
        "saved": "Enregistré ✓",
        "subscription": "Abonnement",
        "account": "COMPTE",
        "login": "Se connecter",
        "sign_up": "Créer un compte",
        "ai_model": "MODÈLE IA",
        "model": "Modèle",
        "no_models": "Aucun modèle disponible",
    },
}

_current = DEFAULT_LANG


def set_language(code):
    """يغيّر اللغة الحالية (رمز غير معروف = الإنجليزية)"""
    global _current
    _current = code if code in STRINGS else DEFAULT_LANG


def get_language():
    return _current


def t(key, **kwargs):
    """يرجع نص المفتاح باللغة الحالية، وإن لم يوجد فبالإنجليزية، وإلا المفتاح نفسه"""
    text = STRINGS.get(_current, {}).get(key)
    if text is None:
        text = STRINGS[DEFAULT_LANG].get(key, key)
    return text.format(**kwargs) if kwargs else text