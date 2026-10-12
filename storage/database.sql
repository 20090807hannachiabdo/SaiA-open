CREATE TABLE IF NOT EXISTS sys_cmd (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code_name VARCHAR(255) NOT NULL,
    exec_payload TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS cmd_prompt (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cmd_id INTEGER NOT NULL,
    naw_query TEXT NOT NULL UNIQUE,
    norm_vec BLOB,
    FOREIGN KEY (cmd_id) REFERENCES sys_cmd(id)
);

CREATE TABLE IF NOT EXISTS user_session (
    user_id TEXT PRIMARY KEY,      
    username TEXT NOT NULL,        
    email TEXT,                   
    api_key TEXT NOT NULL,   
    logged_in_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- تفضيلات المستخدم: صف واحد فقط (id = 1)
CREATE TABLE IF NOT EXISTS user_preferences (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    theme TEXT DEFAULT 'light',               -- light / dark
    language TEXT DEFAULT 'en',               -- en / ar / fr
    user_nickname TEXT DEFAULT '',            -- الاسم المستعار (فارغ = "أنت / You / Vous")
    selected_model TEXT DEFAULT 'saia-1'      -- معرّف النموذج المختار (ai_model.id)
);
INSERT OR IGNORE INTO user_preferences (id) VALUES (1);

-- النماذج المتاحة: أضف صفاً جديداً هنا وسيظهر تلقائياً في قائمة الاختيار بالواجهة
CREATE TABLE IF NOT EXISTS ai_model (
    id TEXT PRIMARY KEY,                -- معرف النموذج (مثل: saia-1)
    model_name TEXT NOT NULL,           -- اسم النموذج للعرض في الواجهة
    description TEXT,                   -- وصف مختصر للنموذج
    version TEXT,                       -- إصدار النموذج
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP  -- آخر تحديث للنموذج
);
INSERT OR IGNORE INTO ai_model (id, model_name, description, version) VALUES
('saia-1', 'SaiA Model 1', 'Core AI', '1.0.0');

-- 3. إدراج الأوامر الرئيسية الـ 50 (باستخدام OR IGNORE لعدم التكرار)
INSERT OR IGNORE INTO sys_cmd (id, code_name, exec_payload) VALUES
(1, 'mute_volume', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]173)"'),
(2, 'volume_down', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]174)"'),
(3, 'volume_up', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]175)"'),
(4, 'media_next', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]176)"'),
(5, 'media_prev', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]177)"'),
(6, 'media_play_pause', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]179)"'),
(7, 'open_google', 'start https://www.google.com'),
(8, 'open_youtube', 'start https://www.youtube.com'),
(9, 'open_github', 'start https://www.github.com'),
(10, 'open_chatgpt', 'start https://chatgpt.com'),
(11, 'open_facebook', 'start https://www.facebook.com'),
(12, 'open_gmail', 'start https://mail.google.com'),
(13, 'open_whatsapp_web', 'start https://web.whatsapp.com'),
(14, 'open_stackoverflow', 'start https://stackoverflow.com'),
(15, 'open_notepad', 'notepad.exe'),
(16, 'open_calculator', 'calc.exe'),
(17, 'open_cmd', 'start cmd'),
(18, 'open_powershell', 'start powershell'),
(19, 'open_paint', 'mspaint.exe'),
(20, 'open_file_explorer', 'explorer.exe'),
(21, 'open_task_manager', 'taskmgr.exe'),
(22, 'open_control_panel', 'control.exe'),
(23, 'open_settings', 'start ms-settings:'),
(24, 'open_snipping_tool', 'snippingtool.exe'),
(25, 'show_ipconfig', 'ipconfig /all'),
(26, 'flush_dns', 'ipconfig /flushdns'),
(27, 'ping_google', 'ping google.com'),
(28, 'show_network_connections', 'ncpa.cpl'),
(29, 'show_active_ports', 'netstat -ano'),
(30, 'show_saved_wifi', 'netsh wlan show profiles'),
(31, 'test_network_route', 'tracert google.com'),
(32, 'renew_ip', 'ipconfig /renew'),
(33, 'lock_pc', 'rundll32.exe user32.dll,LockWorkStation'),
(34, 'sleep_pc', 'rundll32.exe powrprof.dll,SetSuspendState 0,1,0'),
(35, 'shutdown_pc', 'shutdown /s /t 60'),
(36, 'abort_shutdown', 'shutdown /a'),
(37, 'restart_pc', 'shutdown /r /t 0'),
(38, 'open_device_manager', 'devmgmt.msc'),
(39, 'open_disk_management', 'diskmgmt.msc'),
(40, 'open_services', 'services.msc'),
(41, 'open_vscode', 'code'),
(42, 'open_chrome', 'start chrome'),
(43, 'open_edge', 'msedge.exe'),
(44, 'open_wordpad', 'write.exe'),
(45, 'clean_temp_files', 'cleanmgr.exe'),
(46, 'show_system_info', 'systeminfo'),
(47, 'open_downloads_folder', 'explorer.exe %userprofile%\Downloads'),
(48, 'open_desktop_folder', 'explorer.exe %userprofile%\Desktop'),
(49, 'open_documents_folder', 'explorer.exe %userprofile%\Documents'),
(50, 'empty_recycle_bin', 'powershell -c "Clear-RecycleBin -Force"');

-- 4. إدراج الصيغ باستخدام INSERT OR IGNORE
-- عند تشغيل الكود لأول مرة: سيتم إدخال البيانات مع norm_vec = NULL.
-- عند فتح التطبيق مرة أخرى: سيتجاهل SQLite كل السطور ولن يستبدل قيمة norm_vec التي تم حسابها!
INSERT OR IGNORE INTO cmd_prompt (cmd_id, naw_query) VALUES
-- 1. mute_volume
(1, 'كتم الصوت'), (1, 'الغاء الصوت'), (1, 'صامت'), (1, 'اطفاء الصوت'), (1, 'الميوت'),
(1, 'mute volume'), (1, 'mute sound'), (1, 'silence audio'), (1, 'turn off sound'), (1, 'disable audio'),
(1, 'couper le son'), (1, 'rendre muet'), (1, 'desactiver le son'), (1, 'mode silencieux'), (1, 'eteindre le son'),

-- 2. volume_down
(2, 'اخفض الصوت'), (2, 'تنزيل الصوت'), (2, 'تقليل الصوت'), (2, 'نقص الصوت'), (2, 'صوت واطي'),
(2, 'volume down'), (2, 'lower volume'), (2, 'decrease sound'), (2, 'turn down sound'), (2, 'make quieter'),
(2, 'baisser le son'), (2, 'diminuer le volume'), (2, 'reduire le son'), (2, 'moins de son'), (2, 'baisser le volume'),

-- 3. volume_up
(3, 'ارفع الصوت'), (3, 'تعلية الصوت'), (3, 'زيادة الصوت'), (3, 'كبر الصوت'), (3, 'صوت عال'),
(3, 'volume up'), (3, 'increase volume'), (3, 'turn up sound'), (3, 'raise volume'), (3, 'make louder'),
(3, 'augmenter le son'), (3, 'monter le volume'), (3, 'plus de son'), (3, 'hausser le volume'), (3, 'monter le son'),

-- 4. media_next
(4, 'التالي'), (4, 'شغل الأغنية التالية'), (4, 'المقطع التالي'), (4, 'شغل المقطع القادم'), (4, 'تخطي'),
(4, 'next track'), (4, 'next song'), (4, 'play next'), (4, 'skip song'), (4, 'next media'),
(4, 'piste suivante'), (4, 'chanson suivante'), (4, 'passer au suivant'), (4, 'suivant'), (4, 'media suivant'),

-- 5. media_prev
(5, 'السابق'), (5, 'شغل الأغنية السابقة'), (5, 'المقطع السابق'), (5, 'ارجع للخلف'), (5, 'المقطع القديم'),
(5, 'previous track'), (5, 'previous song'), (5, 'play previous'), (5, 'go back song'), (5, 'prev media'),
(5, 'piste precedente'), (5, 'chanson precedente'), (5, 'precedent'), (5, 'retourner en arriere'), (5, 'media precedent'),

-- 6. media_play_pause
(6, 'تشغيل مؤقت'), (6, 'ايقاف مؤقت'), (6, 'شغل الصوت'), (6, 'وقف الصوت'), (6, 'تشغيل او ايقاف'),
(6, 'play pause'), (6, 'pause media'), (6, 'resume music'), (6, 'stop audio'), (6, 'play track'),
(6, 'lecture pause'), (6, 'mettre en pause'), (6, 'relancer la musique'), (6, 'arreter la musique'), (6, 'jouer le media'),

-- 7. open_google
(7, 'افتح جوجل'), (7, 'افتح متصفح جوجل'), (7, 'افتح محرك البحث'), (7, 'شغل google'), (7, 'دخول جوجل'),
(7, 'open google'), (7, 'launch google'), (7, 'go to google'), (7, 'open search engine'), (7, 'start google'),
(7, 'ouvrir google'), (7, 'lancer google'), (7, 'aller sur google'), (7, 'afficher google'), (7, 'page google'),

-- 8. open_youtube
(8, 'افتح يوتيوب'), (8, 'شغل يوتيوب'), (8, 'افتح الفيديوهات'), (8, 'ذهاب الى يوتيوب'), (8, 'موقع يوتيوب'),
(8, 'open youtube'), (8, 'launch youtube'), (8, 'go to youtube'), (8, 'open videos'), (8, 'start youtube'),
(8, 'ouvrir youtube'), (8, 'lancer youtube'), (8, 'aller sur youtube'), (8, 'afficher youtube'), (8, 'site youtube'),

-- 9. open_github
(9, 'افتح جيت هاب'), (9, 'افتح github'), (9, 'موقع github'), (9, 'شغل github'), (9, 'دخول جيت هاب'),
(9, 'open github'), (9, 'launch github'), (9, 'go to github'), (9, 'open code repository'), (9, 'start github'),
(9, 'ouvrir github'), (9, 'lancer github'), (9, 'aller sur github'), (9, 'afficher github'), (9, 'site github'),

-- 10. open_chatgpt
(10, 'افتح شات جي بي تي'), (10, 'افتح chatgpt'), (10, 'شغل الذكاء الاصطناعي'), (10, 'موقع chatgpt'), (10, 'دخول شات جي بي تي'),
(10, 'open chatgpt'), (10, 'launch chatgpt'), (10, 'go to chatgpt'), (10, 'open ai chat'), (10, 'start chatgpt'),
(10, 'ouvrir chatgpt'), (10, 'lancer chatgpt'), (10, 'aller sur chatgpt'), (10, 'afficher chatgpt'), (10, 'chat ai'),

-- 11. open_facebook
(11, 'افتح فيسبوك'), (11, 'شغل فيسبوك'), (11, 'موقع فيسبوك'), (11, 'دخول فيسبوك'), (11, 'افتح facebook'),
(11, 'open facebook'), (11, 'launch facebook'), (11, 'go to facebook'), (11, 'open fb'), (11, 'start facebook'),
(11, 'ouvrir facebook'), (11, 'lancer facebook'), (11, 'aller sur facebook'), (11, 'afficher facebook'), (11, 'site facebook'),

-- 12. open_gmail
(12, 'افتح الجيميل'), (12, 'افتح البريد الإلكتروني'), (12, 'شغل gmail'), (12, 'دخول جيميل'), (12, 'افتح الرسائل'),
(12, 'open gmail'), (12, 'launch gmail'), (12, 'check email'), (12, 'go to gmail'), (12, 'open mail'),
(12, 'ouvrir gmail'), (12, 'lancer gmail'), (12, 'consulter mes mails'), (12, 'aller sur gmail'), (12, 'boite mail'),

-- 13. open_whatsapp_web
(13, 'افتح واتساب ويب'), (13, 'شغل واتس اب'), (13, 'موقع واتساب'), (13, 'افتح whatsapp'), (13, 'دخول واتس'),
(13, 'open whatsapp web'), (13, 'launch whatsapp'), (13, 'go to whatsapp'), (13, 'open web whatsapp'), (13, 'start whatsapp'),
(13, 'ouvrir whatsapp web'), (13, 'lancer whatsapp'), (13, 'aller sur whatsapp'), (13, 'afficher whatsapp'), (13, 'web whatsapp'),

-- 14. open_stackoverflow
(14, 'افتح ستك اوفر فلو'), (14, 'افتح stackoverflow'), (14, 'شغل stackoverflow'), (14, 'موقع البرمجة'), (14, 'دخول ستك اوفر فلو'),
(14, 'open stackoverflow'), (14, 'launch stackoverflow'), (14, 'go to stackoverflow'), (14, 'open developer forum'), (14, 'start stackoverflow'),
(14, 'ouvrir stackoverflow'), (14, 'lancer stackoverflow'), (14, 'aller sur stackoverflow'), (14, 'afficher stackoverflow'), (14, 'site stackoverflow'),

-- 15. open_notepad
(15, 'افتح المفكرة'), (15, 'افتح النوت باد'), (15, 'شغل notepad'), (15, 'افتح دفتر الملاحظات'), (15, 'كتابة ملاحظة'),
(15, 'open notepad'), (15, 'launch notepad'), (15, 'open text editor'), (15, 'start notepad'), (15, 'create note'),
(15, 'ouvrir le bloc notes'), (15, 'lancer notepad'), (15, 'ouvrir notepad'), (15, 'editeur de texte'), (15, 'bloc notes'),

-- 16. open_calculator
(16, 'افتح الحاسبة'), (16, 'شغل الآلة الحاسبة'), (16, 'افتح الالة الحاسبة'), (16, 'حساب رياضيات'), (16, 'افتح calculator'),
(16, 'open calculator'), (16, 'launch calc'), (16, 'start calculator'), (16, 'open math tool'), (16, 'calculator app'),
(16, 'ouvrir la calculatrice'), (16, 'lancer la calculatrice'), (16, 'afficher calculatrice'), (16, 'calculatrice'), (16, 'ouvrir calc'),

-- 17. open_cmd
(17, 'افتح موجه الأوامر'), (17, 'افتح الـ cmd'), (17, 'شغل cmd'), (17, 'نافذة الاوامر'), (17, 'شاشة الاوامر'),
(17, 'open cmd'), (17, 'launch command prompt'), (17, 'open terminal'), (17, 'start cmd'), (17, 'open console'),
(17, 'ouvrir l invite de commandes'), (17, 'lancer cmd'), (17, 'ouvrir cmd'), (17, 'terminal cmd'), (17, 'invite de commande'),

-- 18. open_powershell
(18, 'افتح الباور شيل'), (18, 'افتح powershell'), (18, 'شغل powershell'), (18, 'نافذة powershell'), (18, 'تشغيل باور شيل'),
(18, 'open powershell'), (18, 'launch powershell'), (18, 'start powershell'), (18, 'powershell terminal'), (18, 'open ps console'),
(18, 'ouvrir powershell'), (18, 'lancer powershell'), (18, 'terminal powershell'), (18, 'console powershell'), (18, 'afficher powershell'),

-- 19. open_paint
(19, 'افتح الرسام'), (19, 'شغل برنامج الرسام'), (19, 'افتح paint'), (19, 'برنامج الرسم'), (19, 'افتح الملاحظات المصورة'),
(19, 'open paint'), (19, 'launch mspaint'), (19, 'start paint'), (19, 'open drawing tool'), (19, 'paint app'),
(19, 'ouvrir paint'), (19, 'lancer mspaint'), (19, 'logiciel de dessin'), (19, 'afficher paint'), (19, 'programme paint'),

-- 20. open_file_explorer
(20, 'افتح مستكشف الملفات'), (20, 'افتح الملفات'), (20, 'عرض الملفات'), (20, 'مستكشف النظام'), (20, 'افتح explorer'),
(20, 'open file explorer'), (20, 'launch explorer'), (20, 'open my computer'), (20, 'show files'), (20, 'open file manager'),
(20, 'ouvrir l explorateur de fichiers'), (20, 'lancer explorateur'), (20, 'voir les fichiers'), (20, 'explorateur windows'), (20, 'gestionnaire de fichiers'),

-- 21. open_task_manager
(21, 'افتح إدارة المهام'), (21, 'افتح تاسك مانجر'), (21, 'شغل task manager'), (21, 'مراقبة البرامج'), (21, 'افتح المعالج'),
(21, 'open task manager'), (21, 'launch task manager'), (21, 'start taskmgr'), (21, 'show running tasks'), (21, 'open task window'),
(21, 'ouvrir le gestionnaire des taches'), (21, 'lancer task manager'), (21, 'gestionnaire des taches'), (21, 'voir les processus'), (21, 'task manager'),

-- 22. open_control_panel
(22, 'افتح لوحة التحكم'), (22, 'افتح كنترول بانل'), (22, 'شغل control panel'), (22, 'اعدادات التحكم'), (22, 'لوحة النظام'),
(22, 'open control panel'), (22, 'launch control panel'), (22, 'start control panel'), (22, 'system control panel'), (22, 'open settings control'),
(22, 'ouvrir le panneau de configuration'), (22, 'lancer control panel'), (22, 'panneau de configuration'), (22, 'afficher panneau de controle'), (22, 'configuration systeme'),

-- 23. open_settings
(23, 'افتح الإعدادات'), (23, 'افتح اعدادات النظام'), (23, 'شغل Settings'), (23, 'ضبط الجهاز'), (23, 'خيارات النظام'),
(23, 'open settings'), (23, 'launch system settings'), (23, 'open windows settings'), (23, 'go to settings'), (23, 'show settings'),
(23, 'ouvrir les parametres'), (23, 'lancer parametres'), (23, 'parametres windows'), (23, 'afficher parametres'), (23, 'configuration'),

-- 24. open_snipping_tool
(24, 'افتح أداة القطع'), (24, 'افتح أداة قص الشاشة'), (24, 'تصوير الشاشة'), (24, 'شغل snipping tool'), (24, 'اخذ لقطة شاشة'),
(24, 'open snipping tool'), (24, 'launch snipping tool'), (24, 'take screenshot tool'), (24, 'start snipping tool'), (24, 'screen capture tool'),
(24, 'ouvrir l outil capture d ecran'), (24, 'lancer outil capture'), (24, 'capture d ecran'), (24, 'outil de capture'), (24, 'afficher snipping tool'),

-- 25. show_ipconfig
(25, 'عرض عنوان IP'), (25, 'اظهار الـ ip'), (25, 'معلومات الشبكة ipconfig'), (25, 'فحص IP'), (25, 'عنوان الشبكة'),
(25, 'show ip address'), (25, 'run ipconfig'), (25, 'display network ip'), (25, 'get my ip'), (25, 'show ip configuration'),
(25, 'afficher adresse ip'), (25, 'executer ipconfig'), (25, 'voir mon ip'), (25, 'configuration ip'), (25, 'montrer l ip'),

-- 26. flush_dns
(26, 'تنظيف DNS'), (26, 'مسح الـ DNS'), (26, 'تحديث الـ DNS'), (26, 'إعادة ضبط DNS'), (26, 'تفريغ كاش الـ DNS'),
(26, 'flush dns'), (26, 'clear dns cache'), (26, 'reset dns'), (26, 'purge dns'), (26, 'clean dns cache'),
(26, 'vider le cache dns'), (26, 'nettoyer le dns'), (26, 'reinitialiser dns'), (26, 'purger le dns'), (26, 'effacer cache dns'),

-- 27. ping_google
(27, 'اختبار الاتصال بجوجل'), (27, 'اعمل بينج لجوجل'), (27, 'فحص انترنت جوجل'), (27, 'ping جوجل'), (27, 'اختبار الستجابة'),
(27, 'ping google'), (27, 'test connection to google'), (27, 'check internet ping'), (27, 'ping google com'), (27, 'network test google'),
(27, 'pinger google'), (27, 'tester connexion google'), (27, 'verifier internet ping'), (27, 'test de ping google'), (27, 'ping vers google'),

-- 28. show_network_connections
(28, 'عرض اتصالات الشبكة'), (28, 'افتح محولات الشبكة'), (28, 'شبكات الكروت'), (28, 'إعدادات شبكات الاتصال'), (28, 'عرض الكروت الشبكية'),
(28, 'show network connections'), (28, 'open network adapters'), (28, 'view connections'), (28, 'open ncpa cpl'), (28, 'show network cards'),
(28, 'afficher connexions reseau'), (28, 'ouvrir cartes reseau'), (28, 'voir les connexions'), (28, 'parametres des cartes reseau'), (28, 'reseaux disponibles'),

-- 29. show_active_ports
(29, 'عرض المنافذ النشطة'), (29, 'اظهار البورتات المفتوحة'), (29, 'فحص الاتصالات النشطة'), (29, 'البورتات الشغالة'), (29, 'عرض المنافذ المفتوحة'),
(29, 'show active ports'), (29, 'show open ports'), (29, 'check netstat'), (29, 'list listening ports'), (29, 'view network ports'),
(29, 'afficher ports actifs'), (29, 'voir les ports ouverts'), (29, 'liste des ports'), (29, 'verifier netstat'), (29, 'ports de connexion'),

-- 30. show_saved_wifi
(30, 'عرض شبكات الواي فاي المحفوظة'), (30, 'اظهار كلمات سر الواي فاي'), (30, 'شبكات wifi المحفوظة'), (30, 'عرض ملفات Wifi'), (30, 'فحص شبكات الواي فاي'),
(30, 'show saved wifi'), (30, 'show wifi profiles'), (30, 'view saved wifi networks'), (30, 'list wifi passwords'), (30, 'get wifi profiles'),
(30, 'afficher reseaux wifi enregistres'), (30, 'voir profils wifi'), (30, 'liste des reseaux wifi'), (30, 'wifi enregistres'), (30, 'reseaux wifi sauvés'),

-- 31. test_network_route
(31, 'تتبع مسار الشبكة'), (31, 'عمل tracert لجوجل'), (31, 'فحص المسار للإنترنت'), (31, 'تتبع الشبكة'), (31, 'مسار الاتصال'),
(31, 'test network route'), (31, 'tracert google'), (31, 'trace network path'), (31, 'check connection route'), (31, 'trace route google'),
(31, 'tracer la route reseau'), (31, 'tracert vers google'), (31, 'suivre le chemin reseau'), (31, 'verifier la route reseau'), (31, 'test de route'),

-- 32. renew_ip
(32, 'تجديد عنوان IP'), (32, 'تحديث IP الشبكة'), (32, 'إعادة طلب IP'), (32, 'عمل ipconfig renew'), (32, 'تجديد الاتصال'),
(32, 'renew ip address'), (32, 'refresh ip'), (32, 'get new ip'), (32, 'run ipconfig renew'), (32, 'reconnect ip'),
(32, 'renouveler l adresse ip'), (32, 'rafraichir ip'), (32, 'obtenir nouvelle ip'), (32, 'renouveler ip'), (32, 'reinitialiser adresse ip'),

-- 33. lock_pc
(33, 'قفل الكمبيوتر'), (33, 'قفل الشاشة'), (33, 'قفل الجهاز'), (33, 'أغلق الشاشة'), (33, 'تأمين الكمبيوتر'),
(33, 'lock pc'), (33, 'lock computer'), (33, 'lock screen'), (33, 'secure pc'), (33, 'lock workstation'),
(33, 'verrouiller le pc'), (33, 'verrouiller l ordinateur'), (33, 'bloquer l ecran'), (33, 'verrouiller session'), (33, 'mettre sous verrou'),

-- 34. sleep_pc
(34, 'إدراج الكمبيوتر في وضع النوم'), (34, 'وضع السكون'), (34, 'عمل sleep للجهاز'), (34, 'إيقاف مؤقت للجهاز'), (34, 'تنويم الكمبيوتر'),
(34, 'sleep pc'), (34, 'put computer to sleep'), (34, 'sleep mode'), (34, 'suspend pc'), (34, 'standby mode'),
(34, 'mettre en veille'), (34, 'mettre l ordinateur en veille'), (34, 'mode veille'), (34, 'suspendre le pc'), (34, 'mise en veille'),

-- 35. shutdown_pc
(35, 'إطفاء الكمبيوتر'), (35, 'إغلاق الجهاز'), (35, 'إيقاف تشغيل النظام'), (35, 'اطفاء الجهاز بعد دقيقة'), (35, 'قفل النظام'),
(35, 'shutdown pc'), (35, 'turn off computer'), (35, 'power off pc'), (35, 'shutdown computer'), (35, 'stop system'),
(35, 'eteindre l ordinateur'), (35, 'eteindre le pc'), (35, 'arreter le systeme'), (35, 'fermer l ordinateur'), (35, 'extinction du pc'),

-- 36. abort_shutdown
(36, 'إلغاء إطفاء الكمبيوتر'), (36, 'إلغاء الإغلاق'), (36, 'توقيف إيقاف التشغيل'), (36, 'منع إطفاء الجهاز'), (36, 'إلغاء الإيقاف'),
(36, 'abort shutdown'), (36, 'cancel shutdown'), (36, 'stop shutdown timer'), (36, 'prevent power off'), (36, 'cancel turn off'),
(36, 'annuler l extinction'), (36, 'annuler l arret du pc'), (36, 'stopper l arret'), (36, 'interrompre l extinction'), (36, 'annuler fermeture'),

-- 37. restart_pc
(37, 'إعادة تشغيل الكمبيوتر'), (37, 'إعادة تشغيل الجهاز'), (37, 'اعمل ريستارت'), (37, 'تحديث التشغيل'), (37, 'إعادة اقلاع النظام'),
(37, 'restart pc'), (37, 'reboot computer'), (37, 'restart system'), (37, 'reboot pc'), (37, 'restart machine'),
(37, 'redemarrer l ordinateur'), (37, 'redemarrer le pc'), (37, 'relancer le systeme'), (37, 'rebooter le pc'), (37, 'redemarrage du systeme'),

-- 38. open_device_manager
(38, 'افتح إدارة الأجهزة'), (38, 'افتح ديفايس مانجر'), (38, 'عرض تعريفات الجهاز'), (38, 'إدارة القطع'), (38, 'عرض العتاد'),
(38, 'open device manager'), (38, 'launch device manager'), (38, 'show hardware devices'), (38, 'open devmgmt'), (38, 'manage drivers'),
(38, 'ouvrir le gestionnaire de peripheriques'), (38, 'lancer gestionnaire peripheriques'), (38, 'voir le materiel'), (38, 'gestionnaire de peripheriques'), (38, 'afficher pilotes'),

-- 39. open_disk_management
(39, 'افتح إدارة الأقراص'), (39, 'تقسيم الهارد'), (39, 'عرض الأقراص الصلبة'), (39, 'ادارة الهارد ديسك'), (39, 'افتح diskmgmt'),
(39, 'open disk management'), (39, 'launch disk manager'), (39, 'manage hard drives'), (39, 'show partitions'), (39, 'open disk partition tool'),
(39, 'ouvrir la gestion des disques'), (39, 'lancer gestionnaire de disque'), (39, 'partiionner le disque'), (39, 'voir les disques dur'), (39, 'gestion des partitions'),

-- 40. open_services
(40, 'افتح خدمات النظام'), (40, 'افتح السيرفيسز'), (40, 'شغل services msc'), (40, 'عرض الخدمات الشغالة'), (40, 'إدارة خدمات الويندوز'),
(40, 'open system services'), (40, 'launch services msc'), (40, 'show background services'), (40, 'manage windows services'), (40, 'open services window'),
(40, 'ouvrir les services systeme'), (40, 'lancer services msc'), (40, 'voir les services en arriere plan'), (40, 'gestionnaire de services'), (40, 'services windows'),

-- 41. open_vscode
(41, 'افتح فيجوال ستوديو كود'), (41, 'شغل VS Code'), (41, 'افتح البرمجة code'), (41, 'برنامج vscode'), (41, 'فتح محرّر الكود'),
(41, 'open vscode'), (41, 'launch visual studio code'), (41, 'open code editor'), (41, 'start vscode'), (41, 'open vs code'),
(41, 'ouvrir vscode'), (41, 'lancer visual studio code'), (41, 'ouvrir editeur de code'), (41, 'demarrer vscode'), (41, 'afficher vs code'),

-- 42. open_chrome
(42, 'افتح متصفح كروم'), (42, 'شغل جوجل كروم'), (42, 'افتح chrome'), (42, 'متصفح الإنترنت كروم'), (42, 'تشغيل chrome'),
(42, 'open chrome browser'), (42, 'launch google chrome'), (42, 'start chrome'), (42, 'open chrome'), (42, 'chrome browser'),
(42, 'ouvrir chrome'), (42, 'lancer google chrome'), (42, 'demarrer chrome'), (42, 'navigateur chrome'), (42, 'afficher chrome'),

-- 43. open_edge
(43, 'افتح متصفح إيدج'), (43, 'شغل مايكروسوفت إيدج'), (43, 'افتح msedge'), (43, 'متصفح edge'), (43, 'تشغيل edge'),
(43, 'open microsoft edge'), (43, 'launch edge browser'), (43, 'start msedge'), (43, 'open edge'), (43, 'edge browser'),
(43, 'ouvrir microsoft edge'), (43, 'lancer edge'), (43, 'demarrer edge'), (43, 'navigateur edge'), (43, 'afficher edge'),

-- 44. open_wordpad
(44, 'افتح برنامج وورد باد'), (44, 'افتح الدفتر'), (44, 'شغل wordpad'), (44, 'محرر النصوص ووردباد'), (44, 'كتابة نص ووردباد'),
(44, 'open wordpad'), (44, 'launch wordpad'), (44, 'start write app'), (44, 'open rich text editor'), (44, 'wordpad app'),
(44, 'ouvrir wordpad'), (44, 'lancer wordpad'), (44, 'editeur wordpad'), (44, 'afficher wordpad'), (44, 'programme wordpad'),

-- 45. clean_temp_files
(45, 'تنظيف الملفات المؤقتة'), (45, 'تنظيف القرص'), (45, 'مسح الملفات الزائدة'), (45, 'افتح تنظيف القرص cleanmgr'), (45, 'تسريع الجهاز'),
(45, 'clean temp files'), (45, 'run disk cleanup'), (45, 'clear temporary files'), (45, 'free up space'), (45, 'start cleanmgr'),
(45, 'nettoyer les fichiers temporaires'), (45, 'nettoyage de disque'), (45, 'effacer les fichiers inutiles'), (45, 'liberer de l espace'), (45, 'lancer cleanmgr'),

-- 46. show_system_info
(46, 'عرض مواصفات الجهاز'), (46, 'معلومات النظام'), (46, 'فحص مواصفات الكمبيوتر'), (46, 'اظهار systeminfo'), (46, 'مواصفات النظام'),
(46, 'show system info'), (46, 'display system information'), (46, 'get pc specs'), (46, 'run systeminfo'), (46, 'view system properties'),
(46, 'afficher infos systeme'), (46, 'voir les caracteristiques du pc'), (46, 'informations systeme'), (46, 'specs de l ordinateur'), (46, 'proprietes du systeme'),

-- 47. open_downloads_folder
(47, 'افتح مجلد التنزيلات'), (47, 'افتح الـ Downloads'), (47, 'عرض الملفات المحملة'), (47, 'مجلد الداونلود'), (47, 'الملفات التنزيلية'),
(47, 'open downloads folder'), (47, 'show downloads'), (47, 'go to downloads'), (47, 'open my downloads'), (47, 'view downloaded files'),
(47, 'ouvrir le dossier telechargements'), (47, 'voir les telechargements'), (47, 'afficher downloads'), (47, 'dossier telechargements'), (47, 'aller aux telechargements'),

-- 48. open_desktop_folder
(48, 'افتح مجلد سطح المكتب'), (48, 'مجلد الديسك توب'), (48, 'عرض ملفات سطح المكتب'), (48, 'افتح Desktop'), (48, 'ملفات الشاشة الرئيسية'),
(48, 'open desktop folder'), (48, 'show desktop files'), (48, 'go to desktop folder'), (48, 'open my desktop'), (48, 'view desktop location'),
(48, 'ouvrir le dossier bureau'), (48, 'voir les fichiers du bureau'), (48, 'afficher le bureau'), (48, 'dossier bureau'), (48, 'aller au bureau'),

-- 49. open_documents_folder
(49, 'افتح مجلد المستندات'), (49, 'افتح الوثائق'), (49, 'مجلد Documents'), (49, 'عرض المستندات'), (49, 'ملفات المستندات'),
(49, 'open documents folder'), (49, 'show my documents'), (49, 'go to documents'), (49, 'view documents'), (49, 'open docs folder'),
(49, 'ouvrir le dossier documents'), (49, 'voir mes documents'), (49, 'afficher mes documents'), (49, 'dossier mes documents'), (49, 'aller aux documents'),

-- 50. empty_recycle_bin
(50, 'تفريغ سلة المهملات'), (50, 'تنظيف سلة المحذوفات'), (50, 'مسح السلة'), (50, 'حذف ملفات المهملات'), (50, 'تفريغ الـ Recycle Bin'),
(50, 'empty recycle bin'), (50, 'clear trash bin'), (50, 'clean recycle bin'), (50, 'empty trash'), (50, 'purge recycle bin'),
(50, 'vider la corbeille'), (50, 'nettoyer la corbeille'), (50, 'effacer la corbeille'), (50, 'vider les poubelles'), (50, 'purger la corbeille');





-- =========================================================
--  أوامر إضافية: 200 أمر (id 51..250) × 21 صيغة (8 إنجليزي + 7 عربي + 6 فرنسي)
--  ألصق هذا الملف في آخر database.sql (بعد كتلة الصيغ الحالية)
-- =========================================================

-- إزالة جدول الحساب/مفتاح API القديم (لم يعد مستخدماً)
DROP TABLE IF EXISTS user_session;

INSERT OR IGNORE INTO sys_cmd (id, code_name, exec_payload) VALUES
(51, 'open_instagram', 'start https://www.instagram.com'),
(52, 'open_twitter', 'start https://x.com'),
(53, 'open_linkedin', 'start https://www.linkedin.com'),
(54, 'open_reddit', 'start https://www.reddit.com'),
(55, 'open_netflix', 'start https://www.netflix.com'),
(56, 'open_amazon', 'start https://www.amazon.com'),
(57, 'open_wikipedia', 'start https://www.wikipedia.org'),
(58, 'open_google_maps', 'start https://maps.google.com'),
(59, 'open_google_drive', 'start https://drive.google.com'),
(60, 'open_google_translate', 'start https://translate.google.com'),
(61, 'open_google_calendar', 'start https://calendar.google.com'),
(62, 'open_google_docs', 'start https://docs.google.com'),
(63, 'open_google_news', 'start https://news.google.com'),
(64, 'open_bing', 'start https://www.bing.com'),
(65, 'open_duckduckgo', 'start https://duckduckgo.com'),
(66, 'open_yahoo', 'start https://www.yahoo.com'),
(67, 'open_outlook_web', 'start https://outlook.live.com'),
(68, 'open_twitch', 'start https://www.twitch.tv'),
(69, 'open_soundcloud', 'start https://soundcloud.com'),
(70, 'open_pinterest', 'start https://www.pinterest.com'),
(71, 'open_tiktok', 'start https://www.tiktok.com'),
(72, 'open_telegram_web', 'start https://web.telegram.org'),
(73, 'open_discord', 'start https://discord.com/app'),
(74, 'open_google_meet', 'start https://meet.google.com'),
(75, 'open_canva', 'start https://www.canva.com'),
(76, 'open_figma', 'start https://www.figma.com'),
(77, 'open_notion', 'start https://www.notion.so'),
(78, 'open_trello', 'start https://trello.com'),
(79, 'open_dropbox', 'start https://www.dropbox.com'),
(80, 'open_ebay', 'start https://www.ebay.com'),
(81, 'open_aliexpress', 'start https://www.aliexpress.com'),
(82, 'open_paypal', 'start https://www.paypal.com'),
(83, 'open_booking', 'start https://www.booking.com'),
(84, 'open_imdb', 'start https://www.imdb.com'),
(85, 'open_weather', 'start https://weather.com'),
(86, 'open_w3schools', 'start https://www.w3schools.com'),
(87, 'open_pypi', 'start https://pypi.org'),
(88, 'open_huggingface', 'start https://huggingface.co'),
(89, 'open_kaggle', 'start https://www.kaggle.com'),
(90, 'open_udemy', 'start https://www.udemy.com'),
(91, 'open_windows_terminal', 'start wt'),
(92, 'open_registry_editor', 'start regedit'),
(93, 'open_system_configuration_tool', 'start msconfig'),
(94, 'open_resource_monitor', 'start resmon'),
(95, 'open_performance_monitor', 'start perfmon'),
(96, 'open_event_viewer', 'start eventvwr'),
(97, 'open_computer_management', 'start compmgmt.msc'),
(98, 'open_task_scheduler', 'start taskschd.msc'),
(99, 'open_directx_diagnostic_tool', 'start dxdiag'),
(100, 'open_about_windows_dialog', 'start winver'),
(101, 'open_disk_defragmenter', 'start dfrgui'),
(102, 'open_remote_desktop_connection', 'start mstsc'),
(103, 'open_magnifier', 'start magnify'),
(104, 'open_narrator', 'start narrator'),
(105, 'open_on_screen_keyboard', 'start osk'),
(106, 'open_character_map', 'start charmap'),
(107, 'open_windows_firewall', 'start firewall.cpl'),
(108, 'open_certificate_manager', 'start certmgr.msc'),
(109, 'open_volume_mixer', 'start sndvol'),
(110, 'open_windows_media_player', 'start wmplayer'),
(111, 'open_photos_app', 'start ms-photos:'),
(112, 'open_alarm_clock_app', 'start ms-clock:'),
(113, 'open_camera_app', 'start microsoft.windows.camera:'),
(114, 'open_microsoft_store', 'start ms-windows-store:'),
(115, 'open_microsoft_word', 'start winword'),
(116, 'open_microsoft_excel', 'start excel'),
(117, 'open_microsoft_powerpoint', 'start powerpnt'),
(118, 'open_outlook_desktop', 'start outlook'),
(119, 'open_onenote', 'start onenote'),
(120, 'open_mozilla_firefox', 'start firefox'),
(121, 'open_brave_browser', 'start brave'),
(122, 'open_opera_browser', 'start opera'),
(123, 'open_steam', 'start steam://open/main'),
(124, 'open_python_console', 'start cmd /k python'),
(125, 'open_wsl', 'start wsl'),
(126, 'open_environment_variables', 'start rundll32 sysdm.cpl,EditEnvironmentVariables'),
(127, 'open_programs_and_features', 'start appwiz.cpl'),
(128, 'open_internet_options', 'start inetcpl.cpl'),
(129, 'open_power_options', 'start powercfg.cpl'),
(130, 'open_user_accounts', 'start netplwiz'),
(131, 'open_bluetooth_file_transfer', 'start fsquirt'),
(132, 'open_malicious_software_removal_tool', 'start mrt'),
(133, 'open_security_and_maintenance', 'start wscui.cpl'),
(134, 'open_group_policy_editor', 'start gpedit.msc'),
(135, 'open_reliability_monitor', 'start perfmon /rel'),
(136, 'open_shared_folders_manager', 'start fsmgmt.msc'),
(137, 'open_windows_features_dialog', 'start optionalfeatures'),
(138, 'open_maps_app', 'start bingmaps:'),
(139, 'open_xbox_app', 'start xbox:'),
(140, 'open_management_console', 'start mmc'),
(141, 'open_system_restore', 'start rstrui'),
(142, 'open_memory_diagnostic', 'start mdsched'),
(143, 'open_run_dialog', 'rundll32 shell32.dll,#61'),
(144, 'open_start_menu', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys(''^{ESC}'')"'),
(145, 'open_notification_center', 'start ms-actioncenter:'),
(146, 'open_display_settings', 'start ms-settings:display'),
(147, 'open_sound_settings', 'start ms-settings:sound'),
(148, 'open_bluetooth_settings', 'start ms-settings:bluetooth'),
(149, 'open_wifi_settings', 'start ms-settings:network-wifi'),
(150, 'open_vpn_settings', 'start ms-settings:network-vpn'),
(151, 'open_proxy_settings', 'start ms-settings:network-proxy'),
(152, 'open_battery_settings', 'start ms-settings:batterysaver'),
(153, 'open_storage_settings', 'start ms-settings:storagesense'),
(154, 'open_privacy_settings', 'start ms-settings:privacy'),
(155, 'open_camera_privacy_settings', 'start ms-settings:privacy-webcam'),
(156, 'open_microphone_privacy_settings', 'start ms-settings:privacy-microphone'),
(157, 'open_location_privacy_settings', 'start ms-settings:privacy-location'),
(158, 'open_notifications_settings', 'start ms-settings:notifications'),
(159, 'open_focus_assist_settings', 'start ms-settings:quiethours'),
(160, 'open_night_light_settings', 'start ms-settings:nightlight'),
(161, 'open_taskbar_settings', 'start ms-settings:taskbar'),
(162, 'open_themes_settings', 'start ms-settings:themes'),
(163, 'open_colors_settings', 'start ms-settings:colors'),
(164, 'open_wallpaper_settings', 'start ms-settings:personalization-background'),
(165, 'open_lock_screen_settings', 'start ms-settings:lockscreen'),
(166, 'open_fonts_settings', 'start ms-settings:fonts'),
(167, 'open_default_apps_settings', 'start ms-settings:defaultapps'),
(168, 'open_installed_apps_settings', 'start ms-settings:appsfeatures'),
(169, 'open_startup_apps_settings', 'start ms-settings:startupapps'),
(170, 'open_windows_update_settings', 'start ms-settings:windowsupdate'),
(171, 'open_recovery_settings', 'start ms-settings:recovery'),
(172, 'open_activation_settings', 'start ms-settings:activation'),
(173, 'open_date_and_time_settings', 'start ms-settings:dateandtime'),
(174, 'open_language_settings', 'start ms-settings:regionlanguage'),
(175, 'open_typing_settings', 'start ms-settings:typing'),
(176, 'open_mouse_settings', 'start ms-settings:mousetouchpad'),
(177, 'open_accessibility_settings', 'start ms-settings:easeofaccess'),
(178, 'open_high_contrast_settings', 'start ms-settings:easeofaccess-highcontrast'),
(179, 'open_game_bar_settings', 'start ms-settings:gaming-gamebar'),
(180, 'open_game_mode_settings', 'start ms-settings:gaming-gamemode'),
(181, 'open_clipboard_settings', 'start ms-settings:clipboard'),
(182, 'open_airplane_mode_settings', 'start ms-settings:network-airplanemode'),
(183, 'open_mobile_hotspot_settings', 'start ms-settings:network-mobilehotspot'),
(184, 'open_ethernet_settings', 'start ms-settings:network-ethernet'),
(185, 'open_sign_in_options_settings', 'start ms-settings:signinoptions'),
(186, 'open_backup_settings', 'start ms-settings:backup'),
(187, 'open_windows_security_settings', 'start ms-settings:windowsdefender'),
(188, 'open_printers_settings', 'start ms-settings:printers'),
(189, 'open_sleep_settings', 'start ms-settings:powersleep'),
(190, 'open_account_info_settings', 'start ms-settings:yourinfo'),
(191, 'open_pictures_folder', 'explorer.exe %userprofile%\Pictures'),
(192, 'open_music_folder', 'explorer.exe %userprofile%\Music'),
(193, 'open_videos_folder', 'explorer.exe %userprofile%\Videos'),
(194, 'open_appdata_folder', 'explorer.exe %appdata%'),
(195, 'open_temp_folder', 'explorer.exe %temp%'),
(196, 'open_startup_folder', 'explorer.exe shell:startup'),
(197, 'open_program_files_folder', 'explorer.exe "%ProgramFiles%"'),
(198, 'open_windows_folder', 'explorer.exe %windir%'),
(199, 'open_system32_folder', 'explorer.exe %windir%\System32'),
(200, 'open_user_profile_folder', 'explorer.exe %userprofile%'),
(201, 'open_public_folder', 'explorer.exe C:\Users\Public'),
(202, 'open_recent_folder', 'explorer.exe shell:recent'),
(203, 'open_screenshots_folder', 'explorer.exe %userprofile%\Pictures\Screenshots'),
(204, 'open_onedrive_folder', 'explorer.exe %userprofile%\OneDrive'),
(205, 'open_trash_folder', 'explorer.exe shell:RecycleBinFolder'),
(206, 'show_computer_name', 'hostname'),
(207, 'show_current_user', 'whoami'),
(208, 'show_windows_version', 'ver'),
(209, 'show_current_date', 'date /t'),
(210, 'show_current_time', 'time /t'),
(211, 'show_running_processes', 'tasklist'),
(212, 'show_processor_name', 'powershell -c "(Get-CimInstance Win32_Processor).Name"'),
(213, 'show_total_ram', 'powershell -c "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1).ToString() + '' GB''"'),
(214, 'show_disk_space', 'powershell -c "Get-PSDrive -PSProvider FileSystem | Format-Table Name,Used,Free -AutoSize | Out-String"'),
(215, 'show_graphics_card', 'powershell -c "(Get-CimInstance Win32_VideoController).Name"'),
(216, 'show_battery_level', 'powershell -c "(Get-CimInstance Win32_Battery).EstimatedChargeRemaining.ToString() + ''%''"'),
(217, 'show_system_uptime', 'powershell -c "((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).ToString()"'),
(218, 'show_mac_address', 'getmac'),
(219, 'show_public_ip', 'powershell -c "(Invoke-RestMethod https://api.ipify.org)"'),
(220, 'show_dns_servers', 'powershell -c "Get-DnsClientServerAddress -AddressFamily IPv4 | Select InterfaceAlias,ServerAddresses | Out-String"'),
(221, 'show_arp_table', 'arp -a'),
(222, 'show_routing_table', 'route print'),
(223, 'show_nslookup', 'nslookup google.com'),
(224, 'show_installed_programs', 'powershell -c "Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName | Select-Object -ExpandProperty DisplayName | Sort-Object | Out-String"'),
(225, 'show_startup_programs', 'powershell -c "Get-CimInstance Win32_StartupCommand | Select Name,Command | Out-String"'),
(226, 'show_wifi_status', 'netsh wlan show interfaces'),
(227, 'show_firewall_status', 'netsh advfirewall show allprofiles state'),
(228, 'show_local_users', 'net user'),
(229, 'show_antivirus_status', 'powershell -c "Get-MpComputerStatus | Select AntivirusEnabled,RealTimeProtectionEnabled | Out-String"'),
(230, 'show_screen_resolution', 'powershell -c "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Size.ToString()"'),
(231, 'hibernate_pc', 'shutdown /h'),
(232, 'sign_out', 'shutdown /l'),
(233, 'minimize_all_windows', 'powershell -c "(New-Object -ComObject Shell.Application).MinimizeAll()"'),
(234, 'restore_all_windows', 'powershell -c "(New-Object -ComObject Shell.Application).UndoMinimizeAll()"'),
(235, 'max_volume', 'powershell -c "$w=New-Object -ComObject WScript.Shell;1..50|ForEach-Object{$w.SendKeys([char]175)}"'),
(236, 'min_volume', 'powershell -c "$w=New-Object -ComObject WScript.Shell;1..50|ForEach-Object{$w.SendKeys([char]174)}"'),
(237, 'half_volume', 'powershell -c "$w=New-Object -ComObject WScript.Shell;1..50|ForEach-Object{$w.SendKeys([char]174)};1..25|ForEach-Object{$w.SendKeys([char]175)}"'),
(238, 'stop_music', 'powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]178)"'),
(239, 'restart_explorer', 'taskkill /f /im explorer.exe & start explorer.exe'),
(240, 'clear_clipboard', 'cmd /c "echo off | clip"'),
(241, 'close_chrome', 'taskkill /im chrome.exe /f'),
(242, 'close_edge', 'taskkill /im msedge.exe /f'),
(243, 'close_firefox', 'taskkill /im firefox.exe /f'),
(244, 'close_notepad', 'taskkill /im notepad.exe /f'),
(245, 'close_vscode', 'taskkill /im Code.exe /f'),
(246, 'close_spotify', 'taskkill /im Spotify.exe /f'),
(247, 'close_discord', 'taskkill /im Discord.exe /f'),
(248, 'ping_cloudflare', 'ping 1.1.1.1'),
(249, 'ping_8_8_8_8', 'ping 8.8.8.8'),
(250, 'release_ip_address', 'ipconfig /release');

INSERT OR IGNORE INTO cmd_prompt (cmd_id, naw_query) VALUES
-- 51. open_instagram
(51, 'open instagram'), (51, 'go to instagram'), (51, 'visit instagram'), (51, 'browse instagram'), (51, 'launch instagram'), (51, 'take me to instagram'), (51, 'load instagram'), (51, 'instagram website'),
(51, 'افتح انستقرام'), (51, 'موقع انستقرام'), (51, 'اذهب الى instagram'), (51, 'زيارة instagram'), (51, 'شغل انستقرام'), (51, 'ادخل على instagram'), (51, 'اريد instagram'),
(51, 'ouvrir instagram'), (51, 'aller sur instagram'), (51, 'visiter instagram'), (51, 'lancer instagram'), (51, 'afficher instagram'), (51, 'site instagram'),

-- 52. open_twitter
(52, 'open twitter'), (52, 'go to twitter'), (52, 'visit twitter'), (52, 'browse twitter'), (52, 'launch twitter'), (52, 'take me to twitter'), (52, 'load twitter'), (52, 'twitter website'),
(52, 'افتح تويتر'), (52, 'موقع تويتر'), (52, 'اذهب الى twitter'), (52, 'زيارة twitter'), (52, 'شغل تويتر'), (52, 'ادخل على twitter'), (52, 'اريد twitter'),
(52, 'ouvrir twitter'), (52, 'aller sur twitter'), (52, 'visiter twitter'), (52, 'lancer twitter'), (52, 'afficher twitter'), (52, 'site twitter'),

-- 53. open_linkedin
(53, 'open linkedin'), (53, 'go to linkedin'), (53, 'visit linkedin'), (53, 'browse linkedin'), (53, 'launch linkedin'), (53, 'take me to linkedin'), (53, 'load linkedin'), (53, 'linkedin website'),
(53, 'افتح لينكدان'), (53, 'موقع لينكدان'), (53, 'اذهب الى linkedin'), (53, 'زيارة linkedin'), (53, 'شغل لينكدان'), (53, 'ادخل على linkedin'), (53, 'اريد linkedin'),
(53, 'ouvrir linkedin'), (53, 'aller sur linkedin'), (53, 'visiter linkedin'), (53, 'lancer linkedin'), (53, 'afficher linkedin'), (53, 'site linkedin'),

-- 54. open_reddit
(54, 'open reddit'), (54, 'go to reddit'), (54, 'visit reddit'), (54, 'browse reddit'), (54, 'launch reddit'), (54, 'take me to reddit'), (54, 'load reddit'), (54, 'reddit website'),
(54, 'افتح ريديت'), (54, 'موقع ريديت'), (54, 'اذهب الى reddit'), (54, 'زيارة reddit'), (54, 'شغل ريديت'), (54, 'ادخل على reddit'), (54, 'اريد reddit'),
(54, 'ouvrir reddit'), (54, 'aller sur reddit'), (54, 'visiter reddit'), (54, 'lancer reddit'), (54, 'afficher reddit'), (54, 'site reddit'),

-- 55. open_netflix
(55, 'open netflix'), (55, 'go to netflix'), (55, 'visit netflix'), (55, 'browse netflix'), (55, 'launch netflix'), (55, 'take me to netflix'), (55, 'load netflix'), (55, 'netflix website'),
(55, 'افتح نتفلكس'), (55, 'موقع نتفلكس'), (55, 'اذهب الى netflix'), (55, 'زيارة netflix'), (55, 'شغل نتفلكس'), (55, 'ادخل على netflix'), (55, 'اريد netflix'),
(55, 'ouvrir netflix'), (55, 'aller sur netflix'), (55, 'visiter netflix'), (55, 'lancer netflix'), (55, 'afficher netflix'), (55, 'site netflix'),

-- 56. open_amazon
(56, 'open amazon'), (56, 'go to amazon'), (56, 'visit amazon'), (56, 'browse amazon'), (56, 'launch amazon'), (56, 'take me to amazon'), (56, 'load amazon'), (56, 'amazon website'),
(56, 'افتح امازون'), (56, 'موقع امازون'), (56, 'اذهب الى amazon'), (56, 'زيارة amazon'), (56, 'شغل امازون'), (56, 'ادخل على amazon'), (56, 'اريد amazon'),
(56, 'ouvrir amazon'), (56, 'aller sur amazon'), (56, 'visiter amazon'), (56, 'lancer amazon'), (56, 'afficher amazon'), (56, 'site amazon'),

-- 57. open_wikipedia
(57, 'open wikipedia'), (57, 'go to wikipedia'), (57, 'visit wikipedia'), (57, 'browse wikipedia'), (57, 'launch wikipedia'), (57, 'take me to wikipedia'), (57, 'load wikipedia'), (57, 'wikipedia website'),
(57, 'افتح ويكيبيديا'), (57, 'موقع ويكيبيديا'), (57, 'اذهب الى wikipedia'), (57, 'زيارة wikipedia'), (57, 'شغل ويكيبيديا'), (57, 'ادخل على wikipedia'), (57, 'اريد wikipedia'),
(57, 'ouvrir wikipedia'), (57, 'aller sur wikipedia'), (57, 'visiter wikipedia'), (57, 'lancer wikipedia'), (57, 'afficher wikipedia'), (57, 'site wikipedia'),

-- 58. open_google_maps
(58, 'open google maps'), (58, 'go to google maps'), (58, 'visit google maps'), (58, 'browse google maps'), (58, 'launch google maps'), (58, 'take me to maps online'), (58, 'load maps online'), (58, 'maps online website'),
(58, 'افتح خرائط جوجل'), (58, 'موقع خرائط جوجل'), (58, 'اذهب الى google maps'), (58, 'زيارة google maps'), (58, 'شغل خرائط جوجل'), (58, 'ادخل على google maps'), (58, 'اريد google maps'),
(58, 'ouvrir google maps'), (58, 'aller sur google maps'), (58, 'visiter google maps'), (58, 'lancer google maps'), (58, 'afficher la carte google'), (58, 'site la carte google'),

-- 59. open_google_drive
(59, 'open google drive'), (59, 'go to google drive'), (59, 'visit google drive'), (59, 'browse google drive'), (59, 'launch google drive'), (59, 'take me to my cloud drive'), (59, 'load my cloud drive'), (59, 'my cloud drive website'),
(59, 'افتح جوجل درايف'), (59, 'موقع جوجل درايف'), (59, 'اذهب الى google drive'), (59, 'زيارة google drive'), (59, 'شغل جوجل درايف'), (59, 'ادخل على google drive'), (59, 'اريد google drive'),
(59, 'ouvrir google drive'), (59, 'aller sur google drive'), (59, 'visiter google drive'), (59, 'lancer google drive'), (59, 'afficher mon drive google'), (59, 'site mon drive google'),

-- 60. open_google_translate
(60, 'open google translate'), (60, 'go to google translate'), (60, 'visit google translate'), (60, 'browse google translate'), (60, 'launch google translate'), (60, 'take me to online translator'), (60, 'load online translator'), (60, 'online translator website'),
(60, 'افتح ترجمة جوجل'), (60, 'موقع ترجمة جوجل'), (60, 'اذهب الى google translate'), (60, 'زيارة google translate'), (60, 'شغل ترجمة جوجل'), (60, 'ادخل على google translate'), (60, 'اريد google translate'),
(60, 'ouvrir google traduction'), (60, 'aller sur google traduction'), (60, 'visiter google traduction'), (60, 'lancer google traduction'), (60, 'afficher le traducteur en ligne'), (60, 'site le traducteur en ligne'),

-- 61. open_google_calendar
(61, 'open google calendar'), (61, 'go to google calendar'), (61, 'visit google calendar'), (61, 'browse google calendar'), (61, 'launch google calendar'), (61, 'take me to online calendar'), (61, 'load online calendar'), (61, 'online calendar website'),
(61, 'افتح تقويم جوجل'), (61, 'موقع تقويم جوجل'), (61, 'اذهب الى google calendar'), (61, 'زيارة google calendar'), (61, 'شغل تقويم جوجل'), (61, 'ادخل على google calendar'), (61, 'اريد google calendar'),
(61, 'ouvrir google agenda'), (61, 'aller sur google agenda'), (61, 'visiter google agenda'), (61, 'lancer google agenda'), (61, 'afficher l agenda en ligne'), (61, 'site l agenda en ligne'),

-- 62. open_google_docs
(62, 'open google docs'), (62, 'go to google docs'), (62, 'visit google docs'), (62, 'browse google docs'), (62, 'launch google docs'), (62, 'take me to online documents'), (62, 'load online documents'), (62, 'online documents website'),
(62, 'افتح مستندات جوجل'), (62, 'موقع مستندات جوجل'), (62, 'اذهب الى google docs'), (62, 'زيارة google docs'), (62, 'شغل مستندات جوجل'), (62, 'ادخل على google docs'), (62, 'اريد google docs'),
(62, 'ouvrir google docs'), (62, 'aller sur google docs'), (62, 'visiter google docs'), (62, 'lancer google docs'), (62, 'afficher les documents en ligne'), (62, 'site les documents en ligne'),

-- 63. open_google_news
(63, 'open google news'), (63, 'go to google news'), (63, 'visit google news'), (63, 'browse google news'), (63, 'launch google news'), (63, 'take me to latest news'), (63, 'load latest news'), (63, 'latest news website'),
(63, 'افتح اخبار جوجل'), (63, 'موقع اخبار جوجل'), (63, 'اذهب الى google news'), (63, 'زيارة google news'), (63, 'شغل اخبار جوجل'), (63, 'ادخل على google news'), (63, 'اريد google news'),
(63, 'ouvrir google actualites'), (63, 'aller sur google actualites'), (63, 'visiter google actualites'), (63, 'lancer google actualites'), (63, 'afficher les dernieres actualites'), (63, 'site les dernieres actualites'),

-- 64. open_bing
(64, 'open bing'), (64, 'go to bing'), (64, 'visit bing'), (64, 'browse bing'), (64, 'launch bing'), (64, 'take me to bing search'), (64, 'load bing search'), (64, 'bing search website'),
(64, 'افتح محرك بحث بينج'), (64, 'موقع محرك بحث بينج'), (64, 'اذهب الى bing'), (64, 'زيارة bing'), (64, 'شغل محرك بحث بينج'), (64, 'ادخل على bing'), (64, 'اريد bing'),
(64, 'ouvrir bing'), (64, 'aller sur bing'), (64, 'visiter bing'), (64, 'lancer bing'), (64, 'afficher le moteur bing'), (64, 'site le moteur bing'),

-- 65. open_duckduckgo
(65, 'open duckduckgo'), (65, 'go to duckduckgo'), (65, 'visit duckduckgo'), (65, 'browse duckduckgo'), (65, 'launch duckduckgo'), (65, 'take me to duck duck go'), (65, 'load duck duck go'), (65, 'duck duck go website'),
(65, 'افتح دك دك جو'), (65, 'موقع دك دك جو'), (65, 'اذهب الى duckduckgo'), (65, 'زيارة duckduckgo'), (65, 'شغل دك دك جو'), (65, 'ادخل على duckduckgo'), (65, 'اريد duckduckgo'),
(65, 'ouvrir duckduckgo'), (65, 'aller sur duckduckgo'), (65, 'visiter duckduckgo'), (65, 'lancer duckduckgo'), (65, 'afficher duck duck go'), (65, 'site duck duck go'),

-- 66. open_yahoo
(66, 'open yahoo'), (66, 'go to yahoo'), (66, 'visit yahoo'), (66, 'browse yahoo'), (66, 'launch yahoo'), (66, 'take me to yahoo mail'), (66, 'load yahoo mail'), (66, 'yahoo mail website'),
(66, 'افتح ياهو'), (66, 'موقع ياهو'), (66, 'اذهب الى yahoo'), (66, 'زيارة yahoo'), (66, 'شغل ياهو'), (66, 'ادخل على yahoo'), (66, 'اريد yahoo'),
(66, 'ouvrir yahoo'), (66, 'aller sur yahoo'), (66, 'visiter yahoo'), (66, 'lancer yahoo'), (66, 'afficher yahoo mail'), (66, 'site yahoo mail'),

-- 67. open_outlook_web
(67, 'open outlook web'), (67, 'go to outlook web'), (67, 'visit outlook web'), (67, 'browse outlook web'), (67, 'launch outlook web'), (67, 'take me to outlook online'), (67, 'load outlook online'), (67, 'outlook online website'),
(67, 'افتح اوتلوك ويب'), (67, 'موقع اوتلوك ويب'), (67, 'اذهب الى outlook web'), (67, 'زيارة outlook web'), (67, 'شغل اوتلوك ويب'), (67, 'ادخل على outlook web'), (67, 'اريد outlook web'),
(67, 'ouvrir outlook web'), (67, 'aller sur outlook web'), (67, 'visiter outlook web'), (67, 'lancer outlook web'), (67, 'afficher outlook en ligne'), (67, 'site outlook en ligne'),

-- 68. open_twitch
(68, 'open twitch'), (68, 'go to twitch'), (68, 'visit twitch'), (68, 'browse twitch'), (68, 'launch twitch'), (68, 'take me to twitch streams'), (68, 'load twitch streams'), (68, 'twitch streams website'),
(68, 'افتح تويتش'), (68, 'موقع تويتش'), (68, 'اذهب الى twitch'), (68, 'زيارة twitch'), (68, 'شغل تويتش'), (68, 'ادخل على twitch'), (68, 'اريد twitch'),
(68, 'ouvrir twitch'), (68, 'aller sur twitch'), (68, 'visiter twitch'), (68, 'lancer twitch'), (68, 'afficher twitch live'), (68, 'site twitch live'),

-- 69. open_soundcloud
(69, 'open soundcloud'), (69, 'go to soundcloud'), (69, 'visit soundcloud'), (69, 'browse soundcloud'), (69, 'launch soundcloud'), (69, 'take me to sound cloud'), (69, 'load sound cloud'), (69, 'sound cloud website'),
(69, 'افتح ساوند كلاود'), (69, 'موقع ساوند كلاود'), (69, 'اذهب الى soundcloud'), (69, 'زيارة soundcloud'), (69, 'شغل ساوند كلاود'), (69, 'ادخل على soundcloud'), (69, 'اريد soundcloud'),
(69, 'ouvrir soundcloud'), (69, 'aller sur soundcloud'), (69, 'visiter soundcloud'), (69, 'lancer soundcloud'), (69, 'afficher sound cloud'), (69, 'site sound cloud'),

-- 70. open_pinterest
(70, 'open pinterest'), (70, 'go to pinterest'), (70, 'visit pinterest'), (70, 'browse pinterest'), (70, 'launch pinterest'), (70, 'take me to pinterest pins'), (70, 'load pinterest pins'), (70, 'pinterest pins website'),
(70, 'افتح بنترست'), (70, 'موقع بنترست'), (70, 'اذهب الى pinterest'), (70, 'زيارة pinterest'), (70, 'شغل بنترست'), (70, 'ادخل على pinterest'), (70, 'اريد pinterest'),
(70, 'ouvrir pinterest'), (70, 'aller sur pinterest'), (70, 'visiter pinterest'), (70, 'lancer pinterest'), (70, 'afficher pinterest epingles'), (70, 'site pinterest epingles'),

-- 71. open_tiktok
(71, 'open tiktok'), (71, 'go to tiktok'), (71, 'visit tiktok'), (71, 'browse tiktok'), (71, 'launch tiktok'), (71, 'take me to tik tok'), (71, 'load tik tok'), (71, 'tik tok website'),
(71, 'افتح تيك توك'), (71, 'موقع تيك توك'), (71, 'اذهب الى tiktok'), (71, 'زيارة tiktok'), (71, 'شغل تيك توك'), (71, 'ادخل على tiktok'), (71, 'اريد tiktok'),
(71, 'ouvrir tiktok'), (71, 'aller sur tiktok'), (71, 'visiter tiktok'), (71, 'lancer tiktok'), (71, 'afficher tik tok'), (71, 'site tik tok'),

-- 72. open_telegram_web
(72, 'open telegram web'), (72, 'go to telegram web'), (72, 'visit telegram web'), (72, 'browse telegram web'), (72, 'launch telegram web'), (72, 'take me to telegram online'), (72, 'load telegram online'), (72, 'telegram online website'),
(72, 'افتح تليجرام ويب'), (72, 'موقع تليجرام ويب'), (72, 'اذهب الى telegram web'), (72, 'زيارة telegram web'), (72, 'شغل تليجرام ويب'), (72, 'ادخل على telegram web'), (72, 'اريد telegram web'),
(72, 'ouvrir telegram web'), (72, 'aller sur telegram web'), (72, 'visiter telegram web'), (72, 'lancer telegram web'), (72, 'afficher telegram en ligne'), (72, 'site telegram en ligne'),

-- 73. open_discord
(73, 'open discord'), (73, 'go to discord'), (73, 'visit discord'), (73, 'browse discord'), (73, 'launch discord'), (73, 'take me to discord chat'), (73, 'load discord chat'), (73, 'discord chat website'),
(73, 'افتح ديسكورد'), (73, 'موقع ديسكورد'), (73, 'اذهب الى discord'), (73, 'زيارة discord'), (73, 'شغل ديسكورد'), (73, 'ادخل على discord'), (73, 'اريد discord'),
(73, 'ouvrir discord'), (73, 'aller sur discord'), (73, 'visiter discord'), (73, 'lancer discord'), (73, 'afficher discord chat'), (73, 'site discord chat'),

-- 74. open_google_meet
(74, 'open google meet'), (74, 'go to google meet'), (74, 'visit google meet'), (74, 'browse google meet'), (74, 'launch google meet'), (74, 'take me to video meeting'), (74, 'load video meeting'), (74, 'video meeting website'),
(74, 'افتح جوجل ميت'), (74, 'موقع جوجل ميت'), (74, 'اذهب الى google meet'), (74, 'زيارة google meet'), (74, 'شغل جوجل ميت'), (74, 'ادخل على google meet'), (74, 'اريد google meet'),
(74, 'ouvrir google meet'), (74, 'aller sur google meet'), (74, 'visiter google meet'), (74, 'lancer google meet'), (74, 'afficher reunion video'), (74, 'site reunion video'),

-- 75. open_canva
(75, 'open canva'), (75, 'go to canva'), (75, 'visit canva'), (75, 'browse canva'), (75, 'launch canva'), (75, 'take me to canva design'), (75, 'load canva design'), (75, 'canva design website'),
(75, 'افتح كانفا'), (75, 'موقع كانفا'), (75, 'اذهب الى canva'), (75, 'زيارة canva'), (75, 'شغل كانفا'), (75, 'ادخل على canva'), (75, 'اريد canva'),
(75, 'ouvrir canva'), (75, 'aller sur canva'), (75, 'visiter canva'), (75, 'lancer canva'), (75, 'afficher canva design'), (75, 'site canva design'),

-- 76. open_figma
(76, 'open figma'), (76, 'go to figma'), (76, 'visit figma'), (76, 'browse figma'), (76, 'launch figma'), (76, 'take me to figma design'), (76, 'load figma design'), (76, 'figma design website'),
(76, 'افتح فيجما'), (76, 'موقع فيجما'), (76, 'اذهب الى figma'), (76, 'زيارة figma'), (76, 'شغل فيجما'), (76, 'ادخل على figma'), (76, 'اريد figma'),
(76, 'ouvrir figma'), (76, 'aller sur figma'), (76, 'visiter figma'), (76, 'lancer figma'), (76, 'afficher figma design'), (76, 'site figma design'),

-- 77. open_notion
(77, 'open notion'), (77, 'go to notion'), (77, 'visit notion'), (77, 'browse notion'), (77, 'launch notion'), (77, 'take me to notion notes'), (77, 'load notion notes'), (77, 'notion notes website'),
(77, 'افتح نوشن'), (77, 'موقع نوشن'), (77, 'اذهب الى notion'), (77, 'زيارة notion'), (77, 'شغل نوشن'), (77, 'ادخل على notion'), (77, 'اريد notion'),
(77, 'ouvrir notion'), (77, 'aller sur notion'), (77, 'visiter notion'), (77, 'lancer notion'), (77, 'afficher notion notes'), (77, 'site notion notes'),

-- 78. open_trello
(78, 'open trello'), (78, 'go to trello'), (78, 'visit trello'), (78, 'browse trello'), (78, 'launch trello'), (78, 'take me to trello boards'), (78, 'load trello boards'), (78, 'trello boards website'),
(78, 'افتح تريلو'), (78, 'موقع تريلو'), (78, 'اذهب الى trello'), (78, 'زيارة trello'), (78, 'شغل تريلو'), (78, 'ادخل على trello'), (78, 'اريد trello'),
(78, 'ouvrir trello'), (78, 'aller sur trello'), (78, 'visiter trello'), (78, 'lancer trello'), (78, 'afficher tableaux trello'), (78, 'site tableaux trello'),

-- 79. open_dropbox
(79, 'open dropbox'), (79, 'go to dropbox'), (79, 'visit dropbox'), (79, 'browse dropbox'), (79, 'launch dropbox'), (79, 'take me to drop box'), (79, 'load drop box'), (79, 'drop box website'),
(79, 'افتح دروب بوكس'), (79, 'موقع دروب بوكس'), (79, 'اذهب الى dropbox'), (79, 'زيارة dropbox'), (79, 'شغل دروب بوكس'), (79, 'ادخل على dropbox'), (79, 'اريد dropbox'),
(79, 'ouvrir dropbox'), (79, 'aller sur dropbox'), (79, 'visiter dropbox'), (79, 'lancer dropbox'), (79, 'afficher drop box'), (79, 'site drop box'),

-- 80. open_ebay
(80, 'open ebay'), (80, 'go to ebay'), (80, 'visit ebay'), (80, 'browse ebay'), (80, 'launch ebay'), (80, 'take me to e bay'), (80, 'load e bay'), (80, 'e bay website'),
(80, 'افتح ايباي'), (80, 'موقع ايباي'), (80, 'اذهب الى ebay'), (80, 'زيارة ebay'), (80, 'شغل ايباي'), (80, 'ادخل على ebay'), (80, 'اريد ebay'),
(80, 'ouvrir ebay'), (80, 'aller sur ebay'), (80, 'visiter ebay'), (80, 'lancer ebay'), (80, 'afficher e bay'), (80, 'site e bay'),

-- 81. open_aliexpress
(81, 'open aliexpress'), (81, 'go to aliexpress'), (81, 'visit aliexpress'), (81, 'browse aliexpress'), (81, 'launch aliexpress'), (81, 'take me to ali express'), (81, 'load ali express'), (81, 'ali express website'),
(81, 'افتح علي اكسبريس'), (81, 'موقع علي اكسبريس'), (81, 'اذهب الى aliexpress'), (81, 'زيارة aliexpress'), (81, 'شغل علي اكسبريس'), (81, 'ادخل على aliexpress'), (81, 'اريد aliexpress'),
(81, 'ouvrir aliexpress'), (81, 'aller sur aliexpress'), (81, 'visiter aliexpress'), (81, 'lancer aliexpress'), (81, 'afficher ali express'), (81, 'site ali express'),

-- 82. open_paypal
(82, 'open paypal'), (82, 'go to paypal'), (82, 'visit paypal'), (82, 'browse paypal'), (82, 'launch paypal'), (82, 'take me to pay pal'), (82, 'load pay pal'), (82, 'pay pal website'),
(82, 'افتح بايبال'), (82, 'موقع بايبال'), (82, 'اذهب الى paypal'), (82, 'زيارة paypal'), (82, 'شغل بايبال'), (82, 'ادخل على paypal'), (82, 'اريد paypal'),
(82, 'ouvrir paypal'), (82, 'aller sur paypal'), (82, 'visiter paypal'), (82, 'lancer paypal'), (82, 'afficher pay pal'), (82, 'site pay pal'),

-- 83. open_booking
(83, 'open booking'), (83, 'go to booking'), (83, 'visit booking'), (83, 'browse booking'), (83, 'launch booking'), (83, 'take me to booking hotels'), (83, 'load booking hotels'), (83, 'booking hotels website'),
(83, 'افتح بوكينج'), (83, 'موقع بوكينج'), (83, 'اذهب الى booking'), (83, 'زيارة booking'), (83, 'شغل بوكينج'), (83, 'ادخل على booking'), (83, 'اريد booking'),
(83, 'ouvrir booking'), (83, 'aller sur booking'), (83, 'visiter booking'), (83, 'lancer booking'), (83, 'afficher reservation hotels'), (83, 'site reservation hotels'),

-- 84. open_imdb
(84, 'open imdb'), (84, 'go to imdb'), (84, 'visit imdb'), (84, 'browse imdb'), (84, 'launch imdb'), (84, 'take me to movie database'), (84, 'load movie database'), (84, 'movie database website'),
(84, 'افتح اي ام دي بي'), (84, 'موقع اي ام دي بي'), (84, 'اذهب الى imdb'), (84, 'زيارة imdb'), (84, 'شغل اي ام دي بي'), (84, 'ادخل على imdb'), (84, 'اريد imdb'),
(84, 'ouvrir imdb'), (84, 'aller sur imdb'), (84, 'visiter imdb'), (84, 'lancer imdb'), (84, 'afficher base de donnees de films'), (84, 'site base de donnees de films'),

-- 85. open_weather
(85, 'open weather'), (85, 'go to weather'), (85, 'visit weather'), (85, 'browse weather'), (85, 'launch weather'), (85, 'take me to weather forecast'), (85, 'load weather forecast'), (85, 'weather forecast website'),
(85, 'افتح الطقس'), (85, 'موقع الطقس'), (85, 'اذهب الى توقعات الطقس'), (85, 'زيارة توقعات الطقس'), (85, 'شغل الطقس'), (85, 'ادخل على توقعات الطقس'), (85, 'اريد توقعات الطقس'),
(85, 'ouvrir la meteo'), (85, 'aller sur la meteo'), (85, 'visiter la meteo'), (85, 'lancer la meteo'), (85, 'afficher les previsions meteo'), (85, 'site les previsions meteo'),

-- 86. open_w3schools
(86, 'open w3schools'), (86, 'go to w3schools'), (86, 'visit w3schools'), (86, 'browse w3schools'), (86, 'launch w3schools'), (86, 'take me to w3 schools'), (86, 'load w3 schools'), (86, 'w3 schools website'),
(86, 'افتح دبليو ثري سكولز'), (86, 'موقع دبليو ثري سكولز'), (86, 'اذهب الى w3schools'), (86, 'زيارة w3schools'), (86, 'شغل دبليو ثري سكولز'), (86, 'ادخل على w3schools'), (86, 'اريد w3schools'),
(86, 'ouvrir w3schools'), (86, 'aller sur w3schools'), (86, 'visiter w3schools'), (86, 'lancer w3schools'), (86, 'afficher w3 schools'), (86, 'site w3 schools'),

-- 87. open_pypi
(87, 'open pypi'), (87, 'go to pypi'), (87, 'visit pypi'), (87, 'browse pypi'), (87, 'launch pypi'), (87, 'take me to python packages'), (87, 'load python packages'), (87, 'python packages website'),
(87, 'افتح باي باي اي'), (87, 'موقع باي باي اي'), (87, 'اذهب الى pypi'), (87, 'زيارة pypi'), (87, 'شغل باي باي اي'), (87, 'ادخل على pypi'), (87, 'اريد pypi'),
(87, 'ouvrir pypi'), (87, 'aller sur pypi'), (87, 'visiter pypi'), (87, 'lancer pypi'), (87, 'afficher paquets python'), (87, 'site paquets python'),

-- 88. open_huggingface
(88, 'open huggingface'), (88, 'go to huggingface'), (88, 'visit huggingface'), (88, 'browse huggingface'), (88, 'launch huggingface'), (88, 'take me to hugging face'), (88, 'load hugging face'), (88, 'hugging face website'),
(88, 'افتح هاجينج فيس'), (88, 'موقع هاجينج فيس'), (88, 'اذهب الى huggingface'), (88, 'زيارة huggingface'), (88, 'شغل هاجينج فيس'), (88, 'ادخل على huggingface'), (88, 'اريد huggingface'),
(88, 'ouvrir huggingface'), (88, 'aller sur huggingface'), (88, 'visiter huggingface'), (88, 'lancer huggingface'), (88, 'afficher hugging face'), (88, 'site hugging face'),

-- 89. open_kaggle
(89, 'open kaggle'), (89, 'go to kaggle'), (89, 'visit kaggle'), (89, 'browse kaggle'), (89, 'launch kaggle'), (89, 'take me to kaggle data'), (89, 'load kaggle data'), (89, 'kaggle data website'),
(89, 'افتح كاجل'), (89, 'موقع كاجل'), (89, 'اذهب الى kaggle'), (89, 'زيارة kaggle'), (89, 'شغل كاجل'), (89, 'ادخل على kaggle'), (89, 'اريد kaggle'),
(89, 'ouvrir kaggle'), (89, 'aller sur kaggle'), (89, 'visiter kaggle'), (89, 'lancer kaggle'), (89, 'afficher kaggle data'), (89, 'site kaggle data'),

-- 90. open_udemy
(90, 'open udemy'), (90, 'go to udemy'), (90, 'visit udemy'), (90, 'browse udemy'), (90, 'launch udemy'), (90, 'take me to udemy courses'), (90, 'load udemy courses'), (90, 'udemy courses website'),
(90, 'افتح يوديمي'), (90, 'موقع يوديمي'), (90, 'اذهب الى udemy'), (90, 'زيارة udemy'), (90, 'شغل يوديمي'), (90, 'ادخل على udemy'), (90, 'اريد udemy'),
(90, 'ouvrir udemy'), (90, 'aller sur udemy'), (90, 'visiter udemy'), (90, 'lancer udemy'), (90, 'afficher cours udemy'), (90, 'site cours udemy'),

-- 91. open_windows_terminal
(91, 'open windows terminal'), (91, 'launch windows terminal'), (91, 'start windows terminal'), (91, 'run windows terminal'), (91, 'show terminal app'), (91, 'bring up terminal app'), (91, 'load terminal app'), (91, 'i need terminal app'),
(91, 'افتح ويندوز تيرمنال'), (91, 'شغل ويندوز تيرمنال'), (91, 'تشغيل ويندوز تيرمنال'), (91, 'فتح ويندوز تيرمنال'), (91, 'اظهر الطرفية'), (91, 'ابدا الطرفية'), (91, 'اريد الطرفية'),
(91, 'ouvrir windows terminal'), (91, 'lancer windows terminal'), (91, 'demarrer windows terminal'), (91, 'afficher le terminal windows'), (91, 'montre le terminal windows'), (91, 'ouvre le terminal windows'),

-- 92. open_registry_editor
(92, 'open registry editor'), (92, 'launch registry editor'), (92, 'start registry editor'), (92, 'run registry editor'), (92, 'show regedit'), (92, 'bring up regedit'), (92, 'load regedit'), (92, 'i need regedit'),
(92, 'افتح محرر السجل'), (92, 'شغل محرر السجل'), (92, 'تشغيل محرر السجل'), (92, 'فتح محرر السجل'), (92, 'اظهر ريجيستري'), (92, 'ابدا ريجيستري'), (92, 'اريد ريجيستري'),
(92, 'ouvrir l editeur du registre'), (92, 'lancer l editeur du registre'), (92, 'demarrer l editeur du registre'), (92, 'afficher regedit'), (92, 'montre regedit'), (92, 'ouvre regedit'),

-- 93. open_system_configuration_tool
(93, 'open system configuration tool'), (93, 'launch system configuration tool'), (93, 'start system configuration tool'), (93, 'run system configuration tool'), (93, 'show msconfig'), (93, 'bring up msconfig'), (93, 'load msconfig'), (93, 'i need msconfig'),
(93, 'افتح اداة تهيئة النظام'), (93, 'شغل اداة تهيئة النظام'), (93, 'تشغيل اداة تهيئة النظام'), (93, 'فتح اداة تهيئة النظام'), (93, 'اظهر msconfig'), (93, 'ابدا msconfig'), (93, 'اريد msconfig'),
(93, 'ouvrir l outil de configuration du systeme'), (93, 'lancer l outil de configuration du systeme'), (93, 'demarrer l outil de configuration du systeme'), (93, 'afficher msconfig'), (93, 'montre msconfig'), (93, 'ouvre msconfig'),

-- 94. open_resource_monitor
(94, 'open resource monitor'), (94, 'launch resource monitor'), (94, 'start resource monitor'), (94, 'run resource monitor'), (94, 'show resmon'), (94, 'bring up resmon'), (94, 'load resmon'), (94, 'i need resmon'),
(94, 'افتح مراقب الموارد'), (94, 'شغل مراقب الموارد'), (94, 'تشغيل مراقب الموارد'), (94, 'فتح مراقب الموارد'), (94, 'اظهر resmon'), (94, 'ابدا resmon'), (94, 'اريد resmon'),
(94, 'ouvrir le moniteur de ressources'), (94, 'lancer le moniteur de ressources'), (94, 'demarrer le moniteur de ressources'), (94, 'afficher resmon'), (94, 'montre resmon'), (94, 'ouvre resmon'),

-- 95. open_performance_monitor
(95, 'open performance monitor'), (95, 'launch performance monitor'), (95, 'start performance monitor'), (95, 'run performance monitor'), (95, 'show perfmon'), (95, 'bring up perfmon'), (95, 'load perfmon'), (95, 'i need perfmon'),
(95, 'افتح مراقب الاداء'), (95, 'شغل مراقب الاداء'), (95, 'تشغيل مراقب الاداء'), (95, 'فتح مراقب الاداء'), (95, 'اظهر perfmon'), (95, 'ابدا perfmon'), (95, 'اريد perfmon'),
(95, 'ouvrir le moniteur de performances'), (95, 'lancer le moniteur de performances'), (95, 'demarrer le moniteur de performances'), (95, 'afficher perfmon'), (95, 'montre perfmon'), (95, 'ouvre perfmon'),

-- 96. open_event_viewer
(96, 'open event viewer'), (96, 'launch event viewer'), (96, 'start event viewer'), (96, 'run event viewer'), (96, 'show system logs'), (96, 'bring up system logs'), (96, 'load system logs'), (96, 'i need system logs'),
(96, 'افتح عارض الاحداث'), (96, 'شغل عارض الاحداث'), (96, 'تشغيل عارض الاحداث'), (96, 'فتح عارض الاحداث'), (96, 'اظهر سجلات النظام'), (96, 'ابدا سجلات النظام'), (96, 'اريد سجلات النظام'),
(96, 'ouvrir l observateur d evenements'), (96, 'lancer l observateur d evenements'), (96, 'demarrer l observateur d evenements'), (96, 'afficher les journaux systeme'), (96, 'montre les journaux systeme'), (96, 'ouvre les journaux systeme'),

-- 97. open_computer_management
(97, 'open computer management'), (97, 'launch computer management'), (97, 'start computer management'), (97, 'run computer management'), (97, 'show compmgmt'), (97, 'bring up compmgmt'), (97, 'load compmgmt'), (97, 'i need compmgmt'),
(97, 'افتح ادارة الكمبيوتر'), (97, 'شغل ادارة الكمبيوتر'), (97, 'تشغيل ادارة الكمبيوتر'), (97, 'فتح ادارة الكمبيوتر'), (97, 'اظهر compmgmt'), (97, 'ابدا compmgmt'), (97, 'اريد compmgmt'),
(97, 'ouvrir la gestion de l ordinateur'), (97, 'lancer la gestion de l ordinateur'), (97, 'demarrer la gestion de l ordinateur'), (97, 'afficher compmgmt'), (97, 'montre compmgmt'), (97, 'ouvre compmgmt'),

-- 98. open_task_scheduler
(98, 'open task scheduler'), (98, 'launch task scheduler'), (98, 'start task scheduler'), (98, 'run task scheduler'), (98, 'show scheduled tasks'), (98, 'bring up scheduled tasks'), (98, 'load scheduled tasks'), (98, 'i need scheduled tasks'),
(98, 'افتح مجدول المهام'), (98, 'شغل مجدول المهام'), (98, 'تشغيل مجدول المهام'), (98, 'فتح مجدول المهام'), (98, 'اظهر المهام المجدولة'), (98, 'ابدا المهام المجدولة'), (98, 'اريد المهام المجدولة'),
(98, 'ouvrir le planificateur de taches'), (98, 'lancer le planificateur de taches'), (98, 'demarrer le planificateur de taches'), (98, 'afficher les taches planifiees'), (98, 'montre les taches planifiees'), (98, 'ouvre les taches planifiees'),

-- 99. open_directx_diagnostic_tool
(99, 'open directx diagnostic tool'), (99, 'launch directx diagnostic tool'), (99, 'start directx diagnostic tool'), (99, 'run directx diagnostic tool'), (99, 'show dxdiag'), (99, 'bring up dxdiag'), (99, 'load dxdiag'), (99, 'i need dxdiag'),
(99, 'افتح اداة تشخيص دايركت اكس'), (99, 'شغل اداة تشخيص دايركت اكس'), (99, 'تشغيل اداة تشخيص دايركت اكس'), (99, 'فتح اداة تشخيص دايركت اكس'), (99, 'اظهر dxdiag'), (99, 'ابدا dxdiag'), (99, 'اريد dxdiag'),
(99, 'ouvrir l outil de diagnostic directx'), (99, 'lancer l outil de diagnostic directx'), (99, 'demarrer l outil de diagnostic directx'), (99, 'afficher dxdiag'), (99, 'montre dxdiag'), (99, 'ouvre dxdiag'),

-- 100. open_about_windows_dialog
(100, 'open about windows dialog'), (100, 'launch about windows dialog'), (100, 'start about windows dialog'), (100, 'run about windows dialog'), (100, 'show winver'), (100, 'bring up winver'), (100, 'load winver'), (100, 'i need winver'),
(100, 'افتح نافذة حول ويندوز'), (100, 'شغل نافذة حول ويندوز'), (100, 'تشغيل نافذة حول ويندوز'), (100, 'فتح نافذة حول ويندوز'), (100, 'اظهر winver'), (100, 'ابدا winver'), (100, 'اريد winver'),
(100, 'ouvrir la fenetre a propos de windows'), (100, 'lancer la fenetre a propos de windows'), (100, 'demarrer la fenetre a propos de windows'), (100, 'afficher winver'), (100, 'montre winver'), (100, 'ouvre winver'),

-- 101. open_disk_defragmenter
(101, 'open disk defragmenter'), (101, 'launch disk defragmenter'), (101, 'start disk defragmenter'), (101, 'run disk defragmenter'), (101, 'show defrag tool'), (101, 'bring up defrag tool'), (101, 'load defrag tool'), (101, 'i need defrag tool'),
(101, 'افتح محسن الاقراص'), (101, 'شغل محسن الاقراص'), (101, 'تشغيل محسن الاقراص'), (101, 'فتح محسن الاقراص'), (101, 'اظهر ديفراج'), (101, 'ابدا ديفراج'), (101, 'اريد ديفراج'),
(101, 'ouvrir le defragmenteur de disque'), (101, 'lancer le defragmenteur de disque'), (101, 'demarrer le defragmenteur de disque'), (101, 'afficher l outil de defragmentation'), (101, 'montre l outil de defragmentation'), (101, 'ouvre l outil de defragmentation'),

-- 102. open_remote_desktop_connection
(102, 'open remote desktop connection'), (102, 'launch remote desktop connection'), (102, 'start remote desktop connection'), (102, 'run remote desktop connection'), (102, 'show mstsc'), (102, 'bring up mstsc'), (102, 'load mstsc'), (102, 'i need mstsc'),
(102, 'افتح اتصال سطح المكتب البعيد'), (102, 'شغل اتصال سطح المكتب البعيد'), (102, 'تشغيل اتصال سطح المكتب البعيد'), (102, 'فتح اتصال سطح المكتب البعيد'), (102, 'اظهر mstsc'), (102, 'ابدا mstsc'), (102, 'اريد mstsc'),
(102, 'ouvrir la connexion bureau a distance'), (102, 'lancer la connexion bureau a distance'), (102, 'demarrer la connexion bureau a distance'), (102, 'afficher mstsc'), (102, 'montre mstsc'), (102, 'ouvre mstsc'),

-- 103. open_magnifier
(103, 'open magnifier'), (103, 'launch magnifier'), (103, 'start magnifier'), (103, 'run magnifier'), (103, 'show screen magnifier'), (103, 'bring up screen magnifier'), (103, 'load screen magnifier'), (103, 'i need screen magnifier'),
(103, 'افتح المكبر'), (103, 'شغل المكبر'), (103, 'تشغيل المكبر'), (103, 'فتح المكبر'), (103, 'اظهر عدسة الشاشة'), (103, 'ابدا عدسة الشاشة'), (103, 'اريد عدسة الشاشة'),
(103, 'ouvrir la loupe'), (103, 'lancer la loupe'), (103, 'demarrer la loupe'), (103, 'afficher la loupe d ecran'), (103, 'montre la loupe d ecran'), (103, 'ouvre la loupe d ecran'),

-- 104. open_narrator
(104, 'open narrator'), (104, 'launch narrator'), (104, 'start narrator'), (104, 'run narrator'), (104, 'show screen reader'), (104, 'bring up screen reader'), (104, 'load screen reader'), (104, 'i need screen reader'),
(104, 'افتح الراوي'), (104, 'شغل الراوي'), (104, 'تشغيل الراوي'), (104, 'فتح الراوي'), (104, 'اظهر قارئ الشاشة'), (104, 'ابدا قارئ الشاشة'), (104, 'اريد قارئ الشاشة'),
(104, 'ouvrir le narrateur'), (104, 'lancer le narrateur'), (104, 'demarrer le narrateur'), (104, 'afficher le lecteur d ecran'), (104, 'montre le lecteur d ecran'), (104, 'ouvre le lecteur d ecran'),

-- 105. open_on_screen_keyboard
(105, 'open on screen keyboard'), (105, 'launch on screen keyboard'), (105, 'start on screen keyboard'), (105, 'run on screen keyboard'), (105, 'show virtual keyboard'), (105, 'bring up virtual keyboard'), (105, 'load virtual keyboard'), (105, 'i need virtual keyboard'),
(105, 'افتح لوحة المفاتيح الافتراضية'), (105, 'شغل لوحة المفاتيح الافتراضية'), (105, 'تشغيل لوحة المفاتيح الافتراضية'), (105, 'فتح لوحة المفاتيح الافتراضية'), (105, 'اظهر الكيبورد الافتراضي'), (105, 'ابدا الكيبورد الافتراضي'), (105, 'اريد الكيبورد الافتراضي'),
(105, 'ouvrir le clavier virtuel'), (105, 'lancer le clavier virtuel'), (105, 'demarrer le clavier virtuel'), (105, 'afficher le clavier a l ecran'), (105, 'montre le clavier a l ecran'), (105, 'ouvre le clavier a l ecran'),

-- 106. open_character_map
(106, 'open character map'), (106, 'launch character map'), (106, 'start character map'), (106, 'run character map'), (106, 'show charmap'), (106, 'bring up charmap'), (106, 'load charmap'), (106, 'i need charmap'),
(106, 'افتح خريطة الاحرف'), (106, 'شغل خريطة الاحرف'), (106, 'تشغيل خريطة الاحرف'), (106, 'فتح خريطة الاحرف'), (106, 'اظهر charmap'), (106, 'ابدا charmap'), (106, 'اريد charmap'),
(106, 'ouvrir la table des caracteres'), (106, 'lancer la table des caracteres'), (106, 'demarrer la table des caracteres'), (106, 'afficher charmap'), (106, 'montre charmap'), (106, 'ouvre charmap'),

-- 107. open_windows_firewall
(107, 'open windows firewall'), (107, 'launch windows firewall'), (107, 'start windows firewall'), (107, 'run windows firewall'), (107, 'show firewall panel'), (107, 'bring up firewall panel'), (107, 'load firewall panel'), (107, 'i need firewall panel'),
(107, 'افتح جدار حماية ويندوز'), (107, 'شغل جدار حماية ويندوز'), (107, 'تشغيل جدار حماية ويندوز'), (107, 'فتح جدار حماية ويندوز'), (107, 'اظهر لوحة الجدار الناري'), (107, 'ابدا لوحة الجدار الناري'), (107, 'اريد لوحة الجدار الناري'),
(107, 'ouvrir le pare feu windows'), (107, 'lancer le pare feu windows'), (107, 'demarrer le pare feu windows'), (107, 'afficher le panneau du pare feu'), (107, 'montre le panneau du pare feu'), (107, 'ouvre le panneau du pare feu'),

-- 108. open_certificate_manager
(108, 'open certificate manager'), (108, 'launch certificate manager'), (108, 'start certificate manager'), (108, 'run certificate manager'), (108, 'show certmgr'), (108, 'bring up certmgr'), (108, 'load certmgr'), (108, 'i need certmgr'),
(108, 'افتح مدير الشهادات'), (108, 'شغل مدير الشهادات'), (108, 'تشغيل مدير الشهادات'), (108, 'فتح مدير الشهادات'), (108, 'اظهر certmgr'), (108, 'ابدا certmgr'), (108, 'اريد certmgr'),
(108, 'ouvrir le gestionnaire de certificats'), (108, 'lancer le gestionnaire de certificats'), (108, 'demarrer le gestionnaire de certificats'), (108, 'afficher certmgr'), (108, 'montre certmgr'), (108, 'ouvre certmgr'),

-- 109. open_volume_mixer
(109, 'open volume mixer'), (109, 'launch volume mixer'), (109, 'start volume mixer'), (109, 'run volume mixer'), (109, 'show sound mixer'), (109, 'bring up sound mixer'), (109, 'load sound mixer'), (109, 'i need sound mixer'),
(109, 'افتح خلاط الصوت'), (109, 'شغل خلاط الصوت'), (109, 'تشغيل خلاط الصوت'), (109, 'فتح خلاط الصوت'), (109, 'اظهر مازج الصوت'), (109, 'ابدا مازج الصوت'), (109, 'اريد مازج الصوت'),
(109, 'ouvrir le melangeur de volume'), (109, 'lancer le melangeur de volume'), (109, 'demarrer le melangeur de volume'), (109, 'afficher le melangeur audio'), (109, 'montre le melangeur audio'), (109, 'ouvre le melangeur audio'),

-- 110. open_windows_media_player
(110, 'open windows media player'), (110, 'launch windows media player'), (110, 'start windows media player'), (110, 'run windows media player'), (110, 'show wmplayer'), (110, 'bring up wmplayer'), (110, 'load wmplayer'), (110, 'i need wmplayer'),
(110, 'افتح مشغل ويندوز ميديا'), (110, 'شغل مشغل ويندوز ميديا'), (110, 'تشغيل مشغل ويندوز ميديا'), (110, 'فتح مشغل ويندوز ميديا'), (110, 'اظهر wmplayer'), (110, 'ابدا wmplayer'), (110, 'اريد wmplayer'),
(110, 'ouvrir windows media player'), (110, 'lancer windows media player'), (110, 'demarrer windows media player'), (110, 'afficher le lecteur multimedia'), (110, 'montre le lecteur multimedia'), (110, 'ouvre le lecteur multimedia'),

-- 111. open_photos_app
(111, 'open photos app'), (111, 'launch photos app'), (111, 'start photos app'), (111, 'run photos app'), (111, 'show photo viewer'), (111, 'bring up photo viewer'), (111, 'load photo viewer'), (111, 'i need photo viewer'),
(111, 'افتح تطبيق الصور'), (111, 'شغل تطبيق الصور'), (111, 'تشغيل تطبيق الصور'), (111, 'فتح تطبيق الصور'), (111, 'اظهر عارض الصور'), (111, 'ابدا عارض الصور'), (111, 'اريد عارض الصور'),
(111, 'ouvrir l application photos'), (111, 'lancer l application photos'), (111, 'demarrer l application photos'), (111, 'afficher la visionneuse de photos'), (111, 'montre la visionneuse de photos'), (111, 'ouvre la visionneuse de photos'),

-- 112. open_alarm_clock_app
(112, 'open alarm clock app'), (112, 'launch alarm clock app'), (112, 'start alarm clock app'), (112, 'run alarm clock app'), (112, 'show alarms'), (112, 'bring up alarms'), (112, 'load alarms'), (112, 'i need alarms'),
(112, 'افتح تطبيق المنبه'), (112, 'شغل تطبيق المنبه'), (112, 'تشغيل تطبيق المنبه'), (112, 'فتح تطبيق المنبه'), (112, 'اظهر المنبهات'), (112, 'ابدا المنبهات'), (112, 'اريد المنبهات'),
(112, 'ouvrir l application horloge'), (112, 'lancer l application horloge'), (112, 'demarrer l application horloge'), (112, 'afficher les alarmes'), (112, 'montre les alarmes'), (112, 'ouvre les alarmes'),

-- 113. open_camera_app
(113, 'open camera app'), (113, 'launch camera app'), (113, 'start camera app'), (113, 'run camera app'), (113, 'show webcam app'), (113, 'bring up webcam app'), (113, 'load webcam app'), (113, 'i need webcam app'),
(113, 'افتح تطبيق الكاميرا'), (113, 'شغل تطبيق الكاميرا'), (113, 'تشغيل تطبيق الكاميرا'), (113, 'فتح تطبيق الكاميرا'), (113, 'اظهر كاميرا الويب'), (113, 'ابدا كاميرا الويب'), (113, 'اريد كاميرا الويب'),
(113, 'ouvrir l application camera'), (113, 'lancer l application camera'), (113, 'demarrer l application camera'), (113, 'afficher la webcam'), (113, 'montre la webcam'), (113, 'ouvre la webcam'),

-- 114. open_microsoft_store
(114, 'open microsoft store'), (114, 'launch microsoft store'), (114, 'start microsoft store'), (114, 'run microsoft store'), (114, 'show app store'), (114, 'bring up app store'), (114, 'load app store'), (114, 'i need app store'),
(114, 'افتح متجر مايكروسوفت'), (114, 'شغل متجر مايكروسوفت'), (114, 'تشغيل متجر مايكروسوفت'), (114, 'فتح متجر مايكروسوفت'), (114, 'اظهر متجر التطبيقات'), (114, 'ابدا متجر التطبيقات'), (114, 'اريد متجر التطبيقات'),
(114, 'ouvrir le microsoft store'), (114, 'lancer le microsoft store'), (114, 'demarrer le microsoft store'), (114, 'afficher la boutique d applications'), (114, 'montre la boutique d applications'), (114, 'ouvre la boutique d applications'),

-- 115. open_microsoft_word
(115, 'open microsoft word'), (115, 'launch microsoft word'), (115, 'start microsoft word'), (115, 'run microsoft word'), (115, 'show word processor'), (115, 'bring up word processor'), (115, 'load word processor'), (115, 'i need word processor'),
(115, 'افتح مايكروسوفت وورد'), (115, 'شغل مايكروسوفت وورد'), (115, 'تشغيل مايكروسوفت وورد'), (115, 'فتح مايكروسوفت وورد'), (115, 'اظهر معالج النصوص'), (115, 'ابدا معالج النصوص'), (115, 'اريد معالج النصوص'),
(115, 'ouvrir microsoft word'), (115, 'lancer microsoft word'), (115, 'demarrer microsoft word'), (115, 'afficher le traitement de texte'), (115, 'montre le traitement de texte'), (115, 'ouvre le traitement de texte'),

-- 116. open_microsoft_excel
(116, 'open microsoft excel'), (116, 'launch microsoft excel'), (116, 'start microsoft excel'), (116, 'run microsoft excel'), (116, 'show spreadsheet app'), (116, 'bring up spreadsheet app'), (116, 'load spreadsheet app'), (116, 'i need spreadsheet app'),
(116, 'افتح مايكروسوفت اكسل'), (116, 'شغل مايكروسوفت اكسل'), (116, 'تشغيل مايكروسوفت اكسل'), (116, 'فتح مايكروسوفت اكسل'), (116, 'اظهر برنامج الجداول'), (116, 'ابدا برنامج الجداول'), (116, 'اريد برنامج الجداول'),
(116, 'ouvrir microsoft excel'), (116, 'lancer microsoft excel'), (116, 'demarrer microsoft excel'), (116, 'afficher le tableur'), (116, 'montre le tableur'), (116, 'ouvre le tableur'),

-- 117. open_microsoft_powerpoint
(117, 'open microsoft powerpoint'), (117, 'launch microsoft powerpoint'), (117, 'start microsoft powerpoint'), (117, 'run microsoft powerpoint'), (117, 'show presentation app'), (117, 'bring up presentation app'), (117, 'load presentation app'), (117, 'i need presentation app'),
(117, 'افتح مايكروسوفت بوربوينت'), (117, 'شغل مايكروسوفت بوربوينت'), (117, 'تشغيل مايكروسوفت بوربوينت'), (117, 'فتح مايكروسوفت بوربوينت'), (117, 'اظهر برنامج العروض'), (117, 'ابدا برنامج العروض'), (117, 'اريد برنامج العروض'),
(117, 'ouvrir microsoft powerpoint'), (117, 'lancer microsoft powerpoint'), (117, 'demarrer microsoft powerpoint'), (117, 'afficher le logiciel de presentation'), (117, 'montre le logiciel de presentation'), (117, 'ouvre le logiciel de presentation'),

-- 118. open_outlook_desktop
(118, 'open outlook desktop'), (118, 'launch outlook desktop'), (118, 'start outlook desktop'), (118, 'run outlook desktop'), (118, 'show outlook client'), (118, 'bring up outlook client'), (118, 'load outlook client'), (118, 'i need outlook client'),
(118, 'افتح اوتلوك سطح المكتب'), (118, 'شغل اوتلوك سطح المكتب'), (118, 'تشغيل اوتلوك سطح المكتب'), (118, 'فتح اوتلوك سطح المكتب'), (118, 'اظهر عميل اوتلوك'), (118, 'ابدا عميل اوتلوك'), (118, 'اريد عميل اوتلوك'),
(118, 'ouvrir outlook de bureau'), (118, 'lancer outlook de bureau'), (118, 'demarrer outlook de bureau'), (118, 'afficher le client outlook'), (118, 'montre le client outlook'), (118, 'ouvre le client outlook'),

-- 119. open_onenote
(119, 'open onenote'), (119, 'launch onenote'), (119, 'start onenote'), (119, 'run onenote'), (119, 'show note taking app'), (119, 'bring up note taking app'), (119, 'load note taking app'), (119, 'i need note taking app'),
(119, 'افتح ون نوت'), (119, 'شغل ون نوت'), (119, 'تشغيل ون نوت'), (119, 'فتح ون نوت'), (119, 'اظهر تطبيق تدوين الملاحظات'), (119, 'ابدا تطبيق تدوين الملاحظات'), (119, 'اريد تطبيق تدوين الملاحظات'),
(119, 'ouvrir onenote'), (119, 'lancer onenote'), (119, 'demarrer onenote'), (119, 'afficher l application de prise de notes'), (119, 'montre l application de prise de notes'), (119, 'ouvre l application de prise de notes'),

-- 120. open_mozilla_firefox
(120, 'open mozilla firefox'), (120, 'launch mozilla firefox'), (120, 'start mozilla firefox'), (120, 'run mozilla firefox'), (120, 'show firefox browser'), (120, 'bring up firefox browser'), (120, 'load firefox browser'), (120, 'i need firefox browser'),
(120, 'افتح موزيلا فايرفوكس'), (120, 'شغل موزيلا فايرفوكس'), (120, 'تشغيل موزيلا فايرفوكس'), (120, 'فتح موزيلا فايرفوكس'), (120, 'اظهر متصفح فايرفوكس'), (120, 'ابدا متصفح فايرفوكس'), (120, 'اريد متصفح فايرفوكس'),
(120, 'ouvrir mozilla firefox'), (120, 'lancer mozilla firefox'), (120, 'demarrer mozilla firefox'), (120, 'afficher le navigateur firefox'), (120, 'montre le navigateur firefox'), (120, 'ouvre le navigateur firefox'),

-- 121. open_brave_browser
(121, 'open brave browser'), (121, 'launch brave browser'), (121, 'start brave browser'), (121, 'run brave browser'), (121, 'show brave'), (121, 'bring up brave'), (121, 'load brave'), (121, 'i need brave'),
(121, 'افتح متصفح بريف'), (121, 'شغل متصفح بريف'), (121, 'تشغيل متصفح بريف'), (121, 'فتح متصفح بريف'), (121, 'اظهر بريف'), (121, 'ابدا بريف'), (121, 'اريد بريف'),
(121, 'ouvrir le navigateur brave'), (121, 'lancer le navigateur brave'), (121, 'demarrer le navigateur brave'), (121, 'afficher brave'), (121, 'montre brave'), (121, 'ouvre brave'),

-- 122. open_opera_browser
(122, 'open opera browser'), (122, 'launch opera browser'), (122, 'start opera browser'), (122, 'run opera browser'), (122, 'show opera'), (122, 'bring up opera'), (122, 'load opera'), (122, 'i need opera'),
(122, 'افتح متصفح اوبرا'), (122, 'شغل متصفح اوبرا'), (122, 'تشغيل متصفح اوبرا'), (122, 'فتح متصفح اوبرا'), (122, 'اظهر اوبرا'), (122, 'ابدا اوبرا'), (122, 'اريد اوبرا'),
(122, 'ouvrir le navigateur opera'), (122, 'lancer le navigateur opera'), (122, 'demarrer le navigateur opera'), (122, 'afficher opera'), (122, 'montre opera'), (122, 'ouvre opera'),

-- 123. open_steam
(123, 'open steam'), (123, 'launch steam'), (123, 'start steam'), (123, 'run steam'), (123, 'show steam client'), (123, 'bring up steam client'), (123, 'load steam client'), (123, 'i need steam client'),
(123, 'افتح ستيم'), (123, 'شغل ستيم'), (123, 'تشغيل ستيم'), (123, 'فتح ستيم'), (123, 'اظهر برنامج ستيم'), (123, 'ابدا برنامج ستيم'), (123, 'اريد برنامج ستيم'),
(123, 'ouvrir steam'), (123, 'lancer steam'), (123, 'demarrer steam'), (123, 'afficher le client steam'), (123, 'montre le client steam'), (123, 'ouvre le client steam'),

-- 124. open_python_console
(124, 'open python console'), (124, 'launch python console'), (124, 'start python console'), (124, 'run python console'), (124, 'show python shell'), (124, 'bring up python shell'), (124, 'load python shell'), (124, 'i need python shell'),
(124, 'افتح كونسول بايثون'), (124, 'شغل كونسول بايثون'), (124, 'تشغيل كونسول بايثون'), (124, 'فتح كونسول بايثون'), (124, 'اظهر محرر بايثون التفاعلي'), (124, 'ابدا محرر بايثون التفاعلي'), (124, 'اريد محرر بايثون التفاعلي'),
(124, 'ouvrir la console python'), (124, 'lancer la console python'), (124, 'demarrer la console python'), (124, 'afficher l interpreteur python'), (124, 'montre l interpreteur python'), (124, 'ouvre l interpreteur python'),

-- 125. open_wsl
(125, 'open wsl'), (125, 'launch wsl'), (125, 'start wsl'), (125, 'run wsl'), (125, 'show linux subsystem'), (125, 'bring up linux subsystem'), (125, 'load linux subsystem'), (125, 'i need linux subsystem'),
(125, 'افتح لينكس على ويندوز'), (125, 'شغل لينكس على ويندوز'), (125, 'تشغيل لينكس على ويندوز'), (125, 'فتح لينكس على ويندوز'), (125, 'اظهر wsl'), (125, 'ابدا wsl'), (125, 'اريد wsl'),
(125, 'ouvrir wsl'), (125, 'lancer wsl'), (125, 'demarrer wsl'), (125, 'afficher le sous systeme linux'), (125, 'montre le sous systeme linux'), (125, 'ouvre le sous systeme linux'),

-- 126. open_environment_variables
(126, 'open environment variables'), (126, 'launch environment variables'), (126, 'start environment variables'), (126, 'run environment variables'), (126, 'show env variables'), (126, 'bring up env variables'), (126, 'load env variables'), (126, 'i need env variables'),
(126, 'افتح متغيرات البيئة'), (126, 'شغل متغيرات البيئة'), (126, 'تشغيل متغيرات البيئة'), (126, 'فتح متغيرات البيئة'), (126, 'اظهر متغيرات النظام'), (126, 'ابدا متغيرات النظام'), (126, 'اريد متغيرات النظام'),
(126, 'ouvrir les variables d environnement'), (126, 'lancer les variables d environnement'), (126, 'demarrer les variables d environnement'), (126, 'afficher les variables systeme'), (126, 'montre les variables systeme'), (126, 'ouvre les variables systeme'),

-- 127. open_programs_and_features
(127, 'open programs and features'), (127, 'launch programs and features'), (127, 'start programs and features'), (127, 'run programs and features'), (127, 'show uninstall programs'), (127, 'bring up uninstall programs'), (127, 'load uninstall programs'), (127, 'i need uninstall programs'),
(127, 'افتح البرامج والميزات'), (127, 'شغل البرامج والميزات'), (127, 'تشغيل البرامج والميزات'), (127, 'فتح البرامج والميزات'), (127, 'اظهر ازالة البرامج'), (127, 'ابدا ازالة البرامج'), (127, 'اريد ازالة البرامج'),
(127, 'ouvrir programmes et fonctionnalites'), (127, 'lancer programmes et fonctionnalites'), (127, 'demarrer programmes et fonctionnalites'), (127, 'afficher desinstaller des programmes'), (127, 'montre desinstaller des programmes'), (127, 'ouvre desinstaller des programmes'),

-- 128. open_internet_options
(128, 'open internet options'), (128, 'launch internet options'), (128, 'start internet options'), (128, 'run internet options'), (128, 'show internet properties'), (128, 'bring up internet properties'), (128, 'load internet properties'), (128, 'i need internet properties'),
(128, 'افتح خيارات الانترنت'), (128, 'شغل خيارات الانترنت'), (128, 'تشغيل خيارات الانترنت'), (128, 'فتح خيارات الانترنت'), (128, 'اظهر خصائص الانترنت'), (128, 'ابدا خصائص الانترنت'), (128, 'اريد خصائص الانترنت'),
(128, 'ouvrir les options internet'), (128, 'lancer les options internet'), (128, 'demarrer les options internet'), (128, 'afficher les proprietes internet'), (128, 'montre les proprietes internet'), (128, 'ouvre les proprietes internet'),

-- 129. open_power_options
(129, 'open power options'), (129, 'launch power options'), (129, 'start power options'), (129, 'run power options'), (129, 'show power plan'), (129, 'bring up power plan'), (129, 'load power plan'), (129, 'i need power plan'),
(129, 'افتح خيارات الطاقة'), (129, 'شغل خيارات الطاقة'), (129, 'تشغيل خيارات الطاقة'), (129, 'فتح خيارات الطاقة'), (129, 'اظهر خطة الطاقة'), (129, 'ابدا خطة الطاقة'), (129, 'اريد خطة الطاقة'),
(129, 'ouvrir les options d alimentation'), (129, 'lancer les options d alimentation'), (129, 'demarrer les options d alimentation'), (129, 'afficher le plan d alimentation'), (129, 'montre le plan d alimentation'), (129, 'ouvre le plan d alimentation'),

-- 130. open_user_accounts
(130, 'open user accounts'), (130, 'launch user accounts'), (130, 'start user accounts'), (130, 'run user accounts'), (130, 'show netplwiz'), (130, 'bring up netplwiz'), (130, 'load netplwiz'), (130, 'i need netplwiz'),
(130, 'افتح حسابات المستخدمين'), (130, 'شغل حسابات المستخدمين'), (130, 'تشغيل حسابات المستخدمين'), (130, 'فتح حسابات المستخدمين'), (130, 'اظهر netplwiz'), (130, 'ابدا netplwiz'), (130, 'اريد netplwiz'),
(130, 'ouvrir les comptes utilisateurs'), (130, 'lancer les comptes utilisateurs'), (130, 'demarrer les comptes utilisateurs'), (130, 'afficher netplwiz'), (130, 'montre netplwiz'), (130, 'ouvre netplwiz'),

-- 131. open_bluetooth_file_transfer
(131, 'open bluetooth file transfer'), (131, 'launch bluetooth file transfer'), (131, 'start bluetooth file transfer'), (131, 'run bluetooth file transfer'), (131, 'show fsquirt'), (131, 'bring up fsquirt'), (131, 'load fsquirt'), (131, 'i need fsquirt'),
(131, 'افتح نقل الملفات بالبلوتوث'), (131, 'شغل نقل الملفات بالبلوتوث'), (131, 'تشغيل نقل الملفات بالبلوتوث'), (131, 'فتح نقل الملفات بالبلوتوث'), (131, 'اظهر fsquirt'), (131, 'ابدا fsquirt'), (131, 'اريد fsquirt'),
(131, 'ouvrir le transfert de fichiers bluetooth'), (131, 'lancer le transfert de fichiers bluetooth'), (131, 'demarrer le transfert de fichiers bluetooth'), (131, 'afficher fsquirt'), (131, 'montre fsquirt'), (131, 'ouvre fsquirt'),

-- 132. open_malicious_software_removal_tool
(132, 'open malicious software removal tool'), (132, 'launch malicious software removal tool'), (132, 'start malicious software removal tool'), (132, 'run malicious software removal tool'), (132, 'show mrt'), (132, 'bring up mrt'), (132, 'load mrt'), (132, 'i need mrt'),
(132, 'افتح اداة ازالة البرامج الخبيثة'), (132, 'شغل اداة ازالة البرامج الخبيثة'), (132, 'تشغيل اداة ازالة البرامج الخبيثة'), (132, 'فتح اداة ازالة البرامج الخبيثة'), (132, 'اظهر mrt'), (132, 'ابدا mrt'), (132, 'اريد mrt'),
(132, 'ouvrir l outil de suppression des logiciels malveillants'), (132, 'lancer l outil de suppression des logiciels malveillants'), (132, 'demarrer l outil de suppression des logiciels malveillants'), (132, 'afficher mrt'), (132, 'montre mrt'), (132, 'ouvre mrt'),

-- 133. open_security_and_maintenance
(133, 'open security and maintenance'), (133, 'launch security and maintenance'), (133, 'start security and maintenance'), (133, 'run security and maintenance'), (133, 'show security center'), (133, 'bring up security center'), (133, 'load security center'), (133, 'i need security center'),
(133, 'افتح الامان والصيانة'), (133, 'شغل الامان والصيانة'), (133, 'تشغيل الامان والصيانة'), (133, 'فتح الامان والصيانة'), (133, 'اظهر مركز الامان'), (133, 'ابدا مركز الامان'), (133, 'اريد مركز الامان'),
(133, 'ouvrir securite et maintenance'), (133, 'lancer securite et maintenance'), (133, 'demarrer securite et maintenance'), (133, 'afficher le centre de securite'), (133, 'montre le centre de securite'), (133, 'ouvre le centre de securite'),

-- 134. open_group_policy_editor
(134, 'open group policy editor'), (134, 'launch group policy editor'), (134, 'start group policy editor'), (134, 'run group policy editor'), (134, 'show gpedit'), (134, 'bring up gpedit'), (134, 'load gpedit'), (134, 'i need gpedit'),
(134, 'افتح محرر سياسة المجموعة'), (134, 'شغل محرر سياسة المجموعة'), (134, 'تشغيل محرر سياسة المجموعة'), (134, 'فتح محرر سياسة المجموعة'), (134, 'اظهر gpedit'), (134, 'ابدا gpedit'), (134, 'اريد gpedit'),
(134, 'ouvrir l editeur de strategie de groupe'), (134, 'lancer l editeur de strategie de groupe'), (134, 'demarrer l editeur de strategie de groupe'), (134, 'afficher gpedit'), (134, 'montre gpedit'), (134, 'ouvre gpedit'),

-- 135. open_reliability_monitor
(135, 'open reliability monitor'), (135, 'launch reliability monitor'), (135, 'start reliability monitor'), (135, 'run reliability monitor'), (135, 'show reliability history'), (135, 'bring up reliability history'), (135, 'load reliability history'), (135, 'i need reliability history'),
(135, 'افتح مراقب الموثوقية'), (135, 'شغل مراقب الموثوقية'), (135, 'تشغيل مراقب الموثوقية'), (135, 'فتح مراقب الموثوقية'), (135, 'اظهر سجل الموثوقية'), (135, 'ابدا سجل الموثوقية'), (135, 'اريد سجل الموثوقية'),
(135, 'ouvrir le moniteur de fiabilite'), (135, 'lancer le moniteur de fiabilite'), (135, 'demarrer le moniteur de fiabilite'), (135, 'afficher l historique de fiabilite'), (135, 'montre l historique de fiabilite'), (135, 'ouvre l historique de fiabilite'),

-- 136. open_shared_folders_manager
(136, 'open shared folders manager'), (136, 'launch shared folders manager'), (136, 'start shared folders manager'), (136, 'run shared folders manager'), (136, 'show shared folders'), (136, 'bring up shared folders'), (136, 'load shared folders'), (136, 'i need shared folders'),
(136, 'افتح ادارة المجلدات المشتركة'), (136, 'شغل ادارة المجلدات المشتركة'), (136, 'تشغيل ادارة المجلدات المشتركة'), (136, 'فتح ادارة المجلدات المشتركة'), (136, 'اظهر المجلدات المشتركة'), (136, 'ابدا المجلدات المشتركة'), (136, 'اريد المجلدات المشتركة'),
(136, 'ouvrir le gestionnaire de dossiers partages'), (136, 'lancer le gestionnaire de dossiers partages'), (136, 'demarrer le gestionnaire de dossiers partages'), (136, 'afficher les dossiers partages'), (136, 'montre les dossiers partages'), (136, 'ouvre les dossiers partages'),

-- 137. open_windows_features_dialog
(137, 'open windows features dialog'), (137, 'launch windows features dialog'), (137, 'start windows features dialog'), (137, 'run windows features dialog'), (137, 'show turn windows features on or off'), (137, 'bring up turn windows features on or off'), (137, 'load turn windows features on or off'), (137, 'i need turn windows features on or off'),
(137, 'افتح ميزات ويندوز'), (137, 'شغل ميزات ويندوز'), (137, 'تشغيل ميزات ويندوز'), (137, 'فتح ميزات ويندوز'), (137, 'اظهر تشغيل او ايقاف ميزات ويندوز'), (137, 'ابدا تشغيل او ايقاف ميزات ويندوز'), (137, 'اريد تشغيل او ايقاف ميزات ويندوز'),
(137, 'ouvrir les fonctionnalites windows'), (137, 'lancer les fonctionnalites windows'), (137, 'demarrer les fonctionnalites windows'), (137, 'afficher activer ou desactiver des fonctionnalites windows'), (137, 'montre activer ou desactiver des fonctionnalites windows'), (137, 'ouvre activer ou desactiver des fonctionnalites windows'),

-- 138. open_maps_app
(138, 'open maps app'), (138, 'launch maps app'), (138, 'start maps app'), (138, 'run maps app'), (138, 'show windows maps'), (138, 'bring up windows maps'), (138, 'load windows maps'), (138, 'i need windows maps'),
(138, 'افتح تطبيق الخرائط'), (138, 'شغل تطبيق الخرائط'), (138, 'تشغيل تطبيق الخرائط'), (138, 'فتح تطبيق الخرائط'), (138, 'اظهر خرائط ويندوز'), (138, 'ابدا خرائط ويندوز'), (138, 'اريد خرائط ويندوز'),
(138, 'ouvrir l application cartes'), (138, 'lancer l application cartes'), (138, 'demarrer l application cartes'), (138, 'afficher cartes windows'), (138, 'montre cartes windows'), (138, 'ouvre cartes windows'),

-- 139. open_xbox_app
(139, 'open xbox app'), (139, 'launch xbox app'), (139, 'start xbox app'), (139, 'run xbox app'), (139, 'show xbox'), (139, 'bring up xbox'), (139, 'load xbox'), (139, 'i need xbox'),
(139, 'افتح تطبيق اكس بوكس'), (139, 'شغل تطبيق اكس بوكس'), (139, 'تشغيل تطبيق اكس بوكس'), (139, 'فتح تطبيق اكس بوكس'), (139, 'اظهر اكس بوكس'), (139, 'ابدا اكس بوكس'), (139, 'اريد اكس بوكس'),
(139, 'ouvrir l application xbox'), (139, 'lancer l application xbox'), (139, 'demarrer l application xbox'), (139, 'afficher xbox'), (139, 'montre xbox'), (139, 'ouvre xbox'),

-- 140. open_management_console
(140, 'open management console'), (140, 'launch management console'), (140, 'start management console'), (140, 'run management console'), (140, 'show mmc'), (140, 'bring up mmc'), (140, 'load mmc'), (140, 'i need mmc'),
(140, 'افتح وحدة تحكم الادارة'), (140, 'شغل وحدة تحكم الادارة'), (140, 'تشغيل وحدة تحكم الادارة'), (140, 'فتح وحدة تحكم الادارة'), (140, 'اظهر mmc'), (140, 'ابدا mmc'), (140, 'اريد mmc'),
(140, 'ouvrir la console de gestion'), (140, 'lancer la console de gestion'), (140, 'demarrer la console de gestion'), (140, 'afficher mmc'), (140, 'montre mmc'), (140, 'ouvre mmc'),

-- 141. open_system_restore
(141, 'open system restore'), (141, 'launch system restore'), (141, 'start system restore'), (141, 'run system restore'), (141, 'show restore points'), (141, 'bring up restore points'), (141, 'load restore points'), (141, 'i need restore points'),
(141, 'افتح استعادة النظام'), (141, 'شغل استعادة النظام'), (141, 'تشغيل استعادة النظام'), (141, 'فتح استعادة النظام'), (141, 'اظهر نقاط الاستعادة'), (141, 'ابدا نقاط الاستعادة'), (141, 'اريد نقاط الاستعادة'),
(141, 'ouvrir la restauration du systeme'), (141, 'lancer la restauration du systeme'), (141, 'demarrer la restauration du systeme'), (141, 'afficher les points de restauration'), (141, 'montre les points de restauration'), (141, 'ouvre les points de restauration'),

-- 142. open_memory_diagnostic
(142, 'open memory diagnostic'), (142, 'launch memory diagnostic'), (142, 'start memory diagnostic'), (142, 'run memory diagnostic'), (142, 'show ram test'), (142, 'bring up ram test'), (142, 'load ram test'), (142, 'i need ram test'),
(142, 'افتح تشخيص الذاكرة'), (142, 'شغل تشخيص الذاكرة'), (142, 'تشغيل تشخيص الذاكرة'), (142, 'فتح تشخيص الذاكرة'), (142, 'اظهر فحص الرام'), (142, 'ابدا فحص الرام'), (142, 'اريد فحص الرام'),
(142, 'ouvrir le diagnostic de la memoire'), (142, 'lancer le diagnostic de la memoire'), (142, 'demarrer le diagnostic de la memoire'), (142, 'afficher le test de la ram'), (142, 'montre le test de la ram'), (142, 'ouvre le test de la ram'),

-- 143. open_run_dialog
(143, 'open run dialog'), (143, 'launch run dialog'), (143, 'start run dialog'), (143, 'run run dialog'), (143, 'show run box'), (143, 'bring up run box'), (143, 'load run box'), (143, 'i need run box'),
(143, 'افتح نافذة التشغيل'), (143, 'شغل نافذة التشغيل'), (143, 'تشغيل نافذة التشغيل'), (143, 'فتح نافذة التشغيل'), (143, 'اظهر مربع التشغيل'), (143, 'ابدا مربع التشغيل'), (143, 'اريد مربع التشغيل'),
(143, 'ouvrir la boite executer'), (143, 'lancer la boite executer'), (143, 'demarrer la boite executer'), (143, 'afficher la fenetre executer'), (143, 'montre la fenetre executer'), (143, 'ouvre la fenetre executer'),

-- 144. open_start_menu
(144, 'open start menu'), (144, 'launch start menu'), (144, 'start start menu'), (144, 'run start menu'), (144, 'show windows menu'), (144, 'bring up windows menu'), (144, 'load windows menu'), (144, 'i need windows menu'),
(144, 'افتح قائمة ابدا'), (144, 'شغل قائمة ابدا'), (144, 'تشغيل قائمة ابدا'), (144, 'فتح قائمة ابدا'), (144, 'اظهر قائمة ويندوز'), (144, 'ابدا قائمة ويندوز'), (144, 'اريد قائمة ويندوز'),
(144, 'ouvrir le menu demarrer'), (144, 'lancer le menu demarrer'), (144, 'demarrer le menu demarrer'), (144, 'afficher le menu windows'), (144, 'montre le menu windows'), (144, 'ouvre le menu windows'),

-- 145. open_notification_center
(145, 'open notification center'), (145, 'launch notification center'), (145, 'start notification center'), (145, 'run notification center'), (145, 'show action center'), (145, 'bring up action center'), (145, 'load action center'), (145, 'i need action center'),
(145, 'افتح مركز الاشعارات'), (145, 'شغل مركز الاشعارات'), (145, 'تشغيل مركز الاشعارات'), (145, 'فتح مركز الاشعارات'), (145, 'اظهر مركز العمليات'), (145, 'ابدا مركز العمليات'), (145, 'اريد مركز العمليات'),
(145, 'ouvrir le centre de notifications'), (145, 'lancer le centre de notifications'), (145, 'demarrer le centre de notifications'), (145, 'afficher le centre d action'), (145, 'montre le centre d action'), (145, 'ouvre le centre d action'),

-- 146. open_display_settings
(146, 'open display settings'), (146, 'show display settings'), (146, 'go to screen settings'), (146, 'change screen settings'), (146, 'manage display settings'), (146, 'configure screen'), (146, 'open screen options'), (146, 'adjust display settings'),
(146, 'افتح اعدادات العرض'), (146, 'اعدادات العرض'), (146, 'اظهر اعدادات الشاشة'), (146, 'غير اعدادات الشاشة'), (146, 'اذهب الى اعدادات العرض'), (146, 'ضبط الشاشة'), (146, 'تعديل اعدادات العرض'),
(146, 'ouvrir les parametres affichage'), (146, 'parametres affichage'), (146, 'afficher les parametres ecran'), (146, 'modifier les parametres ecran'), (146, 'aller dans les parametres affichage'), (146, 'ouvrir options ecran'),

-- 147. open_sound_settings
(147, 'open sound settings'), (147, 'show sound settings'), (147, 'go to audio settings'), (147, 'change audio settings'), (147, 'manage sound settings'), (147, 'configure audio'), (147, 'open audio options'), (147, 'adjust sound settings'),
(147, 'افتح اعدادات الصوت'), (147, 'اعدادات الصوت'), (147, 'اظهر اعدادات الصوتيات'), (147, 'غير اعدادات الصوتيات'), (147, 'اذهب الى اعدادات الصوت'), (147, 'ضبط الصوتيات'), (147, 'تعديل اعدادات الصوت'),
(147, 'ouvrir les parametres son'), (147, 'parametres son'), (147, 'afficher les parametres audio'), (147, 'modifier les parametres audio'), (147, 'aller dans les parametres son'), (147, 'ouvrir options audio'),

-- 148. open_bluetooth_settings
(148, 'open bluetooth settings'), (148, 'show bluetooth settings'), (148, 'go to bluetooth devices settings'), (148, 'change bluetooth devices settings'), (148, 'manage bluetooth settings'), (148, 'configure bluetooth devices'), (148, 'open bluetooth devices options'), (148, 'adjust bluetooth settings'),
(148, 'افتح اعدادات البلوتوث'), (148, 'اعدادات البلوتوث'), (148, 'اظهر اعدادات اجهزة البلوتوث'), (148, 'غير اعدادات اجهزة البلوتوث'), (148, 'اذهب الى اعدادات البلوتوث'), (148, 'ضبط اجهزة البلوتوث'), (148, 'تعديل اعدادات البلوتوث'),
(148, 'ouvrir les parametres bluetooth'), (148, 'parametres bluetooth'), (148, 'afficher les parametres peripheriques bluetooth'), (148, 'modifier les parametres peripheriques bluetooth'), (148, 'aller dans les parametres bluetooth'), (148, 'ouvrir options peripheriques bluetooth'),

-- 149. open_wifi_settings
(149, 'open wifi settings'), (149, 'show wifi settings'), (149, 'go to wireless network settings'), (149, 'change wireless network settings'), (149, 'manage wifi settings'), (149, 'configure wireless network'), (149, 'open wireless network options'), (149, 'adjust wifi settings'),
(149, 'افتح اعدادات الواي فاي'), (149, 'اعدادات الواي فاي'), (149, 'اظهر اعدادات الشبكة اللاسلكية'), (149, 'غير اعدادات الشبكة اللاسلكية'), (149, 'اذهب الى اعدادات الواي فاي'), (149, 'ضبط الشبكة اللاسلكية'), (149, 'تعديل اعدادات الواي فاي'),
(149, 'ouvrir les parametres wifi'), (149, 'parametres wifi'), (149, 'afficher les parametres reseau sans fil'), (149, 'modifier les parametres reseau sans fil'), (149, 'aller dans les parametres wifi'), (149, 'ouvrir options reseau sans fil'),

-- 150. open_vpn_settings
(150, 'open vpn settings'), (150, 'show vpn settings'), (150, 'go to virtual private network settings'), (150, 'change virtual private network settings'), (150, 'manage vpn settings'), (150, 'configure virtual private network'), (150, 'open virtual private network options'), (150, 'adjust vpn settings'),
(150, 'افتح اعدادات في بي ان'), (150, 'اعدادات في بي ان'), (150, 'اظهر اعدادات الشبكة الافتراضية'), (150, 'غير اعدادات الشبكة الافتراضية'), (150, 'اذهب الى اعدادات في بي ان'), (150, 'ضبط الشبكة الافتراضية'), (150, 'تعديل اعدادات في بي ان'),
(150, 'ouvrir les parametres vpn'), (150, 'parametres vpn'), (150, 'afficher les parametres reseau prive virtuel'), (150, 'modifier les parametres reseau prive virtuel'), (150, 'aller dans les parametres vpn'), (150, 'ouvrir options reseau prive virtuel'),

-- 151. open_proxy_settings
(151, 'open proxy settings'), (151, 'show proxy settings'), (151, 'go to proxy server settings'), (151, 'change proxy server settings'), (151, 'manage proxy settings'), (151, 'configure proxy server'), (151, 'open proxy server options'), (151, 'adjust proxy settings'),
(151, 'افتح اعدادات البروكسي'), (151, 'اعدادات البروكسي'), (151, 'اظهر اعدادات خادم البروكسي'), (151, 'غير اعدادات خادم البروكسي'), (151, 'اذهب الى اعدادات البروكسي'), (151, 'ضبط خادم البروكسي'), (151, 'تعديل اعدادات البروكسي'),
(151, 'ouvrir les parametres proxy'), (151, 'parametres proxy'), (151, 'afficher les parametres serveur proxy'), (151, 'modifier les parametres serveur proxy'), (151, 'aller dans les parametres proxy'), (151, 'ouvrir options serveur proxy'),

-- 152. open_battery_settings
(152, 'open battery settings'), (152, 'show battery settings'), (152, 'go to battery saver settings'), (152, 'change battery saver settings'), (152, 'manage battery settings'), (152, 'configure battery saver'), (152, 'open battery saver options'), (152, 'adjust battery settings'),
(152, 'افتح اعدادات البطارية'), (152, 'اعدادات البطارية'), (152, 'اظهر اعدادات موفر البطارية'), (152, 'غير اعدادات موفر البطارية'), (152, 'اذهب الى اعدادات البطارية'), (152, 'ضبط موفر البطارية'), (152, 'تعديل اعدادات البطارية'),
(152, 'ouvrir les parametres batterie'), (152, 'parametres batterie'), (152, 'afficher les parametres economiseur de batterie'), (152, 'modifier les parametres economiseur de batterie'), (152, 'aller dans les parametres batterie'), (152, 'ouvrir options economiseur de batterie'),

-- 153. open_storage_settings
(153, 'open storage settings'), (153, 'show storage settings'), (153, 'go to storage sense settings'), (153, 'change storage sense settings'), (153, 'manage storage settings'), (153, 'configure storage sense'), (153, 'open storage sense options'), (153, 'adjust storage settings'),
(153, 'افتح اعدادات التخزين'), (153, 'اعدادات التخزين'), (153, 'اظهر اعدادات حساس التخزين'), (153, 'غير اعدادات حساس التخزين'), (153, 'اذهب الى اعدادات التخزين'), (153, 'ضبط حساس التخزين'), (153, 'تعديل اعدادات التخزين'),
(153, 'ouvrir les parametres stockage'), (153, 'parametres stockage'), (153, 'afficher les parametres assistant de stockage'), (153, 'modifier les parametres assistant de stockage'), (153, 'aller dans les parametres stockage'), (153, 'ouvrir options assistant de stockage'),

-- 154. open_privacy_settings
(154, 'open privacy settings'), (154, 'show privacy settings'), (154, 'go to privacy and security settings'), (154, 'change privacy and security settings'), (154, 'manage privacy settings'), (154, 'configure privacy and security'), (154, 'open privacy and security options'), (154, 'adjust privacy settings'),
(154, 'افتح اعدادات الخصوصية'), (154, 'اعدادات الخصوصية'), (154, 'اظهر اعدادات الخصوصية والامان'), (154, 'غير اعدادات الخصوصية والامان'), (154, 'اذهب الى اعدادات الخصوصية'), (154, 'ضبط الخصوصية والامان'), (154, 'تعديل اعدادات الخصوصية'),
(154, 'ouvrir les parametres confidentialite'), (154, 'parametres confidentialite'), (154, 'afficher les parametres confidentialite et securite'), (154, 'modifier les parametres confidentialite et securite'), (154, 'aller dans les parametres confidentialite'), (154, 'ouvrir options confidentialite et securite'),

-- 155. open_camera_privacy_settings
(155, 'open camera privacy settings'), (155, 'show camera privacy settings'), (155, 'go to camera permissions settings'), (155, 'change camera permissions settings'), (155, 'manage camera privacy settings'), (155, 'configure camera permissions'), (155, 'open camera permissions options'), (155, 'adjust camera privacy settings'),
(155, 'افتح اعدادات خصوصية الكاميرا'), (155, 'اعدادات خصوصية الكاميرا'), (155, 'اظهر اعدادات اذونات الكاميرا'), (155, 'غير اعدادات اذونات الكاميرا'), (155, 'اذهب الى اعدادات خصوصية الكاميرا'), (155, 'ضبط اذونات الكاميرا'), (155, 'تعديل اعدادات خصوصية الكاميرا'),
(155, 'ouvrir les parametres confidentialite camera'), (155, 'parametres confidentialite camera'), (155, 'afficher les parametres autorisations camera'), (155, 'modifier les parametres autorisations camera'), (155, 'aller dans les parametres confidentialite camera'), (155, 'ouvrir options autorisations camera'),

-- 156. open_microphone_privacy_settings
(156, 'open microphone privacy settings'), (156, 'show microphone privacy settings'), (156, 'go to microphone permissions settings'), (156, 'change microphone permissions settings'), (156, 'manage microphone privacy settings'), (156, 'configure microphone permissions'), (156, 'open microphone permissions options'), (156, 'adjust microphone privacy settings'),
(156, 'افتح اعدادات خصوصية الميكروفون'), (156, 'اعدادات خصوصية الميكروفون'), (156, 'اظهر اعدادات اذونات الميكروفون'), (156, 'غير اعدادات اذونات الميكروفون'), (156, 'اذهب الى اعدادات خصوصية الميكروفون'), (156, 'ضبط اذونات الميكروفون'), (156, 'تعديل اعدادات خصوصية الميكروفون'),
(156, 'ouvrir les parametres confidentialite micro'), (156, 'parametres confidentialite micro'), (156, 'afficher les parametres autorisations micro'), (156, 'modifier les parametres autorisations micro'), (156, 'aller dans les parametres confidentialite micro'), (156, 'ouvrir options autorisations micro'),

-- 157. open_location_privacy_settings
(157, 'open location privacy settings'), (157, 'show location privacy settings'), (157, 'go to location access settings'), (157, 'change location access settings'), (157, 'manage location privacy settings'), (157, 'configure location access'), (157, 'open location access options'), (157, 'adjust location privacy settings'),
(157, 'افتح اعدادات خصوصية الموقع'), (157, 'اعدادات خصوصية الموقع'), (157, 'اظهر اعدادات الوصول للموقع'), (157, 'غير اعدادات الوصول للموقع'), (157, 'اذهب الى اعدادات خصوصية الموقع'), (157, 'ضبط الوصول للموقع'), (157, 'تعديل اعدادات خصوصية الموقع'),
(157, 'ouvrir les parametres confidentialite localisation'), (157, 'parametres confidentialite localisation'), (157, 'afficher les parametres acces a la localisation'), (157, 'modifier les parametres acces a la localisation'), (157, 'aller dans les parametres confidentialite localisation'), (157, 'ouvrir options acces a la localisation'),

-- 158. open_notifications_settings
(158, 'open notifications settings'), (158, 'show notifications settings'), (158, 'go to alerts settings'), (158, 'change alerts settings'), (158, 'manage notifications settings'), (158, 'configure alerts'), (158, 'open alerts options'), (158, 'adjust notifications settings'),
(158, 'افتح اعدادات الاشعارات'), (158, 'اعدادات الاشعارات'), (158, 'اظهر اعدادات التنبيهات'), (158, 'غير اعدادات التنبيهات'), (158, 'اذهب الى اعدادات الاشعارات'), (158, 'ضبط التنبيهات'), (158, 'تعديل اعدادات الاشعارات'),
(158, 'ouvrir les parametres notifications'), (158, 'parametres notifications'), (158, 'afficher les parametres alertes'), (158, 'modifier les parametres alertes'), (158, 'aller dans les parametres notifications'), (158, 'ouvrir options alertes'),

-- 159. open_focus_assist_settings
(159, 'open focus assist settings'), (159, 'show focus assist settings'), (159, 'go to do not disturb settings'), (159, 'change do not disturb settings'), (159, 'manage focus assist settings'), (159, 'configure do not disturb'), (159, 'open do not disturb options'), (159, 'adjust focus assist settings'),
(159, 'افتح اعدادات المساعد التركيزي'), (159, 'اعدادات المساعد التركيزي'), (159, 'اظهر اعدادات عدم الازعاج'), (159, 'غير اعدادات عدم الازعاج'), (159, 'اذهب الى اعدادات المساعد التركيزي'), (159, 'ضبط عدم الازعاج'), (159, 'تعديل اعدادات المساعد التركيزي'),
(159, 'ouvrir les parametres assistant de concentration'), (159, 'parametres assistant de concentration'), (159, 'afficher les parametres ne pas deranger'), (159, 'modifier les parametres ne pas deranger'), (159, 'aller dans les parametres assistant de concentration'), (159, 'ouvrir options ne pas deranger'),

-- 160. open_night_light_settings
(160, 'open night light settings'), (160, 'show night light settings'), (160, 'go to blue light filter settings'), (160, 'change blue light filter settings'), (160, 'manage night light settings'), (160, 'configure blue light filter'), (160, 'open blue light filter options'), (160, 'adjust night light settings'),
(160, 'افتح اعدادات الضوء الليلي'), (160, 'اعدادات الضوء الليلي'), (160, 'اظهر اعدادات فلتر الضوء الازرق'), (160, 'غير اعدادات فلتر الضوء الازرق'), (160, 'اذهب الى اعدادات الضوء الليلي'), (160, 'ضبط فلتر الضوء الازرق'), (160, 'تعديل اعدادات الضوء الليلي'),
(160, 'ouvrir les parametres lumiere nocturne'), (160, 'parametres lumiere nocturne'), (160, 'afficher les parametres filtre lumiere bleue'), (160, 'modifier les parametres filtre lumiere bleue'), (160, 'aller dans les parametres lumiere nocturne'), (160, 'ouvrir options filtre lumiere bleue'),

-- 161. open_taskbar_settings
(161, 'open taskbar settings'), (161, 'show taskbar settings'), (161, 'go to task bar settings'), (161, 'change task bar settings'), (161, 'manage taskbar settings'), (161, 'configure task bar'), (161, 'open task bar options'), (161, 'adjust taskbar settings'),
(161, 'افتح اعدادات شريط المهام'), (161, 'اعدادات شريط المهام'), (161, 'اظهر اعدادات شريط ويندوز'), (161, 'غير اعدادات شريط ويندوز'), (161, 'اذهب الى اعدادات شريط المهام'), (161, 'ضبط شريط ويندوز'), (161, 'تعديل اعدادات شريط المهام'),
(161, 'ouvrir les parametres barre des taches'), (161, 'parametres barre des taches'), (161, 'afficher les parametres barre windows'), (161, 'modifier les parametres barre windows'), (161, 'aller dans les parametres barre des taches'), (161, 'ouvrir options barre windows'),

-- 162. open_themes_settings
(162, 'open themes settings'), (162, 'show themes settings'), (162, 'go to desktop themes settings'), (162, 'change desktop themes settings'), (162, 'manage themes settings'), (162, 'configure desktop themes'), (162, 'open desktop themes options'), (162, 'adjust themes settings'),
(162, 'افتح اعدادات السمات'), (162, 'اعدادات السمات'), (162, 'اظهر اعدادات ثيمات سطح المكتب'), (162, 'غير اعدادات ثيمات سطح المكتب'), (162, 'اذهب الى اعدادات السمات'), (162, 'ضبط ثيمات سطح المكتب'), (162, 'تعديل اعدادات السمات'),
(162, 'ouvrir les parametres themes'), (162, 'parametres themes'), (162, 'afficher les parametres themes du bureau'), (162, 'modifier les parametres themes du bureau'), (162, 'aller dans les parametres themes'), (162, 'ouvrir options themes du bureau'),

-- 163. open_colors_settings
(163, 'open colors settings'), (163, 'show colors settings'), (163, 'go to accent color settings'), (163, 'change accent color settings'), (163, 'manage colors settings'), (163, 'configure accent color'), (163, 'open accent color options'), (163, 'adjust colors settings'),
(163, 'افتح اعدادات الالوان'), (163, 'اعدادات الالوان'), (163, 'اظهر اعدادات لون التمييز'), (163, 'غير اعدادات لون التمييز'), (163, 'اذهب الى اعدادات الالوان'), (163, 'ضبط لون التمييز'), (163, 'تعديل اعدادات الالوان'),
(163, 'ouvrir les parametres couleurs'), (163, 'parametres couleurs'), (163, 'afficher les parametres couleur d accentuation'), (163, 'modifier les parametres couleur d accentuation'), (163, 'aller dans les parametres couleurs'), (163, 'ouvrir options couleur d accentuation'),

-- 164. open_wallpaper_settings
(164, 'open wallpaper settings'), (164, 'show wallpaper settings'), (164, 'go to desktop background settings'), (164, 'change desktop background settings'), (164, 'manage wallpaper settings'), (164, 'configure desktop background'), (164, 'open desktop background options'), (164, 'adjust wallpaper settings'),
(164, 'افتح اعدادات خلفية الشاشة'), (164, 'اعدادات خلفية الشاشة'), (164, 'اظهر اعدادات خلفية سطح المكتب'), (164, 'غير اعدادات خلفية سطح المكتب'), (164, 'اذهب الى اعدادات خلفية الشاشة'), (164, 'ضبط خلفية سطح المكتب'), (164, 'تعديل اعدادات خلفية الشاشة'),
(164, 'ouvrir les parametres fond d ecran'), (164, 'parametres fond d ecran'), (164, 'afficher les parametres arriere plan du bureau'), (164, 'modifier les parametres arriere plan du bureau'), (164, 'aller dans les parametres fond d ecran'), (164, 'ouvrir options arriere plan du bureau'),

-- 165. open_lock_screen_settings
(165, 'open lock screen settings'), (165, 'show lock screen settings'), (165, 'go to login screen settings'), (165, 'change login screen settings'), (165, 'manage lock screen settings'), (165, 'configure login screen'), (165, 'open login screen options'), (165, 'adjust lock screen settings'),
(165, 'افتح اعدادات شاشة القفل'), (165, 'اعدادات شاشة القفل'), (165, 'اظهر اعدادات شاشة الدخول'), (165, 'غير اعدادات شاشة الدخول'), (165, 'اذهب الى اعدادات شاشة القفل'), (165, 'ضبط شاشة الدخول'), (165, 'تعديل اعدادات شاشة القفل'),
(165, 'ouvrir les parametres ecran de verrouillage'), (165, 'parametres ecran de verrouillage'), (165, 'afficher les parametres ecran de connexion'), (165, 'modifier les parametres ecran de connexion'), (165, 'aller dans les parametres ecran de verrouillage'), (165, 'ouvrir options ecran de connexion'),

-- 166. open_fonts_settings
(166, 'open fonts settings'), (166, 'show fonts settings'), (166, 'go to typefaces settings'), (166, 'change typefaces settings'), (166, 'manage fonts settings'), (166, 'configure typefaces'), (166, 'open typefaces options'), (166, 'adjust fonts settings'),
(166, 'افتح اعدادات الخطوط'), (166, 'اعدادات الخطوط'), (166, 'اظهر اعدادات انواع الخطوط'), (166, 'غير اعدادات انواع الخطوط'), (166, 'اذهب الى اعدادات الخطوط'), (166, 'ضبط انواع الخطوط'), (166, 'تعديل اعدادات الخطوط'),
(166, 'ouvrir les parametres polices'), (166, 'parametres polices'), (166, 'afficher les parametres polices de caracteres'), (166, 'modifier les parametres polices de caracteres'), (166, 'aller dans les parametres polices'), (166, 'ouvrir options polices de caracteres'),

-- 167. open_default_apps_settings
(167, 'open default apps settings'), (167, 'show default apps settings'), (167, 'go to default programs settings'), (167, 'change default programs settings'), (167, 'manage default apps settings'), (167, 'configure default programs'), (167, 'open default programs options'), (167, 'adjust default apps settings'),
(167, 'افتح اعدادات التطبيقات الافتراضية'), (167, 'اعدادات التطبيقات الافتراضية'), (167, 'اظهر اعدادات البرامج الافتراضية'), (167, 'غير اعدادات البرامج الافتراضية'), (167, 'اذهب الى اعدادات التطبيقات الافتراضية'), (167, 'ضبط البرامج الافتراضية'), (167, 'تعديل اعدادات التطبيقات الافتراضية'),
(167, 'ouvrir les parametres applications par defaut'), (167, 'parametres applications par defaut'), (167, 'afficher les parametres programmes par defaut'), (167, 'modifier les parametres programmes par defaut'), (167, 'aller dans les parametres applications par defaut'), (167, 'ouvrir options programmes par defaut'),

-- 168. open_installed_apps_settings
(168, 'open installed apps settings'), (168, 'show installed apps settings'), (168, 'go to apps and features settings'), (168, 'change apps and features settings'), (168, 'manage installed apps settings'), (168, 'configure apps and features'), (168, 'open apps and features options'), (168, 'adjust installed apps settings'),
(168, 'افتح اعدادات التطبيقات المثبتة'), (168, 'اعدادات التطبيقات المثبتة'), (168, 'اظهر اعدادات التطبيقات والميزات'), (168, 'غير اعدادات التطبيقات والميزات'), (168, 'اذهب الى اعدادات التطبيقات المثبتة'), (168, 'ضبط التطبيقات والميزات'), (168, 'تعديل اعدادات التطبيقات المثبتة'),
(168, 'ouvrir les parametres applications installees'), (168, 'parametres applications installees'), (168, 'afficher les parametres applications et fonctionnalites'), (168, 'modifier les parametres applications et fonctionnalites'), (168, 'aller dans les parametres applications installees'), (168, 'ouvrir options applications et fonctionnalites'),

-- 169. open_startup_apps_settings
(169, 'open startup apps settings'), (169, 'show startup apps settings'), (169, 'go to autostart apps settings'), (169, 'change autostart apps settings'), (169, 'manage startup apps settings'), (169, 'configure autostart apps'), (169, 'open autostart apps options'), (169, 'adjust startup apps settings'),
(169, 'افتح اعدادات تطبيقات بدء التشغيل'), (169, 'اعدادات تطبيقات بدء التشغيل'), (169, 'اظهر اعدادات التطبيقات التلقائية'), (169, 'غير اعدادات التطبيقات التلقائية'), (169, 'اذهب الى اعدادات تطبيقات بدء التشغيل'), (169, 'ضبط التطبيقات التلقائية'), (169, 'تعديل اعدادات تطبيقات بدء التشغيل'),
(169, 'ouvrir les parametres applications au demarrage'), (169, 'parametres applications au demarrage'), (169, 'afficher les parametres applications de demarrage'), (169, 'modifier les parametres applications de demarrage'), (169, 'aller dans les parametres applications au demarrage'), (169, 'ouvrir options applications de demarrage'),

-- 170. open_windows_update_settings
(170, 'open windows update settings'), (170, 'show windows update settings'), (170, 'go to system updates settings'), (170, 'change system updates settings'), (170, 'manage windows update settings'), (170, 'configure system updates'), (170, 'open system updates options'), (170, 'adjust windows update settings'),
(170, 'افتح اعدادات تحديثات ويندوز'), (170, 'اعدادات تحديثات ويندوز'), (170, 'اظهر اعدادات تحديثات النظام'), (170, 'غير اعدادات تحديثات النظام'), (170, 'اذهب الى اعدادات تحديثات ويندوز'), (170, 'ضبط تحديثات النظام'), (170, 'تعديل اعدادات تحديثات ويندوز'),
(170, 'ouvrir les parametres mises a jour windows'), (170, 'parametres mises a jour windows'), (170, 'afficher les parametres mises a jour du systeme'), (170, 'modifier les parametres mises a jour du systeme'), (170, 'aller dans les parametres mises a jour windows'), (170, 'ouvrir options mises a jour du systeme'),

-- 171. open_recovery_settings
(171, 'open recovery settings'), (171, 'show recovery settings'), (171, 'go to reset pc settings'), (171, 'change reset pc settings'), (171, 'manage recovery settings'), (171, 'configure reset pc'), (171, 'open reset pc options'), (171, 'adjust recovery settings'),
(171, 'افتح اعدادات الاسترداد'), (171, 'اعدادات الاسترداد'), (171, 'اظهر اعدادات اعادة ضبط الجهاز'), (171, 'غير اعدادات اعادة ضبط الجهاز'), (171, 'اذهب الى اعدادات الاسترداد'), (171, 'ضبط اعادة ضبط الجهاز'), (171, 'تعديل اعدادات الاسترداد'),
(171, 'ouvrir les parametres recuperation'), (171, 'parametres recuperation'), (171, 'afficher les parametres reinitialisation du pc'), (171, 'modifier les parametres reinitialisation du pc'), (171, 'aller dans les parametres recuperation'), (171, 'ouvrir options reinitialisation du pc'),

-- 172. open_activation_settings
(172, 'open activation settings'), (172, 'show activation settings'), (172, 'go to windows activation settings'), (172, 'change windows activation settings'), (172, 'manage activation settings'), (172, 'configure windows activation'), (172, 'open windows activation options'), (172, 'adjust activation settings'),
(172, 'افتح اعدادات التنشيط'), (172, 'اعدادات التنشيط'), (172, 'اظهر اعدادات تنشيط ويندوز'), (172, 'غير اعدادات تنشيط ويندوز'), (172, 'اذهب الى اعدادات التنشيط'), (172, 'ضبط تنشيط ويندوز'), (172, 'تعديل اعدادات التنشيط'),
(172, 'ouvrir les parametres activation'), (172, 'parametres activation'), (172, 'afficher les parametres activation de windows'), (172, 'modifier les parametres activation de windows'), (172, 'aller dans les parametres activation'), (172, 'ouvrir options activation de windows'),

-- 173. open_date_and_time_settings
(173, 'open date and time settings'), (173, 'show date and time settings'), (173, 'go to clock settings'), (173, 'change clock settings'), (173, 'manage date and time settings'), (173, 'configure clock'), (173, 'open clock options'), (173, 'adjust date and time settings'),
(173, 'افتح اعدادات التاريخ والوقت'), (173, 'اعدادات التاريخ والوقت'), (173, 'اظهر اعدادات الساعة'), (173, 'غير اعدادات الساعة'), (173, 'اذهب الى اعدادات التاريخ والوقت'), (173, 'ضبط الساعة'), (173, 'تعديل اعدادات التاريخ والوقت'),
(173, 'ouvrir les parametres date et heure'), (173, 'parametres date et heure'), (173, 'afficher les parametres horloge'), (173, 'modifier les parametres horloge'), (173, 'aller dans les parametres date et heure'), (173, 'ouvrir options horloge'),

-- 174. open_language_settings
(174, 'open language settings'), (174, 'show language settings'), (174, 'go to region settings'), (174, 'change region settings'), (174, 'manage language settings'), (174, 'configure region'), (174, 'open region options'), (174, 'adjust language settings'),
(174, 'افتح اعدادات اللغة'), (174, 'اعدادات اللغة'), (174, 'اظهر اعدادات المنطقة'), (174, 'غير اعدادات المنطقة'), (174, 'اذهب الى اعدادات اللغة'), (174, 'ضبط المنطقة'), (174, 'تعديل اعدادات اللغة'),
(174, 'ouvrir les parametres langue'), (174, 'parametres langue'), (174, 'afficher les parametres region'), (174, 'modifier les parametres region'), (174, 'aller dans les parametres langue'), (174, 'ouvrir options region'),

-- 175. open_typing_settings
(175, 'open typing settings'), (175, 'show typing settings'), (175, 'go to keyboard settings'), (175, 'change keyboard settings'), (175, 'manage typing settings'), (175, 'configure keyboard'), (175, 'open keyboard options'), (175, 'adjust typing settings'),
(175, 'افتح اعدادات الكتابة'), (175, 'اعدادات الكتابة'), (175, 'اظهر اعدادات لوحة المفاتيح'), (175, 'غير اعدادات لوحة المفاتيح'), (175, 'اذهب الى اعدادات الكتابة'), (175, 'ضبط لوحة المفاتيح'), (175, 'تعديل اعدادات الكتابة'),
(175, 'ouvrir les parametres saisie'), (175, 'parametres saisie'), (175, 'afficher les parametres clavier'), (175, 'modifier les parametres clavier'), (175, 'aller dans les parametres saisie'), (175, 'ouvrir options clavier'),

-- 176. open_mouse_settings
(176, 'open mouse settings'), (176, 'show mouse settings'), (176, 'go to touchpad settings'), (176, 'change touchpad settings'), (176, 'manage mouse settings'), (176, 'configure touchpad'), (176, 'open touchpad options'), (176, 'adjust mouse settings'),
(176, 'افتح اعدادات الماوس'), (176, 'اعدادات الماوس'), (176, 'اظهر اعدادات لوحة اللمس'), (176, 'غير اعدادات لوحة اللمس'), (176, 'اذهب الى اعدادات الماوس'), (176, 'ضبط لوحة اللمس'), (176, 'تعديل اعدادات الماوس'),
(176, 'ouvrir les parametres souris'), (176, 'parametres souris'), (176, 'afficher les parametres pave tactile'), (176, 'modifier les parametres pave tactile'), (176, 'aller dans les parametres souris'), (176, 'ouvrir options pave tactile'),

-- 177. open_accessibility_settings
(177, 'open accessibility settings'), (177, 'show accessibility settings'), (177, 'go to ease of access settings'), (177, 'change ease of access settings'), (177, 'manage accessibility settings'), (177, 'configure ease of access'), (177, 'open ease of access options'), (177, 'adjust accessibility settings'),
(177, 'افتح اعدادات سهولة الوصول'), (177, 'اعدادات سهولة الوصول'), (177, 'اظهر اعدادات امكانية الوصول'), (177, 'غير اعدادات امكانية الوصول'), (177, 'اذهب الى اعدادات سهولة الوصول'), (177, 'ضبط امكانية الوصول'), (177, 'تعديل اعدادات سهولة الوصول'),
(177, 'ouvrir les parametres accessibilite'), (177, 'parametres accessibilite'), (177, 'afficher les parametres facilite d acces'), (177, 'modifier les parametres facilite d acces'), (177, 'aller dans les parametres accessibilite'), (177, 'ouvrir options facilite d acces'),

-- 178. open_high_contrast_settings
(178, 'open high contrast settings'), (178, 'show high contrast settings'), (178, 'go to contrast themes settings'), (178, 'change contrast themes settings'), (178, 'manage high contrast settings'), (178, 'configure contrast themes'), (178, 'open contrast themes options'), (178, 'adjust high contrast settings'),
(178, 'افتح اعدادات التباين العالي'), (178, 'اعدادات التباين العالي'), (178, 'اظهر اعدادات سمات التباين'), (178, 'غير اعدادات سمات التباين'), (178, 'اذهب الى اعدادات التباين العالي'), (178, 'ضبط سمات التباين'), (178, 'تعديل اعدادات التباين العالي'),
(178, 'ouvrir les parametres contraste eleve'), (178, 'parametres contraste eleve'), (178, 'afficher les parametres themes de contraste'), (178, 'modifier les parametres themes de contraste'), (178, 'aller dans les parametres contraste eleve'), (178, 'ouvrir options themes de contraste'),

-- 179. open_game_bar_settings
(179, 'open game bar settings'), (179, 'show game bar settings'), (179, 'go to xbox game bar settings'), (179, 'change xbox game bar settings'), (179, 'manage game bar settings'), (179, 'configure xbox game bar'), (179, 'open xbox game bar options'), (179, 'adjust game bar settings'),
(179, 'افتح اعدادات شريط الالعاب'), (179, 'اعدادات شريط الالعاب'), (179, 'اظهر اعدادات شريط اكس بوكس'), (179, 'غير اعدادات شريط اكس بوكس'), (179, 'اذهب الى اعدادات شريط الالعاب'), (179, 'ضبط شريط اكس بوكس'), (179, 'تعديل اعدادات شريط الالعاب'),
(179, 'ouvrir les parametres barre de jeu'), (179, 'parametres barre de jeu'), (179, 'afficher les parametres barre xbox'), (179, 'modifier les parametres barre xbox'), (179, 'aller dans les parametres barre de jeu'), (179, 'ouvrir options barre xbox'),

-- 180. open_game_mode_settings
(180, 'open game mode settings'), (180, 'show game mode settings'), (180, 'go to gaming mode settings'), (180, 'change gaming mode settings'), (180, 'manage game mode settings'), (180, 'configure gaming mode'), (180, 'open gaming mode options'), (180, 'adjust game mode settings'),
(180, 'افتح اعدادات وضع الالعاب'), (180, 'اعدادات وضع الالعاب'), (180, 'اظهر اعدادات وضع اللعب'), (180, 'غير اعدادات وضع اللعب'), (180, 'اذهب الى اعدادات وضع الالعاب'), (180, 'ضبط وضع اللعب'), (180, 'تعديل اعدادات وضع الالعاب'),
(180, 'ouvrir les parametres mode jeu'), (180, 'parametres mode jeu'), (180, 'afficher les parametres mode gaming'), (180, 'modifier les parametres mode gaming'), (180, 'aller dans les parametres mode jeu'), (180, 'ouvrir options mode gaming'),

-- 181. open_clipboard_settings
(181, 'open clipboard settings'), (181, 'show clipboard settings'), (181, 'go to clipboard history settings'), (181, 'change clipboard history settings'), (181, 'manage clipboard settings'), (181, 'configure clipboard history'), (181, 'open clipboard history options'), (181, 'adjust clipboard settings'),
(181, 'افتح اعدادات الحافظة'), (181, 'اعدادات الحافظة'), (181, 'اظهر اعدادات سجل الحافظة'), (181, 'غير اعدادات سجل الحافظة'), (181, 'اذهب الى اعدادات الحافظة'), (181, 'ضبط سجل الحافظة'), (181, 'تعديل اعدادات الحافظة'),
(181, 'ouvrir les parametres presse papiers'), (181, 'parametres presse papiers'), (181, 'afficher les parametres historique du presse papiers'), (181, 'modifier les parametres historique du presse papiers'), (181, 'aller dans les parametres presse papiers'), (181, 'ouvrir options historique du presse papiers'),

-- 182. open_airplane_mode_settings
(182, 'open airplane mode settings'), (182, 'show airplane mode settings'), (182, 'go to flight mode settings'), (182, 'change flight mode settings'), (182, 'manage airplane mode settings'), (182, 'configure flight mode'), (182, 'open flight mode options'), (182, 'adjust airplane mode settings'),
(182, 'افتح اعدادات وضع الطيران'), (182, 'اعدادات وضع الطيران'), (182, 'اظهر اعدادات وضع الرحلة'), (182, 'غير اعدادات وضع الرحلة'), (182, 'اذهب الى اعدادات وضع الطيران'), (182, 'ضبط وضع الرحلة'), (182, 'تعديل اعدادات وضع الطيران'),
(182, 'ouvrir les parametres mode avion'), (182, 'parametres mode avion'), (182, 'afficher les parametres mode vol'), (182, 'modifier les parametres mode vol'), (182, 'aller dans les parametres mode avion'), (182, 'ouvrir options mode vol'),

-- 183. open_mobile_hotspot_settings
(183, 'open mobile hotspot settings'), (183, 'show mobile hotspot settings'), (183, 'go to wifi hotspot settings'), (183, 'change wifi hotspot settings'), (183, 'manage mobile hotspot settings'), (183, 'configure wifi hotspot'), (183, 'open wifi hotspot options'), (183, 'adjust mobile hotspot settings'),
(183, 'افتح اعدادات نقطة الاتصال'), (183, 'اعدادات نقطة الاتصال'), (183, 'اظهر اعدادات الهوت سبوت'), (183, 'غير اعدادات الهوت سبوت'), (183, 'اذهب الى اعدادات نقطة الاتصال'), (183, 'ضبط الهوت سبوت'), (183, 'تعديل اعدادات نقطة الاتصال'),
(183, 'ouvrir les parametres point d acces mobile'), (183, 'parametres point d acces mobile'), (183, 'afficher les parametres hotspot wifi'), (183, 'modifier les parametres hotspot wifi'), (183, 'aller dans les parametres point d acces mobile'), (183, 'ouvrir options hotspot wifi'),

-- 184. open_ethernet_settings
(184, 'open ethernet settings'), (184, 'show ethernet settings'), (184, 'go to wired network settings'), (184, 'change wired network settings'), (184, 'manage ethernet settings'), (184, 'configure wired network'), (184, 'open wired network options'), (184, 'adjust ethernet settings'),
(184, 'افتح اعدادات الايثرنت'), (184, 'اعدادات الايثرنت'), (184, 'اظهر اعدادات الشبكة السلكية'), (184, 'غير اعدادات الشبكة السلكية'), (184, 'اذهب الى اعدادات الايثرنت'), (184, 'ضبط الشبكة السلكية'), (184, 'تعديل اعدادات الايثرنت'),
(184, 'ouvrir les parametres ethernet'), (184, 'parametres ethernet'), (184, 'afficher les parametres reseau filaire'), (184, 'modifier les parametres reseau filaire'), (184, 'aller dans les parametres ethernet'), (184, 'ouvrir options reseau filaire'),

-- 185. open_sign_in_options_settings
(185, 'open sign in options settings'), (185, 'show sign in options settings'), (185, 'go to password options settings'), (185, 'change password options settings'), (185, 'manage sign in options settings'), (185, 'configure password options'), (185, 'open password options options'), (185, 'adjust sign in options settings'),
(185, 'افتح اعدادات خيارات تسجيل الدخول'), (185, 'اعدادات خيارات تسجيل الدخول'), (185, 'اظهر اعدادات خيارات كلمة المرور'), (185, 'غير اعدادات خيارات كلمة المرور'), (185, 'اذهب الى اعدادات خيارات تسجيل الدخول'), (185, 'ضبط خيارات كلمة المرور'), (185, 'تعديل اعدادات خيارات تسجيل الدخول'),
(185, 'ouvrir les parametres options de connexion'), (185, 'parametres options de connexion'), (185, 'afficher les parametres options de mot de passe'), (185, 'modifier les parametres options de mot de passe'), (185, 'aller dans les parametres options de connexion'), (185, 'ouvrir options options de mot de passe'),

-- 186. open_backup_settings
(186, 'open backup settings'), (186, 'show backup settings'), (186, 'go to file backup settings'), (186, 'change file backup settings'), (186, 'manage backup settings'), (186, 'configure file backup'), (186, 'open file backup options'), (186, 'adjust backup settings'),
(186, 'افتح اعدادات النسخ الاحتياطي'), (186, 'اعدادات النسخ الاحتياطي'), (186, 'اظهر اعدادات نسخ الملفات'), (186, 'غير اعدادات نسخ الملفات'), (186, 'اذهب الى اعدادات النسخ الاحتياطي'), (186, 'ضبط نسخ الملفات'), (186, 'تعديل اعدادات النسخ الاحتياطي'),
(186, 'ouvrir les parametres sauvegarde'), (186, 'parametres sauvegarde'), (186, 'afficher les parametres sauvegarde de fichiers'), (186, 'modifier les parametres sauvegarde de fichiers'), (186, 'aller dans les parametres sauvegarde'), (186, 'ouvrir options sauvegarde de fichiers'),

-- 187. open_windows_security_settings
(187, 'open windows security settings'), (187, 'show windows security settings'), (187, 'go to defender settings'), (187, 'change defender settings'), (187, 'manage windows security settings'), (187, 'configure defender'), (187, 'open defender options'), (187, 'adjust windows security settings'),
(187, 'افتح اعدادات امان ويندوز'), (187, 'اعدادات امان ويندوز'), (187, 'اظهر اعدادات الديفندر'), (187, 'غير اعدادات الديفندر'), (187, 'اذهب الى اعدادات امان ويندوز'), (187, 'ضبط الديفندر'), (187, 'تعديل اعدادات امان ويندوز'),
(187, 'ouvrir les parametres securite windows'), (187, 'parametres securite windows'), (187, 'afficher les parametres defender'), (187, 'modifier les parametres defender'), (187, 'aller dans les parametres securite windows'), (187, 'ouvrir options defender'),

-- 188. open_printers_settings
(188, 'open printers settings'), (188, 'show printers settings'), (188, 'go to printers and scanners settings'), (188, 'change printers and scanners settings'), (188, 'manage printers settings'), (188, 'configure printers and scanners'), (188, 'open printers and scanners options'), (188, 'adjust printers settings'),
(188, 'افتح اعدادات الطابعات'), (188, 'اعدادات الطابعات'), (188, 'اظهر اعدادات الطابعات والماسحات'), (188, 'غير اعدادات الطابعات والماسحات'), (188, 'اذهب الى اعدادات الطابعات'), (188, 'ضبط الطابعات والماسحات'), (188, 'تعديل اعدادات الطابعات'),
(188, 'ouvrir les parametres imprimantes'), (188, 'parametres imprimantes'), (188, 'afficher les parametres imprimantes et scanners'), (188, 'modifier les parametres imprimantes et scanners'), (188, 'aller dans les parametres imprimantes'), (188, 'ouvrir options imprimantes et scanners'),

-- 189. open_sleep_settings
(189, 'open sleep settings'), (189, 'show sleep settings'), (189, 'go to screen timeout settings'), (189, 'change screen timeout settings'), (189, 'manage sleep settings'), (189, 'configure screen timeout'), (189, 'open screen timeout options'), (189, 'adjust sleep settings'),
(189, 'افتح اعدادات السكون'), (189, 'اعدادات السكون'), (189, 'اظهر اعدادات مهلة الشاشة'), (189, 'غير اعدادات مهلة الشاشة'), (189, 'اذهب الى اعدادات السكون'), (189, 'ضبط مهلة الشاشة'), (189, 'تعديل اعدادات السكون'),
(189, 'ouvrir les parametres veille'), (189, 'parametres veille'), (189, 'afficher les parametres extinction de l ecran'), (189, 'modifier les parametres extinction de l ecran'), (189, 'aller dans les parametres veille'), (189, 'ouvrir options extinction de l ecran'),

-- 190. open_account_info_settings
(190, 'open account info settings'), (190, 'show account info settings'), (190, 'go to my account settings'), (190, 'change my account settings'), (190, 'manage account info settings'), (190, 'configure my account'), (190, 'open my account options'), (190, 'adjust account info settings'),
(190, 'افتح اعدادات معلومات الحساب'), (190, 'اعدادات معلومات الحساب'), (190, 'اظهر اعدادات حسابي'), (190, 'غير اعدادات حسابي'), (190, 'اذهب الى اعدادات معلومات الحساب'), (190, 'ضبط حسابي'), (190, 'تعديل اعدادات معلومات الحساب'),
(190, 'ouvrir les parametres informations du compte'), (190, 'parametres informations du compte'), (190, 'afficher les parametres mon compte'), (190, 'modifier les parametres mon compte'), (190, 'aller dans les parametres informations du compte'), (190, 'ouvrir options mon compte'),

-- 191. open_pictures_folder
(191, 'open pictures folder'), (191, 'show pictures folder'), (191, 'go to photos folder'), (191, 'browse photos folder'), (191, 'open my pictures'), (191, 'view pictures files'), (191, 'show me photos files'), (191, 'pictures folder'),
(191, 'افتح مجلد الصور'), (191, 'اظهر مجلد الصور'), (191, 'اذهب الى مجلد صور الجهاز'), (191, 'عرض ملفات صور الجهاز'), (191, 'مجلد الصور'), (191, 'تصفح مجلد صور الجهاز'), (191, 'افتح صور الجهاز'),
(191, 'ouvrir le dossier images'), (191, 'afficher le dossier images'), (191, 'aller au dossier photos'), (191, 'voir les fichiers photos'), (191, 'dossier images'), (191, 'parcourir le dossier photos'),

-- 192. open_music_folder
(192, 'open music folder'), (192, 'show music folder'), (192, 'go to songs folder'), (192, 'browse songs folder'), (192, 'open my music'), (192, 'view music files'), (192, 'show me songs files'), (192, 'music folder'),
(192, 'افتح مجلد الموسيقى'), (192, 'اظهر مجلد الموسيقى'), (192, 'اذهب الى مجلد الاغاني'), (192, 'عرض ملفات الاغاني'), (192, 'مجلد الموسيقى'), (192, 'تصفح مجلد الاغاني'), (192, 'افتح الاغاني'),
(192, 'ouvrir le dossier musique'), (192, 'afficher le dossier musique'), (192, 'aller au dossier chansons'), (192, 'voir les fichiers chansons'), (192, 'dossier musique'), (192, 'parcourir le dossier chansons'),

-- 193. open_videos_folder
(193, 'open videos folder'), (193, 'show videos folder'), (193, 'go to movies folder'), (193, 'browse movies folder'), (193, 'open my videos'), (193, 'view videos files'), (193, 'show me movies files'), (193, 'videos folder'),
(193, 'افتح مجلد الفيديوهات'), (193, 'اظهر مجلد الفيديوهات'), (193, 'اذهب الى مجلد الافلام'), (193, 'عرض ملفات الافلام'), (193, 'مجلد الفيديوهات'), (193, 'تصفح مجلد الافلام'), (193, 'افتح الافلام'),
(193, 'ouvrir le dossier videos'), (193, 'afficher le dossier videos'), (193, 'aller au dossier films'), (193, 'voir les fichiers films'), (193, 'dossier videos'), (193, 'parcourir le dossier films'),

-- 194. open_appdata_folder
(194, 'open appdata folder'), (194, 'show appdata folder'), (194, 'go to app data folder'), (194, 'browse app data folder'), (194, 'open my appdata'), (194, 'view appdata files'), (194, 'show me app data files'), (194, 'appdata folder'),
(194, 'افتح مجلد بيانات التطبيقات'), (194, 'اظهر مجلد بيانات التطبيقات'), (194, 'اذهب الى مجلد اب داتا'), (194, 'عرض ملفات اب داتا'), (194, 'مجلد بيانات التطبيقات'), (194, 'تصفح مجلد اب داتا'), (194, 'افتح اب داتا'),
(194, 'ouvrir le dossier donnees d application'), (194, 'afficher le dossier donnees d application'), (194, 'aller au dossier appdata'), (194, 'voir les fichiers appdata'), (194, 'dossier donnees d application'), (194, 'parcourir le dossier appdata'),

-- 195. open_temp_folder
(195, 'open temp folder'), (195, 'show temp folder'), (195, 'go to temp files folder'), (195, 'browse temp files folder'), (195, 'open my temp'), (195, 'view temp files'), (195, 'show me temp files files'), (195, 'temp folder'),
(195, 'افتح مجلد تيمب'), (195, 'اظهر مجلد تيمب'), (195, 'اذهب الى مجلد التيمب'), (195, 'عرض ملفات التيمب'), (195, 'مجلد تيمب'), (195, 'تصفح مجلد التيمب'), (195, 'افتح التيمب'),
(195, 'ouvrir le dossier temp'), (195, 'afficher le dossier temp'), (195, 'aller au dossier fichiers temp'), (195, 'voir les fichiers fichiers temp'), (195, 'dossier temp'), (195, 'parcourir le dossier fichiers temp'),

-- 196. open_startup_folder
(196, 'open startup folder'), (196, 'show startup folder'), (196, 'go to autostart folder'), (196, 'browse autostart folder'), (196, 'open my startup'), (196, 'view startup files'), (196, 'show me autostart files'), (196, 'startup folder'),
(196, 'افتح مجلد بدء التشغيل'), (196, 'اظهر مجلد بدء التشغيل'), (196, 'اذهب الى مجلد التشغيل التلقائي'), (196, 'عرض ملفات التشغيل التلقائي'), (196, 'مجلد بدء التشغيل'), (196, 'تصفح مجلد التشغيل التلقائي'), (196, 'افتح التشغيل التلقائي'),
(196, 'ouvrir le dossier demarrage'), (196, 'afficher le dossier demarrage'), (196, 'aller au dossier demarrage automatique'), (196, 'voir les fichiers demarrage automatique'), (196, 'dossier demarrage'), (196, 'parcourir le dossier demarrage automatique'),

-- 197. open_program_files_folder
(197, 'open program files folder'), (197, 'show program files folder'), (197, 'go to programs directory folder'), (197, 'browse programs directory folder'), (197, 'open my program files'), (197, 'view program files files'), (197, 'show me programs directory files'), (197, 'program files folder'),
(197, 'افتح مجلد ملفات البرامج'), (197, 'اظهر مجلد ملفات البرامج'), (197, 'اذهب الى مجلد مجلد البرامج'), (197, 'عرض ملفات مجلد البرامج'), (197, 'مجلد ملفات البرامج'), (197, 'تصفح مجلد مجلد البرامج'), (197, 'افتح مجلد البرامج'),
(197, 'ouvrir le dossier program files'), (197, 'afficher le dossier program files'), (197, 'aller au dossier repertoire des programmes'), (197, 'voir les fichiers repertoire des programmes'), (197, 'dossier program files'), (197, 'parcourir le dossier repertoire des programmes'),

-- 198. open_windows_folder
(198, 'open windows folder'), (198, 'show windows folder'), (198, 'go to windows directory folder'), (198, 'browse windows directory folder'), (198, 'open my windows'), (198, 'view windows files'), (198, 'show me windows directory files'), (198, 'windows folder'),
(198, 'افتح مجلد ويندوز'), (198, 'اظهر مجلد ويندوز'), (198, 'اذهب الى مجلد مجلد النظام'), (198, 'عرض ملفات مجلد النظام'), (198, 'مجلد ويندوز'), (198, 'تصفح مجلد مجلد النظام'), (198, 'افتح مجلد النظام'),
(198, 'ouvrir le dossier windows'), (198, 'afficher le dossier windows'), (198, 'aller au dossier repertoire windows'), (198, 'voir les fichiers repertoire windows'), (198, 'dossier windows'), (198, 'parcourir le dossier repertoire windows'),

-- 199. open_system32_folder
(199, 'open system32 folder'), (199, 'show system32 folder'), (199, 'go to system 32 folder'), (199, 'browse system 32 folder'), (199, 'open my system32'), (199, 'view system32 files'), (199, 'show me system 32 files'), (199, 'system32 folder'),
(199, 'افتح مجلد سيستم 32'), (199, 'اظهر مجلد سيستم 32'), (199, 'اذهب الى مجلد نظام 32'), (199, 'عرض ملفات نظام 32'), (199, 'مجلد سيستم 32'), (199, 'تصفح مجلد نظام 32'), (199, 'افتح نظام 32'),
(199, 'ouvrir le dossier system32'), (199, 'afficher le dossier system32'), (199, 'aller au dossier system 32'), (199, 'voir les fichiers system 32'), (199, 'dossier system32'), (199, 'parcourir le dossier system 32'),

-- 200. open_user_profile_folder
(200, 'open user profile folder'), (200, 'show user profile folder'), (200, 'go to home folder'), (200, 'browse home folder'), (200, 'open my user profile'), (200, 'view user profile files'), (200, 'show me home files'), (200, 'user profile folder'),
(200, 'افتح مجلد ملف المستخدم'), (200, 'اظهر مجلد ملف المستخدم'), (200, 'اذهب الى مجلد المجلد الشخصي'), (200, 'عرض ملفات المجلد الشخصي'), (200, 'مجلد ملف المستخدم'), (200, 'تصفح مجلد المجلد الشخصي'), (200, 'افتح المجلد الشخصي'),
(200, 'ouvrir le dossier profil utilisateur'), (200, 'afficher le dossier profil utilisateur'), (200, 'aller au dossier dossier personnel'), (200, 'voir les fichiers dossier personnel'), (200, 'dossier profil utilisateur'), (200, 'parcourir le dossier dossier personnel'),

-- 201. open_public_folder
(201, 'open public folder'), (201, 'show public folder'), (201, 'go to shared folder'), (201, 'browse shared folder'), (201, 'open my public'), (201, 'view public files'), (201, 'show me shared files'), (201, 'public folder'),
(201, 'افتح مجلد العام'), (201, 'اظهر مجلد العام'), (201, 'اذهب الى مجلد المشترك'), (201, 'عرض ملفات المشترك'), (201, 'مجلد العام'), (201, 'تصفح مجلد المشترك'), (201, 'افتح المشترك'),
(201, 'ouvrir le dossier public'), (201, 'afficher le dossier public'), (201, 'aller au dossier partage'), (201, 'voir les fichiers partage'), (201, 'dossier public'), (201, 'parcourir le dossier partage'),

-- 202. open_recent_folder
(202, 'open recent folder'), (202, 'show recent folder'), (202, 'go to latest folder'), (202, 'browse latest folder'), (202, 'open my recent'), (202, 'view recent files'), (202, 'show me latest files'), (202, 'recent folder'),
(202, 'افتح مجلد الاخيرة'), (202, 'اظهر مجلد الاخيرة'), (202, 'اذهب الى مجلد الحديثة'), (202, 'عرض ملفات الحديثة'), (202, 'مجلد الاخيرة'), (202, 'تصفح مجلد الحديثة'), (202, 'افتح الحديثة'),
(202, 'ouvrir le dossier recents'), (202, 'afficher le dossier recents'), (202, 'aller au dossier derniers'), (202, 'voir les fichiers derniers'), (202, 'dossier recents'), (202, 'parcourir le dossier derniers'),

-- 203. open_screenshots_folder
(203, 'open screenshots folder'), (203, 'show screenshots folder'), (203, 'go to screen captures folder'), (203, 'browse screen captures folder'), (203, 'open my screenshots'), (203, 'view screenshots files'), (203, 'show me screen captures files'), (203, 'screenshots folder'),
(203, 'افتح مجلد لقطات الشاشة'), (203, 'اظهر مجلد لقطات الشاشة'), (203, 'اذهب الى مجلد صور الشاشة'), (203, 'عرض ملفات صور الشاشة'), (203, 'مجلد لقطات الشاشة'), (203, 'تصفح مجلد صور الشاشة'), (203, 'افتح صور الشاشة'),
(203, 'ouvrir le dossier captures d ecran'), (203, 'afficher le dossier captures d ecran'), (203, 'aller au dossier copies d ecran'), (203, 'voir les fichiers copies d ecran'), (203, 'dossier captures d ecran'), (203, 'parcourir le dossier copies d ecran'),

-- 204. open_onedrive_folder
(204, 'open onedrive folder'), (204, 'show onedrive folder'), (204, 'go to cloud sync folder'), (204, 'browse cloud sync folder'), (204, 'open my onedrive'), (204, 'view onedrive files'), (204, 'show me cloud sync files'), (204, 'onedrive folder'),
(204, 'افتح مجلد ون درايف'), (204, 'اظهر مجلد ون درايف'), (204, 'اذهب الى مجلد السحابة'), (204, 'عرض ملفات السحابة'), (204, 'مجلد ون درايف'), (204, 'تصفح مجلد السحابة'), (204, 'افتح السحابة'),
(204, 'ouvrir le dossier onedrive'), (204, 'afficher le dossier onedrive'), (204, 'aller au dossier cloud'), (204, 'voir les fichiers cloud'), (204, 'dossier onedrive'), (204, 'parcourir le dossier cloud'),

-- 205. open_trash_folder
(205, 'open trash folder'), (205, 'show trash folder'), (205, 'go to deleted files folder'), (205, 'browse deleted files folder'), (205, 'open my trash'), (205, 'view trash files'), (205, 'show me deleted files files'), (205, 'trash folder'),
(205, 'افتح مجلد المحذوفات'), (205, 'اظهر مجلد المحذوفات'), (205, 'اذهب الى مجلد الملفات المحذوفة'), (205, 'عرض ملفات الملفات المحذوفة'), (205, 'مجلد المحذوفات'), (205, 'تصفح مجلد الملفات المحذوفة'), (205, 'افتح الملفات المحذوفة'),
(205, 'ouvrir le dossier corbeille'), (205, 'afficher le dossier corbeille'), (205, 'aller au dossier fichiers supprimes'), (205, 'voir les fichiers fichiers supprimes'), (205, 'dossier corbeille'), (205, 'parcourir le dossier fichiers supprimes'),

-- 206. show_computer_name
(206, 'show computer name'), (206, 'display computer name'), (206, 'view computer name'), (206, 'get computer name'), (206, 'check pc name'), (206, 'give me pc name'), (206, 'tell me pc name'), (206, 'pc name'),
(206, 'اعرض اسم الكمبيوتر'), (206, 'اظهر اسم الكمبيوتر'), (206, 'عرض اسم الكمبيوتر'), (206, 'اعطني اسم الجهاز'), (206, 'افحص اسم الجهاز'), (206, 'اريد معرفة اسم الجهاز'), (206, 'هات اسم الجهاز'),
(206, 'afficher le nom de l ordinateur'), (206, 'voir le nom de l ordinateur'), (206, 'montrer le nom de l ordinateur'), (206, 'donne moi le nom du pc'), (206, 'verifier le nom du pc'), (206, 'je veux voir le nom du pc'),

-- 207. show_current_user
(207, 'show current user'), (207, 'display current user'), (207, 'view current user'), (207, 'get current user'), (207, 'check my username'), (207, 'give me my username'), (207, 'tell me my username'), (207, 'my username'),
(207, 'اعرض المستخدم الحالي'), (207, 'اظهر المستخدم الحالي'), (207, 'عرض المستخدم الحالي'), (207, 'اعطني اسم المستخدم'), (207, 'افحص اسم المستخدم'), (207, 'اريد معرفة اسم المستخدم'), (207, 'هات اسم المستخدم'),
(207, 'afficher l utilisateur actuel'), (207, 'voir l utilisateur actuel'), (207, 'montrer l utilisateur actuel'), (207, 'donne moi mon nom d utilisateur'), (207, 'verifier mon nom d utilisateur'), (207, 'je veux voir mon nom d utilisateur'),

-- 208. show_windows_version
(208, 'show windows version'), (208, 'display windows version'), (208, 'view windows version'), (208, 'get windows version'), (208, 'check os version'), (208, 'give me os version'), (208, 'tell me os version'), (208, 'os version'),
(208, 'اعرض اصدار ويندوز'), (208, 'اظهر اصدار ويندوز'), (208, 'عرض اصدار ويندوز'), (208, 'اعطني نسخة النظام'), (208, 'افحص نسخة النظام'), (208, 'اريد معرفة نسخة النظام'), (208, 'هات نسخة النظام'),
(208, 'afficher la version de windows'), (208, 'voir la version de windows'), (208, 'montrer la version de windows'), (208, 'donne moi la version du systeme'), (208, 'verifier la version du systeme'), (208, 'je veux voir la version du systeme'),

-- 209. show_current_date
(209, 'show current date'), (209, 'display current date'), (209, 'view current date'), (209, 'get current date'), (209, 'check today date'), (209, 'give me today date'), (209, 'tell me today date'), (209, 'today date'),
(209, 'اعرض تاريخ اليوم'), (209, 'اظهر تاريخ اليوم'), (209, 'عرض تاريخ اليوم'), (209, 'اعطني التاريخ الحالي'), (209, 'افحص التاريخ الحالي'), (209, 'اريد معرفة التاريخ الحالي'), (209, 'هات التاريخ الحالي'),
(209, 'afficher la date du jour'), (209, 'voir la date du jour'), (209, 'montrer la date du jour'), (209, 'donne moi la date actuelle'), (209, 'verifier la date actuelle'), (209, 'je veux voir la date actuelle'),

-- 210. show_current_time
(210, 'show current time'), (210, 'display current time'), (210, 'view current time'), (210, 'get current time'), (210, 'check time now'), (210, 'give me time now'), (210, 'tell me time now'), (210, 'time now'),
(210, 'اعرض الوقت الحالي'), (210, 'اظهر الوقت الحالي'), (210, 'عرض الوقت الحالي'), (210, 'اعطني الساعة الان'), (210, 'افحص الساعة الان'), (210, 'اريد معرفة الساعة الان'), (210, 'هات الساعة الان'),
(210, 'afficher l heure actuelle'), (210, 'voir l heure actuelle'), (210, 'montrer l heure actuelle'), (210, 'donne moi l heure'), (210, 'verifier l heure'), (210, 'je veux voir l heure'),

-- 211. show_running_processes
(211, 'show running processes'), (211, 'display running processes'), (211, 'view running processes'), (211, 'get running processes'), (211, 'check process list'), (211, 'give me process list'), (211, 'tell me process list'), (211, 'process list'),
(211, 'اعرض العمليات الجارية'), (211, 'اظهر العمليات الجارية'), (211, 'عرض العمليات الجارية'), (211, 'اعطني قائمة العمليات'), (211, 'افحص قائمة العمليات'), (211, 'اريد معرفة قائمة العمليات'), (211, 'هات قائمة العمليات'),
(211, 'afficher les processus en cours'), (211, 'voir les processus en cours'), (211, 'montrer les processus en cours'), (211, 'donne moi la liste des processus'), (211, 'verifier la liste des processus'), (211, 'je veux voir la liste des processus'),

-- 212. show_processor_name
(212, 'show processor name'), (212, 'display processor name'), (212, 'view processor name'), (212, 'get processor name'), (212, 'check cpu model'), (212, 'give me cpu model'), (212, 'tell me cpu model'), (212, 'cpu model'),
(212, 'اعرض اسم المعالج'), (212, 'اظهر اسم المعالج'), (212, 'عرض اسم المعالج'), (212, 'اعطني نوع المعالج'), (212, 'افحص نوع المعالج'), (212, 'اريد معرفة نوع المعالج'), (212, 'هات نوع المعالج'),
(212, 'afficher le nom du processeur'), (212, 'voir le nom du processeur'), (212, 'montrer le nom du processeur'), (212, 'donne moi le modele du processeur'), (212, 'verifier le modele du processeur'), (212, 'je veux voir le modele du processeur'),

-- 213. show_total_ram
(213, 'show total ram'), (213, 'display total ram'), (213, 'view total ram'), (213, 'get total ram'), (213, 'check memory size'), (213, 'give me memory size'), (213, 'tell me memory size'), (213, 'memory size'),
(213, 'اعرض حجم الرام'), (213, 'اظهر حجم الرام'), (213, 'عرض حجم الرام'), (213, 'اعطني حجم الذاكرة'), (213, 'افحص حجم الذاكرة'), (213, 'اريد معرفة حجم الذاكرة'), (213, 'هات حجم الذاكرة'),
(213, 'afficher la taille de la ram'), (213, 'voir la taille de la ram'), (213, 'montrer la taille de la ram'), (213, 'donne moi la memoire installee'), (213, 'verifier la memoire installee'), (213, 'je veux voir la memoire installee'),

-- 214. show_disk_space
(214, 'show disk space'), (214, 'display disk space'), (214, 'view disk space'), (214, 'get disk space'), (214, 'check free storage'), (214, 'give me free storage'), (214, 'tell me free storage'), (214, 'free storage'),
(214, 'اعرض المساحة الفارغة'), (214, 'اظهر المساحة الفارغة'), (214, 'عرض المساحة الفارغة'), (214, 'اعطني مساحة الاقراص'), (214, 'افحص مساحة الاقراص'), (214, 'اريد معرفة مساحة الاقراص'), (214, 'هات مساحة الاقراص'),
(214, 'afficher l espace disque'), (214, 'voir l espace disque'), (214, 'montrer l espace disque'), (214, 'donne moi l espace libre'), (214, 'verifier l espace libre'), (214, 'je veux voir l espace libre'),

-- 215. show_graphics_card
(215, 'show graphics card'), (215, 'display graphics card'), (215, 'view graphics card'), (215, 'get graphics card'), (215, 'check gpu name'), (215, 'give me gpu name'), (215, 'tell me gpu name'), (215, 'gpu name'),
(215, 'اعرض كرت الشاشة'), (215, 'اظهر كرت الشاشة'), (215, 'عرض كرت الشاشة'), (215, 'اعطني اسم كرت الشاشة'), (215, 'افحص اسم كرت الشاشة'), (215, 'اريد معرفة اسم كرت الشاشة'), (215, 'هات اسم كرت الشاشة'),
(215, 'afficher la carte graphique'), (215, 'voir la carte graphique'), (215, 'montrer la carte graphique'), (215, 'donne moi le nom du gpu'), (215, 'verifier le nom du gpu'), (215, 'je veux voir le nom du gpu'),

-- 216. show_battery_level
(216, 'show battery level'), (216, 'display battery level'), (216, 'view battery level'), (216, 'get battery level'), (216, 'check battery percentage'), (216, 'give me battery percentage'), (216, 'tell me battery percentage'), (216, 'battery percentage'),
(216, 'اعرض نسبة البطارية'), (216, 'اظهر نسبة البطارية'), (216, 'عرض نسبة البطارية'), (216, 'اعطني مستوى البطارية'), (216, 'افحص مستوى البطارية'), (216, 'اريد معرفة مستوى البطارية'), (216, 'هات مستوى البطارية'),
(216, 'afficher le niveau de batterie'), (216, 'voir le niveau de batterie'), (216, 'montrer le niveau de batterie'), (216, 'donne moi le pourcentage de batterie'), (216, 'verifier le pourcentage de batterie'), (216, 'je veux voir le pourcentage de batterie'),

-- 217. show_system_uptime
(217, 'show system uptime'), (217, 'display system uptime'), (217, 'view system uptime'), (217, 'get system uptime'), (217, 'check pc uptime'), (217, 'give me pc uptime'), (217, 'tell me pc uptime'), (217, 'pc uptime'),
(217, 'اعرض مدة تشغيل الجهاز'), (217, 'اظهر مدة تشغيل الجهاز'), (217, 'عرض مدة تشغيل الجهاز'), (217, 'اعطني وقت التشغيل'), (217, 'افحص وقت التشغيل'), (217, 'اريد معرفة وقت التشغيل'), (217, 'هات وقت التشغيل'),
(217, 'afficher la duree de fonctionnement'), (217, 'voir la duree de fonctionnement'), (217, 'montrer la duree de fonctionnement'), (217, 'donne moi le temps de fonctionnement du pc'), (217, 'verifier le temps de fonctionnement du pc'), (217, 'je veux voir le temps de fonctionnement du pc'),

-- 218. show_mac_address
(218, 'show mac address'), (218, 'display mac address'), (218, 'view mac address'), (218, 'get mac address'), (218, 'check adapter address'), (218, 'give me adapter address'), (218, 'tell me adapter address'), (218, 'adapter address'),
(218, 'اعرض عنوان الماك'), (218, 'اظهر عنوان الماك'), (218, 'عرض عنوان الماك'), (218, 'اعطني ماك ادريس'), (218, 'افحص ماك ادريس'), (218, 'اريد معرفة ماك ادريس'), (218, 'هات ماك ادريس'),
(218, 'afficher l adresse mac'), (218, 'voir l adresse mac'), (218, 'montrer l adresse mac'), (218, 'donne moi adresse mac de la carte'), (218, 'verifier adresse mac de la carte'), (218, 'je veux voir adresse mac de la carte'),

-- 219. show_public_ip
(219, 'show public ip'), (219, 'display public ip'), (219, 'view public ip'), (219, 'get public ip'), (219, 'check external ip'), (219, 'give me external ip'), (219, 'tell me external ip'), (219, 'external ip'),
(219, 'اعرض الايبي العام'), (219, 'اظهر الايبي العام'), (219, 'عرض الايبي العام'), (219, 'اعطني الايبي الخارجي'), (219, 'افحص الايبي الخارجي'), (219, 'اريد معرفة الايبي الخارجي'), (219, 'هات الايبي الخارجي'),
(219, 'afficher l ip publique'), (219, 'voir l ip publique'), (219, 'montrer l ip publique'), (219, 'donne moi l ip externe'), (219, 'verifier l ip externe'), (219, 'je veux voir l ip externe'),

-- 220. show_dns_servers
(220, 'show dns servers'), (220, 'display dns servers'), (220, 'view dns servers'), (220, 'get dns servers'), (220, 'check dns addresses'), (220, 'give me dns addresses'), (220, 'tell me dns addresses'), (220, 'dns addresses'),
(220, 'اعرض خوادم دي ان اس'), (220, 'اظهر خوادم دي ان اس'), (220, 'عرض خوادم دي ان اس'), (220, 'اعطني عناوين دي ان اس'), (220, 'افحص عناوين دي ان اس'), (220, 'اريد معرفة عناوين دي ان اس'), (220, 'هات عناوين دي ان اس'),
(220, 'afficher les serveurs dns'), (220, 'voir les serveurs dns'), (220, 'montrer les serveurs dns'), (220, 'donne moi les adresses dns'), (220, 'verifier les adresses dns'), (220, 'je veux voir les adresses dns'),

-- 221. show_arp_table
(221, 'show arp table'), (221, 'display arp table'), (221, 'view arp table'), (221, 'get arp table'), (221, 'check arp cache'), (221, 'give me arp cache'), (221, 'tell me arp cache'), (221, 'arp cache'),
(221, 'اعرض جدول ارب'), (221, 'اظهر جدول ارب'), (221, 'عرض جدول ارب'), (221, 'اعطني ذاكرة ارب'), (221, 'افحص ذاكرة ارب'), (221, 'اريد معرفة ذاكرة ارب'), (221, 'هات ذاكرة ارب'),
(221, 'afficher la table arp'), (221, 'voir la table arp'), (221, 'montrer la table arp'), (221, 'donne moi le cache arp'), (221, 'verifier le cache arp'), (221, 'je veux voir le cache arp'),

-- 222. show_routing_table
(222, 'show routing table'), (222, 'display routing table'), (222, 'view routing table'), (222, 'get routing table'), (222, 'check route table'), (222, 'give me route table'), (222, 'tell me route table'), (222, 'route table'),
(222, 'اعرض جدول التوجيه'), (222, 'اظهر جدول التوجيه'), (222, 'عرض جدول التوجيه'), (222, 'اعطني جدول المسارات'), (222, 'افحص جدول المسارات'), (222, 'اريد معرفة جدول المسارات'), (222, 'هات جدول المسارات'),
(222, 'afficher la table de routage'), (222, 'voir la table de routage'), (222, 'montrer la table de routage'), (222, 'donne moi la table des routes'), (222, 'verifier la table des routes'), (222, 'je veux voir la table des routes'),

-- 223. show_nslookup
(223, 'show nslookup'), (223, 'display nslookup'), (223, 'view nslookup'), (223, 'get nslookup'), (223, 'check dns lookup'), (223, 'give me dns lookup'), (223, 'tell me dns lookup'), (223, 'dns lookup'),
(223, 'اعرض فحص النطاق'), (223, 'اظهر فحص النطاق'), (223, 'عرض فحص النطاق'), (223, 'اعطني بحث دي ان اس'), (223, 'افحص بحث دي ان اس'), (223, 'اريد معرفة بحث دي ان اس'), (223, 'هات بحث دي ان اس'),
(223, 'afficher nslookup'), (223, 'voir nslookup'), (223, 'montrer nslookup'), (223, 'donne moi la recherche dns'), (223, 'verifier la recherche dns'), (223, 'je veux voir la recherche dns'),

-- 224. show_installed_programs
(224, 'show installed programs'), (224, 'display installed programs'), (224, 'view installed programs'), (224, 'get installed programs'), (224, 'check installed software'), (224, 'give me installed software'), (224, 'tell me installed software'), (224, 'installed software'),
(224, 'اعرض البرامج المثبتة'), (224, 'اظهر البرامج المثبتة'), (224, 'عرض البرامج المثبتة'), (224, 'اعطني البرامج المنصبة'), (224, 'افحص البرامج المنصبة'), (224, 'اريد معرفة البرامج المنصبة'), (224, 'هات البرامج المنصبة'),
(224, 'afficher les programmes installes'), (224, 'voir les programmes installes'), (224, 'montrer les programmes installes'), (224, 'donne moi les logiciels installes'), (224, 'verifier les logiciels installes'), (224, 'je veux voir les logiciels installes'),

-- 225. show_startup_programs
(225, 'show startup programs'), (225, 'display startup programs'), (225, 'view startup programs'), (225, 'get startup programs'), (225, 'check autostart list'), (225, 'give me autostart list'), (225, 'tell me autostart list'), (225, 'autostart list'),
(225, 'اعرض برامج بدء التشغيل'), (225, 'اظهر برامج بدء التشغيل'), (225, 'عرض برامج بدء التشغيل'), (225, 'اعطني قائمة التشغيل التلقائي'), (225, 'افحص قائمة التشغيل التلقائي'), (225, 'اريد معرفة قائمة التشغيل التلقائي'), (225, 'هات قائمة التشغيل التلقائي'),
(225, 'afficher les programmes au demarrage'), (225, 'voir les programmes au demarrage'), (225, 'montrer les programmes au demarrage'), (225, 'donne moi la liste de demarrage'), (225, 'verifier la liste de demarrage'), (225, 'je veux voir la liste de demarrage'),

-- 226. show_wifi_status
(226, 'show wifi status'), (226, 'display wifi status'), (226, 'view wifi status'), (226, 'get wifi status'), (226, 'check wifi signal'), (226, 'give me wifi signal'), (226, 'tell me wifi signal'), (226, 'wifi signal'),
(226, 'اعرض حالة الواي فاي'), (226, 'اظهر حالة الواي فاي'), (226, 'عرض حالة الواي فاي'), (226, 'اعطني قوة الاشارة'), (226, 'افحص قوة الاشارة'), (226, 'اريد معرفة قوة الاشارة'), (226, 'هات قوة الاشارة'),
(226, 'afficher l etat du wifi'), (226, 'voir l etat du wifi'), (226, 'montrer l etat du wifi'), (226, 'donne moi la force du signal'), (226, 'verifier la force du signal'), (226, 'je veux voir la force du signal'),

-- 227. show_firewall_status
(227, 'show firewall status'), (227, 'display firewall status'), (227, 'view firewall status'), (227, 'get firewall status'), (227, 'check firewall state'), (227, 'give me firewall state'), (227, 'tell me firewall state'), (227, 'firewall state'),
(227, 'اعرض حالة جدار الحماية'), (227, 'اظهر حالة جدار الحماية'), (227, 'عرض حالة جدار الحماية'), (227, 'اعطني وضع الجدار الناري'), (227, 'افحص وضع الجدار الناري'), (227, 'اريد معرفة وضع الجدار الناري'), (227, 'هات وضع الجدار الناري'),
(227, 'afficher l etat du pare feu'), (227, 'voir l etat du pare feu'), (227, 'montrer l etat du pare feu'), (227, 'donne moi le statut du pare feu'), (227, 'verifier le statut du pare feu'), (227, 'je veux voir le statut du pare feu'),

-- 228. show_local_users
(228, 'show local users'), (228, 'display local users'), (228, 'view local users'), (228, 'get local users'), (228, 'check all local users'), (228, 'give me all local users'), (228, 'tell me all local users'), (228, 'all local users'),
(228, 'اعرض المستخدمين المحليين'), (228, 'اظهر المستخدمين المحليين'), (228, 'عرض المستخدمين المحليين'), (228, 'اعطني كل المستخدمين'), (228, 'افحص كل المستخدمين'), (228, 'اريد معرفة كل المستخدمين'), (228, 'هات كل المستخدمين'),
(228, 'afficher les utilisateurs locaux'), (228, 'voir les utilisateurs locaux'), (228, 'montrer les utilisateurs locaux'), (228, 'donne moi tous les utilisateurs'), (228, 'verifier tous les utilisateurs'), (228, 'je veux voir tous les utilisateurs'),

-- 229. show_antivirus_status
(229, 'show antivirus status'), (229, 'display antivirus status'), (229, 'view antivirus status'), (229, 'get antivirus status'), (229, 'check defender status'), (229, 'give me defender status'), (229, 'tell me defender status'), (229, 'defender status'),
(229, 'اعرض حالة مضاد الفيروسات'), (229, 'اظهر حالة مضاد الفيروسات'), (229, 'عرض حالة مضاد الفيروسات'), (229, 'اعطني حالة الديفندر'), (229, 'افحص حالة الديفندر'), (229, 'اريد معرفة حالة الديفندر'), (229, 'هات حالة الديفندر'),
(229, 'afficher l etat de l antivirus'), (229, 'voir l etat de l antivirus'), (229, 'montrer l etat de l antivirus'), (229, 'donne moi l etat de defender'), (229, 'verifier l etat de defender'), (229, 'je veux voir l etat de defender'),

-- 230. show_screen_resolution
(230, 'show screen resolution'), (230, 'display screen resolution'), (230, 'view screen resolution'), (230, 'get screen resolution'), (230, 'check display size'), (230, 'give me display size'), (230, 'tell me display size'), (230, 'display size'),
(230, 'اعرض دقة الشاشة'), (230, 'اظهر دقة الشاشة'), (230, 'عرض دقة الشاشة'), (230, 'اعطني حجم الشاشة'), (230, 'افحص حجم الشاشة'), (230, 'اريد معرفة حجم الشاشة'), (230, 'هات حجم الشاشة'),
(230, 'afficher la resolution de l ecran'), (230, 'voir la resolution de l ecran'), (230, 'montrer la resolution de l ecran'), (230, 'donne moi la taille de l ecran'), (230, 'verifier la taille de l ecran'), (230, 'je veux voir la taille de l ecran'),

-- 231. hibernate_pc
(231, 'hibernate pc'), (231, 'hibernate the computer'), (231, 'please hibernate pc'), (231, 'hibernate pc now'), (231, 'can you hibernate the computer'), (231, 'i want to hibernate pc'), (231, 'just hibernate the computer'), (231, 'go ahead and hibernate pc'),
(231, 'سبات الجهاز'), (231, 'وضع السبات'), (231, 'نفذ سبات الجهاز'), (231, 'نفذ وضع السبات'), (231, 'اريد سبات الجهاز'), (231, 'ممكن وضع السبات'), (231, 'من فضلك سبات الجهاز'),
(231, 'mettre en hibernation'), (231, 'hiberner l ordinateur'), (231, 'je veux mettre en hibernation'), (231, 'peux tu hiberner l ordinateur'), (231, 'maintenant mettre en hibernation'), (231, 'veuillez hiberner l ordinateur'),

-- 232. sign_out
(232, 'sign out'), (232, 'log off'), (232, 'please sign out'), (232, 'sign out now'), (232, 'can you log off'), (232, 'i want to sign out'), (232, 'just log off'), (232, 'go ahead and sign out'),
(232, 'تسجيل الخروج'), (232, 'الخروج من الحساب'), (232, 'نفذ تسجيل الخروج'), (232, 'نفذ الخروج من الحساب'), (232, 'اريد تسجيل الخروج'), (232, 'ممكن الخروج من الحساب'), (232, 'من فضلك تسجيل الخروج'),
(232, 'se deconnecter'), (232, 'fermer la session'), (232, 'je veux se deconnecter'), (232, 'peux tu fermer la session'), (232, 'maintenant se deconnecter'), (232, 'veuillez fermer la session'),

-- 233. minimize_all_windows
(233, 'minimize all windows'), (233, 'hide all windows'), (233, 'please minimize all windows'), (233, 'minimize all windows now'), (233, 'can you hide all windows'), (233, 'i want to minimize all windows'), (233, 'just hide all windows'), (233, 'go ahead and minimize all windows'),
(233, 'تصغير كل النوافذ'), (233, 'اخفاء كل النوافذ'), (233, 'نفذ تصغير كل النوافذ'), (233, 'نفذ اخفاء كل النوافذ'), (233, 'اريد تصغير كل النوافذ'), (233, 'ممكن اخفاء كل النوافذ'), (233, 'من فضلك تصغير كل النوافذ'),
(233, 'reduire toutes les fenetres'), (233, 'cacher toutes les fenetres'), (233, 'je veux reduire toutes les fenetres'), (233, 'peux tu cacher toutes les fenetres'), (233, 'maintenant reduire toutes les fenetres'), (233, 'veuillez cacher toutes les fenetres'),

-- 234. restore_all_windows
(234, 'restore all windows'), (234, 'undo minimize'), (234, 'please restore all windows'), (234, 'restore all windows now'), (234, 'can you undo minimize'), (234, 'i want to restore all windows'), (234, 'just undo minimize'), (234, 'go ahead and restore all windows'),
(234, 'استعادة كل النوافذ'), (234, 'اظهار النوافذ المصغرة'), (234, 'نفذ استعادة كل النوافذ'), (234, 'نفذ اظهار النوافذ المصغرة'), (234, 'اريد استعادة كل النوافذ'), (234, 'ممكن اظهار النوافذ المصغرة'), (234, 'من فضلك استعادة كل النوافذ'),
(234, 'restaurer toutes les fenetres'), (234, 'annuler la reduction'), (234, 'je veux restaurer toutes les fenetres'), (234, 'peux tu annuler la reduction'), (234, 'maintenant restaurer toutes les fenetres'), (234, 'veuillez annuler la reduction'),

-- 235. max_volume
(235, 'max volume'), (235, 'full volume'), (235, 'please max volume'), (235, 'max volume now'), (235, 'can you full volume'), (235, 'i want to max volume'), (235, 'just full volume'), (235, 'go ahead and max volume'),
(235, 'اعلى صوت'), (235, 'الصوت الاقصى'), (235, 'نفذ اعلى صوت'), (235, 'نفذ الصوت الاقصى'), (235, 'اريد اعلى صوت'), (235, 'ممكن الصوت الاقصى'), (235, 'من فضلك اعلى صوت'),
(235, 'volume maximum'), (235, 'volume a fond'), (235, 'je veux volume maximum'), (235, 'peux tu volume a fond'), (235, 'maintenant volume maximum'), (235, 'veuillez volume a fond'),

-- 236. min_volume
(236, 'min volume'), (236, 'lowest volume'), (236, 'please min volume'), (236, 'min volume now'), (236, 'can you lowest volume'), (236, 'i want to min volume'), (236, 'just lowest volume'), (236, 'go ahead and min volume'),
(236, 'اقل صوت'), (236, 'ادنى صوت'), (236, 'نفذ اقل صوت'), (236, 'نفذ ادنى صوت'), (236, 'اريد اقل صوت'), (236, 'ممكن ادنى صوت'), (236, 'من فضلك اقل صوت'),
(236, 'volume minimum'), (236, 'volume au plus bas'), (236, 'je veux volume minimum'), (236, 'peux tu volume au plus bas'), (236, 'maintenant volume minimum'), (236, 'veuillez volume au plus bas'),

-- 237. half_volume
(237, 'half volume'), (237, 'volume fifty percent'), (237, 'please half volume'), (237, 'half volume now'), (237, 'can you volume fifty percent'), (237, 'i want to half volume'), (237, 'just volume fifty percent'), (237, 'go ahead and half volume'),
(237, 'نصف الصوت'), (237, 'الصوت خمسين بالمئة'), (237, 'نفذ نصف الصوت'), (237, 'نفذ الصوت خمسين بالمئة'), (237, 'اريد نصف الصوت'), (237, 'ممكن الصوت خمسين بالمئة'), (237, 'من فضلك نصف الصوت'),
(237, 'volume a moitie'), (237, 'volume cinquante pour cent'), (237, 'je veux volume a moitie'), (237, 'peux tu volume cinquante pour cent'), (237, 'maintenant volume a moitie'), (237, 'veuillez volume cinquante pour cent'),

-- 238. stop_music
(238, 'stop music'), (238, 'stop media playback'), (238, 'please stop music'), (238, 'stop music now'), (238, 'can you stop media playback'), (238, 'i want to stop music'), (238, 'just stop media playback'), (238, 'go ahead and stop music'),
(238, 'ايقاف الموسيقى'), (238, 'ايقاف تشغيل الوسائط'), (238, 'نفذ ايقاف الموسيقى'), (238, 'نفذ ايقاف تشغيل الوسائط'), (238, 'اريد ايقاف الموسيقى'), (238, 'ممكن ايقاف تشغيل الوسائط'), (238, 'من فضلك ايقاف الموسيقى'),
(238, 'stopper la lecture'), (238, 'arreter le media'), (238, 'je veux stopper la lecture'), (238, 'peux tu arreter le media'), (238, 'maintenant stopper la lecture'), (238, 'veuillez arreter le media'),

-- 239. restart_explorer
(239, 'restart explorer'), (239, 'reset desktop shell'), (239, 'please restart explorer'), (239, 'restart explorer now'), (239, 'can you reset desktop shell'), (239, 'i want to restart explorer'), (239, 'just reset desktop shell'), (239, 'go ahead and restart explorer'),
(239, 'اعادة تشغيل المستكشف'), (239, 'اعادة تشغيل سطح المكتب'), (239, 'نفذ اعادة تشغيل المستكشف'), (239, 'نفذ اعادة تشغيل سطح المكتب'), (239, 'اريد اعادة تشغيل المستكشف'), (239, 'ممكن اعادة تشغيل سطح المكتب'), (239, 'من فضلك اعادة تشغيل المستكشف'),
(239, 'redemarrer l explorateur'), (239, 'relancer le bureau windows'), (239, 'je veux redemarrer l explorateur'), (239, 'peux tu relancer le bureau windows'), (239, 'maintenant redemarrer l explorateur'), (239, 'veuillez relancer le bureau windows'),

-- 240. clear_clipboard
(240, 'clear clipboard'), (240, 'empty clipboard'), (240, 'please clear clipboard'), (240, 'clear clipboard now'), (240, 'can you empty clipboard'), (240, 'i want to clear clipboard'), (240, 'just empty clipboard'), (240, 'go ahead and clear clipboard'),
(240, 'مسح الحافظة'), (240, 'تفريغ الحافظة'), (240, 'نفذ مسح الحافظة'), (240, 'نفذ تفريغ الحافظة'), (240, 'اريد مسح الحافظة'), (240, 'ممكن تفريغ الحافظة'), (240, 'من فضلك مسح الحافظة'),
(240, 'vider le presse papiers'), (240, 'effacer le presse papiers'), (240, 'je veux vider le presse papiers'), (240, 'peux tu effacer le presse papiers'), (240, 'maintenant vider le presse papiers'), (240, 'veuillez effacer le presse papiers'),

-- 241. close_chrome
(241, 'close chrome'), (241, 'kill chrome'), (241, 'please close chrome'), (241, 'close chrome now'), (241, 'can you kill chrome'), (241, 'i want to close chrome'), (241, 'just kill chrome'), (241, 'go ahead and close chrome'),
(241, 'اغلاق كروم'), (241, 'اقفل كروم'), (241, 'نفذ اغلاق كروم'), (241, 'نفذ اقفل كروم'), (241, 'اريد اغلاق كروم'), (241, 'ممكن اقفل كروم'), (241, 'من فضلك اغلاق كروم'),
(241, 'fermer chrome'), (241, 'tuer chrome'), (241, 'je veux fermer chrome'), (241, 'peux tu tuer chrome'), (241, 'maintenant fermer chrome'), (241, 'veuillez tuer chrome'),

-- 242. close_edge
(242, 'close edge'), (242, 'kill edge'), (242, 'please close edge'), (242, 'close edge now'), (242, 'can you kill edge'), (242, 'i want to close edge'), (242, 'just kill edge'), (242, 'go ahead and close edge'),
(242, 'اغلاق ايدج'), (242, 'اقفل ايدج'), (242, 'نفذ اغلاق ايدج'), (242, 'نفذ اقفل ايدج'), (242, 'اريد اغلاق ايدج'), (242, 'ممكن اقفل ايدج'), (242, 'من فضلك اغلاق ايدج'),
(242, 'fermer edge'), (242, 'tuer edge'), (242, 'je veux fermer edge'), (242, 'peux tu tuer edge'), (242, 'maintenant fermer edge'), (242, 'veuillez tuer edge'),

-- 243. close_firefox
(243, 'close firefox'), (243, 'kill firefox'), (243, 'please close firefox'), (243, 'close firefox now'), (243, 'can you kill firefox'), (243, 'i want to close firefox'), (243, 'just kill firefox'), (243, 'go ahead and close firefox'),
(243, 'اغلاق فايرفوكس'), (243, 'اقفل فايرفوكس'), (243, 'نفذ اغلاق فايرفوكس'), (243, 'نفذ اقفل فايرفوكس'), (243, 'اريد اغلاق فايرفوكس'), (243, 'ممكن اقفل فايرفوكس'), (243, 'من فضلك اغلاق فايرفوكس'),
(243, 'fermer firefox'), (243, 'tuer firefox'), (243, 'je veux fermer firefox'), (243, 'peux tu tuer firefox'), (243, 'maintenant fermer firefox'), (243, 'veuillez tuer firefox'),

-- 244. close_notepad
(244, 'close notepad'), (244, 'kill notepad'), (244, 'please close notepad'), (244, 'close notepad now'), (244, 'can you kill notepad'), (244, 'i want to close notepad'), (244, 'just kill notepad'), (244, 'go ahead and close notepad'),
(244, 'اغلاق المفكرة'), (244, 'اقفل المفكرة'), (244, 'نفذ اغلاق المفكرة'), (244, 'نفذ اقفل المفكرة'), (244, 'اريد اغلاق المفكرة'), (244, 'ممكن اقفل المفكرة'), (244, 'من فضلك اغلاق المفكرة'),
(244, 'fermer le bloc notes'), (244, 'tuer le bloc notes'), (244, 'je veux fermer le bloc notes'), (244, 'peux tu tuer le bloc notes'), (244, 'maintenant fermer le bloc notes'), (244, 'veuillez tuer le bloc notes'),

-- 245. close_vscode
(245, 'close vscode'), (245, 'kill vscode'), (245, 'please close vscode'), (245, 'close vscode now'), (245, 'can you kill vscode'), (245, 'i want to close vscode'), (245, 'just kill vscode'), (245, 'go ahead and close vscode'),
(245, 'اغلاق فيجوال ستوديو كود'), (245, 'اقفل vscode'), (245, 'نفذ اغلاق فيجوال ستوديو كود'), (245, 'نفذ اقفل vscode'), (245, 'اريد اغلاق فيجوال ستوديو كود'), (245, 'ممكن اقفل vscode'), (245, 'من فضلك اغلاق فيجوال ستوديو كود'),
(245, 'fermer vscode'), (245, 'tuer vscode'), (245, 'je veux fermer vscode'), (245, 'peux tu tuer vscode'), (245, 'maintenant fermer vscode'), (245, 'veuillez tuer vscode'),

-- 246. close_spotify
(246, 'close spotify'), (246, 'kill spotify'), (246, 'please close spotify'), (246, 'close spotify now'), (246, 'can you kill spotify'), (246, 'i want to close spotify'), (246, 'just kill spotify'), (246, 'go ahead and close spotify'),
(246, 'اغلاق سبوتيفاي'), (246, 'اقفل سبوتيفاي'), (246, 'نفذ اغلاق سبوتيفاي'), (246, 'نفذ اقفل سبوتيفاي'), (246, 'اريد اغلاق سبوتيفاي'), (246, 'ممكن اقفل سبوتيفاي'), (246, 'من فضلك اغلاق سبوتيفاي'),
(246, 'fermer spotify'), (246, 'tuer spotify'), (246, 'je veux fermer spotify'), (246, 'peux tu tuer spotify'), (246, 'maintenant fermer spotify'), (246, 'veuillez tuer spotify'),

-- 247. close_discord
(247, 'close discord'), (247, 'kill discord'), (247, 'please close discord'), (247, 'close discord now'), (247, 'can you kill discord'), (247, 'i want to close discord'), (247, 'just kill discord'), (247, 'go ahead and close discord'),
(247, 'اغلاق ديسكورد'), (247, 'اقفل ديسكورد'), (247, 'نفذ اغلاق ديسكورد'), (247, 'نفذ اقفل ديسكورد'), (247, 'اريد اغلاق ديسكورد'), (247, 'ممكن اقفل ديسكورد'), (247, 'من فضلك اغلاق ديسكورد'),
(247, 'fermer discord'), (247, 'tuer discord'), (247, 'je veux fermer discord'), (247, 'peux tu tuer discord'), (247, 'maintenant fermer discord'), (247, 'veuillez tuer discord'),

-- 248. ping_cloudflare
(248, 'ping cloudflare'), (248, 'ping 1.1.1.1'), (248, 'please ping cloudflare'), (248, 'ping cloudflare now'), (248, 'can you ping 1.1.1.1'), (248, 'i want to ping cloudflare'), (248, 'just ping 1.1.1.1'), (248, 'go ahead and ping cloudflare'),
(248, 'اختبار الاتصال بكلاود فلير'), (248, 'بينج كلاود فلير'), (248, 'نفذ اختبار الاتصال بكلاود فلير'), (248, 'نفذ بينج كلاود فلير'), (248, 'اريد اختبار الاتصال بكلاود فلير'), (248, 'ممكن بينج كلاود فلير'), (248, 'من فضلك اختبار الاتصال بكلاود فلير'),
(248, 'pinger cloudflare'), (248, 'tester la connexion cloudflare'), (248, 'je veux pinger cloudflare'), (248, 'peux tu tester la connexion cloudflare'), (248, 'maintenant pinger cloudflare'), (248, 'veuillez tester la connexion cloudflare'),

-- 249. ping_8_8_8_8
(249, 'ping 8.8.8.8'), (249, 'test public dns server'), (249, 'please ping 8.8.8.8'), (249, 'ping 8.8.8.8 now'), (249, 'can you test public dns server'), (249, 'i want to ping 8.8.8.8'), (249, 'just test public dns server'), (249, 'go ahead and ping 8.8.8.8'),
(249, 'بينج 8.8.8.8'), (249, 'اختبار خادم دي ان اس العام'), (249, 'نفذ بينج 8.8.8.8'), (249, 'نفذ اختبار خادم دي ان اس العام'), (249, 'اريد بينج 8.8.8.8'), (249, 'ممكن اختبار خادم دي ان اس العام'), (249, 'من فضلك بينج 8.8.8.8'),
(249, 'pinger 8.8.8.8'), (249, 'tester le serveur dns public'), (249, 'je veux pinger 8.8.8.8'), (249, 'peux tu tester le serveur dns public'), (249, 'maintenant pinger 8.8.8.8'), (249, 'veuillez tester le serveur dns public'),

-- 250. release_ip_address
(250, 'release ip address'), (250, 'drop ip lease'), (250, 'please release ip address'), (250, 'release ip address now'), (250, 'can you drop ip lease'), (250, 'i want to release ip address'), (250, 'just drop ip lease'), (250, 'go ahead and release ip address'),
(250, 'تحرير عنوان الايبي'), (250, 'الغاء عنوان الايبي الحالي'), (250, 'نفذ تحرير عنوان الايبي'), (250, 'نفذ الغاء عنوان الايبي الحالي'), (250, 'اريد تحرير عنوان الايبي'), (250, 'ممكن الغاء عنوان الايبي الحالي'), (250, 'من فضلك تحرير عنوان الايبي'),
(250, 'liberer l adresse ip'), (250, 'abandonner le bail ip'), (250, 'je veux liberer l adresse ip'), (250, 'peux tu abandonner le bail ip'), (250, 'maintenant liberer l adresse ip'), (250, 'veuillez abandonner le bail ip');