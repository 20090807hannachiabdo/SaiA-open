import subprocess
import sys
import threading


def _console_encoding():
    """
    أوامر الكونسول في ويندوز (ipconfig وغيرها) تطبع بترميز OEM الخاص
    بالنظام (cp720/cp1256/cp437...) وليس UTF-8، وإلا تظهر الحروف مشوّهة.
    """
    if sys.platform == "win32":
        try:
            import ctypes
            return f"cp{ctypes.windll.kernel32.GetOEMCP()}"
        except Exception:
            pass
    return "utf-8"


def run_shell_command(command, timeout=25):
    """
    يشغّل أمر شل ويرجّع نصه الناتج (stdout + stderr) بدل None.

    - بدون نافذة كونسول سوداء تومض على الشاشة (ويندوز).
    - stdin مغلق، فالأمر الذي ينتظر إدخالاً لا يعلّق البرنامج.
    - عند انتهاء المهلة لا نقتل الأمر (قد يكون تطبيقاً فتحه المستخدم عمداً
      مثل notepad)؛ نترك العملية تعمل ونرجّع رسالة فقط.
    اجعل timeout أقل من مهلة المحرك (command_timeout) حتى تظهر هذه الرسالة.
    """
    kwargs = {}
    if sys.platform == "win32":
        kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW

    proc = subprocess.Popen(
        command,
        shell=True,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        **kwargs,
    )

    try:
        out, err = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        # نستمر بتصريف مخرجات العملية في الخلفية كي لا تتجمد عند امتلاء الأنبوب
        threading.Thread(target=proc.communicate, daemon=True).start()
        return "⏱ الأمر ما زال يعمل في الخلفية ولم ينتهِ بعد."

    enc = _console_encoding()
    parts = [
        (data or b"").decode(enc, errors="replace").strip()
        for data in (out, err)
    ]
    text = "\n".join(p for p in parts if p)

    if proc.returncode != 0:
        return f"⚠ انتهى الأمر برمز خطأ {proc.returncode}\n{text}".strip()
    return text or "✓ Command executed (no output)."