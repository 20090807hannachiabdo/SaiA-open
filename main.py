import os
import sys
import threading
from core.web_server import run_web_server
from storage.database import Database
from ui.app_gui import start_app


def start_web_server():
    run_web_server()


def create_database():
    db = Database(DEV=True)
    db.create_database()


def main():
    # 1. تهيئة قاعدة البيانات
    create_database()

    # 2. تشغيل سيرفر ويب في خيط ثانوي (daemon)
    web_server_thread = threading.Thread(target=start_web_server, daemon=True)
    web_server_thread.start()

    # 3. تشغيل الواجهة الرسومية (Main Thread)
    start_app()

    # 4. إنهاء العملية وكل الخيوط التابعة فور إغلاق نافذة Tkinter
    os._exit(0)


if __name__ == "__main__":
    main()