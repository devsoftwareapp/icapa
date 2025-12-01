// lib/main.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pdf_reader_manager/tools.dart';
import 'dart:ui' as ui;

// Intent handling için
final MethodChannel _intentChannel = MethodChannel('app.channel.shared/data');
final MethodChannel _pdfViewerChannel = MethodChannel('pdf_viewer_channel');
final MethodChannel _languageChannel = MethodChannel('app.channel/language');

// Initial intent'i almak için fonksiyon
Future<Map<String, dynamic>?> _getInitialIntent() async {
  try {
    final intentData = await _intentChannel.invokeMethod('getInitialIntent');
    return intentData != null ? Map<String, dynamic>.from(intentData) : null;
  } catch (e) {
    print('Intent error: $e');
    return null;
  }
}

// Dil ayarlarını WebView'a göndermek için
Future<void> _updateWebViewLanguage(String langCode) async {
  try {
    await _languageChannel.invokeMethod('updateLanguage', {'langCode': langCode});
    print('WebView dil güncellendi: $langCode');
  } catch (e) {
    print('WebView dil güncelleme hatası: $e');
  }
}

// Tema yönetimi için
enum AppTheme { system, light, dark }

class ThemeManager with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.system;

  AppTheme get currentTheme => _currentTheme;

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
      default:
        return ThemeMode.system;
    }
  }
}

// Dil yönetimi
class LanguageManager with ChangeNotifier {
  static const String defaultLanguage = 'en';
  String _currentLanguage = defaultLanguage;
  
  // Desteklenen diller - WebView ile uyumlu
  final Map<String, String> supportedLanguages = {
    'ar': 'العربية', // Arabic
    'bn': 'বাংলা', // Bengali
    'de': 'Deutsch', // German
    'en': 'English', // English
    'es': 'Español', // Spanish
    'fr': 'Français', // French
    'hi': 'हिन्दी', // Hindi
    'id': 'Bahasa Indonesia', // Indonesian
    'ja': '日本語', // Japanese
    'ku': 'Kurmanci', // Kurmanci
    'pt': 'Português', // Portuguese
    'ru': 'Русский', // Russian
    'sw': 'Kiswahili', // Swahili
    'tr': 'Türkçe', // Turkish
    'ur': 'اردو', // Urdu
    'za': 'Zazakî', // Zazaki
    'zh': '中文', // Chinese
  };
  
  // Dil kodlarını WebView formatına dönüştür
  String get webViewLangCode {
    // WebView'daki dil kodları ile eşleştirme
    if (_currentLanguage == 'zh') return 'zh-cn'; // Basitleştirilmiş Çince
    if (_currentLanguage == 'pt') return 'pt-br'; // Brezilya Portekizcesi
    return _currentLanguage;
  }
  
  String get currentLanguage => _currentLanguage;
  
  Future<void> setLanguage(String langCode, {bool updateWebView = true}) async {
    if (supportedLanguages.containsKey(langCode)) {
      _currentLanguage = langCode;
      
      // WebView dilini güncelle
      if (updateWebView) {
        await _updateWebViewLanguage(webViewLangCode);
      }
      
      notifyListeners();
      print('Uygulama dili değiştirildi: $langCode');
    } else {
      print('Desteklenmeyen dil kodu: $langCode');
    }
  }
  
  Future<void> detectDeviceLanguage() async {
    final locale = ui.window.locale;
    String deviceLang = locale.languageCode.toLowerCase();
    
    // Özel eşleştirmeler
    if (deviceLang == 'zh_hans' || deviceLang == 'zh_cn') {
      deviceLang = 'zh';
    } else if (deviceLang == 'zh_hant' || deviceLang == 'zh_tw') {
      deviceLang = 'zh';
    } else if (deviceLang == 'pt_br' || deviceLang == 'pt_pt') {
      deviceLang = 'pt';
    }
    
    // Destekleniyor mu kontrol et
    if (supportedLanguages.containsKey(deviceLang)) {
      await setLanguage(deviceLang);
      print('Cihaz dili algılandı: $deviceLang');
    } else {
      await setLanguage(defaultLanguage);
      print('Cihaz dili desteklenmiyor, varsayılan dil kullanılıyor: $defaultLanguage');
    }
  }
  
  // Dil koduna göre yerel adını al
  String getLanguageName(String code) {
    return supportedLanguages[code] ?? code.toUpperCase();
  }
  
  // Tüm desteklenen dilleri listele
  List<Map<String, String>> getLanguageList() {
    return supportedLanguages.entries.map((entry) {
      return {'code': entry.key, 'name': entry.value};
    }).toList();
  }
}

// Basitleştirilmiş dil desteği
class AppTranslations {
  static Map<String, String> getTranslations(String languageCode) {
    final allTranslations = {
      'ar': {
        'home': 'الرئيسية',
        'tools': 'الأدوات',
        'files': 'الملفات',
        'device_files': 'الملفات على الجهاز',
        'recent': 'المستخدمة مؤخرًا',
        'favorites': 'المفضلة',
        'search': 'بحث',
        'search_hint': 'البحث في ملفات PDF...',
        'search_history': 'سجل البحث',
        'clear': 'مسح',
        'scan': 'مسح',
        'pick_file': 'اختر ملف',
        'permission_title': 'مطلوب إذن الوصول إلى الملفات',
        'permission_message': 'مطلوب إذن للوصول إلى جميع الملفات لعرض جميع ملفات PDF. يمكنك منح الإذن من الإعدادات.',
        'grant_permission': 'منح إذن الوصول',
        'cancel': 'إلغاء',
        'no_files': 'لم يتم العثور على ملفات PDF',
        'scan_again': 'مسح مرة أخرى',
        'no_recent': 'لا توجد ملفات مستخدمة مؤخرًا',
        'no_favorites': 'لا توجد ملفات مفضلة',
        'share': 'مشاركة',
        'rename': 'إعادة تسمية',
        'print': 'طباعة',
        'delete': 'حذف',
        'delete_title': 'حذف الملف',
        'delete_message': 'هل أنت متأكد أنك تريد حذف الملف؟ لا يمكن التراجع عن هذا الإجراء.',
        'confirm_delete': 'حذف',
        'cloud_storage': 'التخزين السحابي',
        'email_integration': 'تكامل البريد الإلكتروني',
        'more_files': 'تصفح للمزيد من الملفات',
        'about': 'حول',
        'help': 'المساعدة والدعم',
        'app_language': 'لغة التطبيق',
        'privacy': 'الخصوصية',
        'privacy_policy': 'سياسة الخصوصية',
        'close': 'إغلاق',
      },
      'bn': {
        'home': 'হোম',
        'tools': 'টুলস',
        'files': 'ফাইলস',
        'device_files': 'ডিভাইসে ফাইল',
        'recent': 'সাম্প্রতিক',
        'favorites': 'পছন্দসমূহ',
        'search': 'অনুসন্ধান',
        'search_hint': 'পিডিএফ ফাইলে অনুসন্ধান...',
        'search_history': 'অনুসন্ধানের ইতিহাস',
        'clear': 'পরিষ্কার',
        'scan': 'স্ক্যান',
        'pick_file': 'ফাইল নির্বাচন',
        'permission_title': 'ফাইল অ্যাক্সেস অনুমতি প্রয়োজন',
        'permission_message': 'সমস্ত পিডিএফ ফাইল তালিকাভুক্ত করার জন্য ফাইল অ্যাক্সেস অনুমতি প্রয়োজন। আপনি সেটিংস থেকে অনুমতি দিতে পারেন।',
        'grant_permission': 'ফাইল অ্যাক্সেস অনুমতি দিন',
        'cancel': 'বাতিল',
        'no_files': 'কোনো পিডিএফ ফাইল পাওয়া যায়নি',
        'scan_again': 'আবার স্ক্যান করুন',
        'no_recent': 'কোনো সাম্প্রতিক ফাইল নেই',
        'no_favorites': 'কোনো পছন্দের ফাইল নেই',
        'share': 'শেয়ার',
        'rename': 'নাম পরিবর্তন',
        'print': 'প্রিন্ট',
        'delete': 'মুছুন',
        'delete_title': 'ফাইল মুছুন',
        'delete_message': 'দলীয় মুছতে চান? এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',
        'confirm_delete': 'মুছুন',
        'cloud_storage': 'ক্লাউড স্টোরেজ',
        'email_integration': 'ইমেল ইন্টিগ্রেশন',
        'more_files': 'আরও ফাইলের জন্য ব্রাউজ করুন',
        'about': 'সম্পর্কে',
        'help': 'সাহায্য ও সমর্থন',
        'app_language': 'অ্যাপ ভাষা',
        'privacy': 'গোপনীয়তা',
        'privacy_policy': 'গোপনীয়তা নীতি',
        'close': 'বন্ধ',
      },
      'de': {
        'home': 'Startseite',
        'tools': 'Werkzeuge',
        'files': 'Dateien',
        'device_files': 'Gerätedateien',
        'recent': 'Zuletzt verwendet',
        'favorites': 'Favoriten',
        'search': 'Suchen',
        'search_hint': 'PDF-Dateien durchsuchen...',
        'search_history': 'Suchverlauf',
        'clear': 'Löschen',
        'scan': 'Scannen',
        'pick_file': 'Datei auswählen',
        'permission_title': 'Dateizugriffsberechtigung erforderlich',
        'permission_message': 'Zum Auflisten aller PDF-Dateien ist die Dateizugriffsberechtigung erforderlich. Sie können die Berechtigung in den Einstellungen erteilen.',
        'grant_permission': 'Dateizugriffsberechtigung erteilen',
        'cancel': 'Abbrechen',
        'no_files': 'Keine PDF-Dateien gefunden',
        'scan_again': 'Erneut scannen',
        'no_recent': 'Keine zuletzt geöffneten Dateien',
        'no_favorites': 'Keine Favoriten',
        'share': 'Teilen',
        'rename': 'Umbenennen',
        'print': 'Drucken',
        'delete': 'Löschen',
        'delete_title': 'Datei löschen',
        'delete_message': 'Sind Sie sicher, dass Sie die Datei löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
        'confirm_delete': 'Löschen',
        'cloud_storage': 'Cloud-Speicher',
        'email_integration': 'E-Mail-Integration',
        'more_files': 'Für weitere Dateien durchsuchen',
        'about': 'Über',
        'help': 'Hilfe & Support',
        'app_language': 'App-Sprache',
        'privacy': 'Datenschutz',
        'privacy_policy': 'Datenschutzerklärung',
        'close': 'Schließen',
      },
      'en': {
        'home': 'Home',
        'tools': 'Tools',
        'files': 'Files',
        'device_files': 'Device Files',
        'recent': 'Recent',
        'favorites': 'Favorites',
        'search': 'Search',
        'search_hint': 'Search in PDF files...',
        'search_history': 'Search History',
        'clear': 'Clear',
        'scan': 'Scan',
        'pick_file': 'Pick File',
        'permission_title': 'File Access Permission Required',
        'permission_message': 'File access permission is required to list all PDF files. You can grant permission from Settings.',
        'grant_permission': 'Grant File Access Permission',
        'cancel': 'Cancel',
        'no_files': 'No PDF files found',
        'scan_again': 'Scan Again',
        'no_recent': 'No recent files',
        'no_favorites': 'No favorites',
        'share': 'Share',
        'rename': 'Rename',
        'print': 'Print',
        'delete': 'Delete',
        'delete_title': 'Delete File',
        'delete_message': 'Are you sure you want to delete the file? This action cannot be undone.',
        'confirm_delete': 'Delete',
        'cloud_storage': 'Cloud Storage',
        'email_integration': 'Email Integration',
        'more_files': 'Browse for More Files',
        'about': 'About',
        'help': 'Help & Support',
        'app_language': 'App Language',
        'privacy': 'Privacy',
        'privacy_policy': 'Privacy Policy',
        'close': 'Close',
      },
      'es': {
        'home': 'Inicio',
        'tools': 'Herramientas',
        'files': 'Archivos',
        'device_files': 'Archivos del dispositivo',
        'recent': 'Recientes',
        'favorites': 'Favoritos',
        'search': 'Buscar',
        'search_hint': 'Buscar en archivos PDF...',
        'search_history': 'Historial de búsqueda',
        'clear': 'Limpiar',
        'scan': 'Escanear',
        'pick_file': 'Seleccionar archivo',
        'permission_title': 'Se requiere permiso de acceso a archivos',
        'permission_message': 'Se requiere permiso de acceso a archivos para listar todos los archivos PDF. Puede otorgar permiso desde Configuración.',
        'grant_permission': 'Otorgar permiso de acceso a archivos',
        'cancel': 'Cancelar',
        'no_files': 'No se encontraron archivos PDF',
        'scan_again': 'Escanear de nuevo',
        'no_recent': 'No hay archivos recientes',
        'no_favorites': 'No hay favoritos',
        'share': 'Compartir',
        'rename': 'Renombrar',
        'print': 'Imprimir',
        'delete': 'Eliminar',
        'delete_title': 'Eliminar archivo',
        'delete_message': '¿Está seguro de que desea eliminar el archivo? Esta acción no se puede deshacer.',
        'confirm_delete': 'Eliminar',
        'cloud_storage': 'Almacenamiento en la nube',
        'email_integration': 'Integración de correo electrónico',
        'more_files': 'Buscar más archivos',
        'about': 'Acerca de',
        'help': 'Ayuda y soporte',
        'app_language': 'Idioma de la aplicación',
        'privacy': 'Privacidad',
        'privacy_policy': 'Política de privacidad',
        'close': 'Cerrar',
      },
      'fr': {
        'home': 'Accueil',
        'tools': 'Outils',
        'files': 'Fichiers',
        'device_files': 'Fichiers de l\'appareil',
        'recent': 'Récents',
        'favorites': 'Favoris',
        'search': 'Rechercher',
        'search_hint': 'Rechercher dans les fichiers PDF...',
        'search_history': 'Historique de recherche',
        'clear': 'Effacer',
        'scan': 'Scanner',
        'pick_file': 'Choisir un fichier',
        'permission_title': 'Autorisation d\'accès aux fichiers requise',
        'permission_message': 'L\'autorisation d\'accès aux fichiers est requise pour lister tous les fichiers PDF. Vous pouvez accorder l\'autorisation dans les Paramètres.',
        'grant_permission': 'Accorder l\'autorisation d\'accès aux fichiers',
        'cancel': 'Annuler',
        'no_files': 'Aucun fichier PDF trouvé',
        'scan_again': 'Scanner à nouveau',
        'no_recent': 'Aucun fichier récent',
        'no_favorites': 'Aucun favori',
        'share': 'Partager',
        'rename': 'Renommer',
        'print': 'Imprimer',
        'delete': 'Supprimer',
        'delete_title': 'Supprimer le fichier',
        'delete_message': 'Êtes-vous sûr de vouloir supprimer le fichier ? Cette action ne peut pas être annulée.',
        'confirm_delete': 'Supprimer',
        'cloud_storage': 'Stockage en nuage',
        'email_integration': 'Intégration d\'e-mail',
        'more_files': 'Parcourir pour plus de fichiers',
        'about': 'À propos',
        'help': 'Aide et support',
        'app_language': 'Langue de l\'application',
        'privacy': 'Confidentialité',
        'privacy_policy': 'Politique de confidentialité',
        'close': 'Fermer',
      },
      'hi': {
        'home': 'होम',
        'tools': 'टूल्स',
        'files': 'फ़ाइलें',
        'device_files': 'डिवाइस फ़ाइलें',
        'recent': 'हाल ही में',
        'favorites': 'पसंदीदा',
        'search': 'खोज',
        'search_hint': 'पीडीएफ फ़ाइलों में खोज...',
        'search_history': 'खोज इतिहास',
        'clear': 'साफ़ करें',
        'scan': 'स्कैन',
        'pick_file': 'फ़ाइल चुनें',
        'permission_title': 'फ़ाइल पहुंच अनुमति आवश्यक',
        'permission_message': 'सभी पीडीएफ फ़ाइलों को सूचीबद्ध करने के लिए फ़ाइल पहुंच अनुमति आवश्यक है। आप सेटिंग्स से अनुमति दे सकते हैं।',
        'grant_permission': 'फ़ाइल पहुंच अनुमति दें',
        'cancel': 'रद्द करें',
        'no_files': 'कोई पीडीएफ फ़ाइल नहीं मिली',
        'scan_again': 'फिर से स्कैन करें',
        'no_recent': 'कोई हाल की फ़ाइल नहीं',
        'no_favorites': 'कोई पसंदीदा नहीं',
        'share': 'साझा करें',
        'rename': 'नाम बदलें',
        'print': 'प्रिंट',
        'delete': 'हटाएं',
        'delete_title': 'फ़ाइल हटाएं',
        'delete_message': 'क्या आप वाकई फ़ाइल हटाना चाहते हैं? इस क्रिया को पूर्ववत नहीं किया जा सकता।',
        'confirm_delete': 'हटाएं',
        'cloud_storage': 'क्लाउड स्टोरेज',
        'email_integration': 'ईमेल एकीकरण',
        'more_files': 'अधिक फ़ाइलों के लिए ब्राउज़ करें',
        'about': 'के बारे में',
        'help': 'सहायता और समर्थन',
        'app_language': 'ऐप भाषा',
        'privacy': 'गोपनीयता',
        'privacy_policy': 'गोपनीयता नीति',
        'close': 'बंद करें',
      },
      'id': {
        'home': 'Beranda',
        'tools': 'Alat',
        'files': 'File',
        'device_files': 'File Perangkat',
        'recent': 'Terbaru',
        'favorites': 'Favorit',
        'search': 'Cari',
        'search_hint': 'Cari dalam file PDF...',
        'search_history': 'Riwayat Pencarian',
        'clear': 'Hapus',
        'scan': 'Pindai',
        'pick_file': 'Pilih File',
        'permission_title': 'Izin Akses File Diperlukan',
        'permission_message': 'Izin akses file diperlukan untuk mendaftar semua file PDF. Anda dapat memberikan izin dari Pengaturan.',
        'grant_permission': 'Berikan Izin Akses File',
        'cancel': 'Batal',
        'no_files': 'Tidak ada file PDF yang ditemukan',
        'scan_again': 'Pindai Lagi',
        'no_recent': 'Tidak ada file terbaru',
        'no_favorites': 'Tidak ada favorit',
        'share': 'Bagikan',
        'rename': 'Ganti Nama',
        'print': 'Cetak',
        'delete': 'Hapus',
        'delete_title': 'Hapus File',
        'delete_message': 'Apakah Anda yakin ingin menghapus file? Tindakan ini tidak dapat dibatalkan.',
        'confirm_delete': 'Hapus',
        'cloud_storage': 'Penyimpanan Awan',
        'email_integration': 'Integrasi Email',
        'more_files': 'Jelajahi untuk File Lainnya',
        'about': 'Tentang',
        'help': 'Bantuan & Dukungan',
        'app_language': 'Bahasa Aplikasi',
        'privacy': 'Privasi',
        'privacy_policy': 'Kebijakan Privasi',
        'close': 'Tutup',
      },
      'ja': {
        'home': 'ホーム',
        'tools': 'ツール',
        'files': 'ファイル',
        'device_files': 'デバイスファイル',
        'recent': '最近',
        'favorites': 'お気に入り',
        'search': '検索',
        'search_hint': 'PDFファイルを検索...',
        'search_history': '検索履歴',
        'clear': 'クリア',
        'scan': 'スキャン',
        'pick_file': 'ファイルを選択',
        'permission_title': 'ファイルアクセス許可が必要です',
        'permission_message': 'すべてのPDFファイルをリストするには、ファイルアクセス許可が必要です。設定から許可を付与できます。',
        'grant_permission': 'ファイルアクセス許可を付与',
        'cancel': 'キャンセル',
        'no_files': 'PDFファイルが見つかりません',
        'scan_again': '再スキャン',
        'no_recent': '最近のファイルはありません',
        'no_favorites': 'お気に入りはありません',
        'share': '共有',
        'rename': '名前を変更',
        'print': '印刷',
        'delete': '削除',
        'delete_title': 'ファイルを削除',
        'delete_message': 'ファイルを削除してもよろしいですか？この操作は元に戻せません。',
        'confirm_delete': '削除',
        'cloud_storage': 'クラウドストレージ',
        'email_integration': 'メール連携',
        'more_files': 'さらにファイルを閲覧',
        'about': 'について',
        'help': 'ヘルプ＆サポート',
        'app_language': 'アプリの言語',
        'privacy': 'プライバシー',
        'privacy_policy': 'プライバシーポリシー',
        'close': '閉じる',
      },
      'ku': {
        'home': 'Mal',
        'tools': 'Amûr',
        'files': 'Dosye',
        'device_files': 'Dosyeyên Amûrê',
        'recent': 'Nêzîk',
        'favorites': 'Bijare',
        'search': 'Lêgerîn',
        'search_hint': 'Di dosyeyên PDF de lêgerîn...',
        'search_history': 'Dîroka Lêgerînê',
        'clear': 'Paqij bike',
        'scan': 'Pêl dan',
        'pick_file': 'Dosye hilbijêre',
        'permission_title': 'Destûra Gihîştina Dosyeyê Pêwîst e',
        'permission_message': 'Destûra gihîştina dosyeyê ji bo lîstekirina hemû dosyeyên PDF pêwîst e. Hûn dikarin ji Sazkirinan destûr bidin.',
        'grant_permission': 'Destûra Gihîştina Dosyeyê Bidin',
        'cancel': 'Betal bike',
        'no_files': 'Dosyeya PDF nehate dîtin',
        'scan_again': 'Dîsa pêl bide',
        'no_recent': 'Dosyeyên nêzîk tune',
        'no_favorites': 'Bijare tune',
        'share': 'Parve bike',
        'rename': 'Nav biguherîne',
        'print': 'Çap bike',
        'delete': 'Jê bibe',
        'delete_title': 'Dosyeyê Jê Bibe',
        'delete_message': 'Ma hûn guman dikin ku hûn dixwazin dosyeyê jê bibin? Ev çalakî nabe vegerandin.',
        'confirm_delete': 'Jê Bibe',
        'cloud_storage': 'Embara Ewrê',
        'email_integration': 'Têkiliya E-nameyê',
        'more_files': 'Ji bo Dosyeyên Zêdetir Bigerin',
        'about': 'Derbarê',
        'help': 'Alîkarî & Piştgirî',
        'app_language': 'Zimanê Appê',
        'privacy': 'Nihênî',
        'privacy_policy': 'Sîyaseta Nihênîbûnê',
        'close': 'Bigre',
      },
      'pt': {
        'home': 'Início',
        'tools': 'Ferramentas',
        'files': 'Arquivos',
        'device_files': 'Arquivos do Dispositivo',
        'recent': 'Recentes',
        'favorites': 'Favoritos',
        'search': 'Pesquisar',
        'search_hint': 'Pesquisar em arquivos PDF...',
        'search_history': 'Histórico de Pesquisa',
        'clear': 'Limpar',
        'scan': 'Escanear',
        'pick_file': 'Escolher Arquivo',
        'permission_title': 'Permissão de Acesso a Arquivos Necessária',
        'permission_message': 'A permissão de acesso a arquivos é necessária para listar todos os arquivos PDF. Você pode conceder permissão nas Configurações.',
        'grant_permission': 'Conceder Permissão de Acesso a Arquivos',
        'cancel': 'Cancelar',
        'no_files': 'Nenhum arquivo PDF encontrado',
        'scan_again': 'Escanear Novamente',
        'no_recent': 'Nenhum arquivo recente',
        'no_favorites': 'Nenhum favorito',
        'share': 'Compartilhar',
        'rename': 'Renomear',
        'print': 'Imprimir',
        'delete': 'Excluir',
        'delete_title': 'Excluir Arquivo',
        'delete_message': 'Tem certeza de que deseja excluir o arquivo? Esta ação não pode ser desfeita.',
        'confirm_delete': 'Excluir',
        'cloud_storage': 'Armazenamento em Nuvem',
        'email_integration': 'Integração de E-mail',
        'more_files': 'Procurar Mais Arquivos',
        'about': 'Sobre',
        'help': 'Ajuda e Suporte',
        'app_language': 'Idioma do Aplicativo',
        'privacy': 'Privacidade',
        'privacy_policy': 'Política de Privacidade',
        'close': 'Fechar',
      },
      'ru': {
        'home': 'Главная',
        'tools': 'Инструменты',
        'files': 'Файлы',
        'device_files': 'Файлы устройства',
        'recent': 'Недавние',
        'favorites': 'Избранное',
        'search': 'Поиск',
        'search_hint': 'Поиск в PDF файлах...',
        'search_history': 'История поиска',
        'clear': 'Очистить',
        'scan': 'Сканировать',
        'pick_file': 'Выбрать файл',
        'permission_title': 'Требуется разрешение на доступ к файлам',
        'permission_message': 'Для отображения всех PDF файлов требуется разрешение на доступ к файлам. Вы можете предоставить разрешение в Настройках.',
        'grant_permission': 'Предоставить разрешение на доступ к файлам',
        'cancel': 'Отмена',
        'no_files': 'PDF файлы не найдены',
        'scan_again': 'Сканировать снова',
        'no_recent': 'Нет недавних файлов',
        'no_favorites': 'Нет избранного',
        'share': 'Поделиться',
        'rename': 'Переименовать',
        'print': 'Печать',
        'delete': 'Удалить',
        'delete_title': 'Удалить файл',
        'delete_message': 'Вы уверены, что хотите удалить файл? Это действие нельзя отменить.',
        'confirm_delete': 'Удалить',
        'cloud_storage': 'Облачное хранилище',
        'email_integration': 'Интеграция с электронной почтой',
        'more_files': 'Просмотреть другие файлы',
        'about': 'О программе',
        'help': 'Помощь и поддержка',
        'app_language': 'Язык приложения',
        'privacy': 'Конфиденциальность',
        'privacy_policy': 'Политика конфиденциальности',
        'close': 'Закрыть',
      },
      'sw': {
        'home': 'Nyumbani',
        'tools': 'Zana',
        'files': 'Faili',
        'device_files': 'Faili za Kifaa',
        'recent': 'Hivi Karibuni',
        'favorites': 'Vipendwa',
        'search': 'Tafuta',
        'search_hint': 'Tafuta kwenye faili za PDF...',
        'search_history': 'Historia ya Utafutaji',
        'clear': 'Futa',
        'scan': 'Piga chapa',
        'pick_file': 'Chagua Faili',
        'permission_title': 'Kibali cha Ufikiaji wa Faili Kinahitajika',
        'permission_message': 'Kibali cha ufikiaji wa faili kinahitajika kuorodhesha faili zote za PDF. Unaweza kutoa kibali kutoka kwenye Mipangilio.',
        'grant_permission': 'Toa Kibali cha Ufikiaji wa Faili',
        'cancel': 'Ghairi',
        'no_files': 'Hakuna faili za PDF zilizopatikana',
        'scan_again': 'Piga Chapa Tena',
        'no_recent': 'Hakuna faili za hivi karibuni',
        'no_favorites': 'Hakuna vipendwa',
        'share': 'Shiriki',
        'rename': 'Badilisha Jina',
        'print': 'Chapisha',
        'delete': 'Futa',
        'delete_title': 'Futa Faili',
        'delete_message': 'Una uhakika unataka kufuta faili? Hatua hii haiwezi kutenduliwa.',
        'confirm_delete': 'Futa',
        'cloud_storage': 'Hifadhi ya Wingu',
        'email_integration': 'Ujumuishaji wa Barua Pepe',
        'more_files': 'Vinjari kwa Faili Zaidi',
        'about': 'Kuhusu',
        'help': 'Msaada & Usaidizi',
        'app_language': 'Lugha ya Programu',
        'privacy': 'Faragha',
        'privacy_policy': 'Sera ya Faragha',
        'close': 'Funga',
      },
      'tr': {
        'home': 'Ana Sayfa',
        'tools': 'Araçlar',
        'files': 'Dosyalar',
        'device_files': 'Cihazda',
        'recent': 'Son Kullanılanlar',
        'favorites': 'Favoriler',
        'search': 'Ara',
        'search_hint': 'PDF dosyalarında ara...',
        'search_history': 'Arama Geçmişi',
        'clear': 'Temizle',
        'scan': 'Tara',
        'pick_file': 'Dosya Seç',
        'permission_title': 'Dosya Erişim İzni Gerekli',
        'permission_message': 'Tüm PDF dosyalarını listelemek için dosya erişim izni gerekiyor. Ayarlardan izin verebilirsiniz.',
        'grant_permission': 'Tüm Dosya Erişim İzni Ver',
        'cancel': 'İptal',
        'no_files': 'PDF dosyası bulunamadı',
        'scan_again': 'Yeniden Tara',
        'no_recent': 'Henüz son açılan dosya yok',
        'no_favorites': 'Henüz favori dosyanız yok',
        'share': 'Paylaş',
        'rename': 'Yeniden Adlandır',
        'print': 'Yazdır',
        'delete': 'Sil',
        'delete_title': 'Dosyayı Sil',
        'delete_message': 'Dosyayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        'confirm_delete': 'Sil',
        'cloud_storage': 'Bulut Depolama',
        'email_integration': 'E-posta Entegrasyonu',
        'more_files': 'Daha Fazla Dosya İçin Göz Atın',
        'about': 'Hakkında',
        'help': 'Yardım ve Destek',
        'app_language': 'Uygulama Dili',
        'privacy': 'Gizlilik',
        'privacy_policy': 'Gizlilik Politikası',
        'close': 'Kapat',
      },
      'ur': {
        'home': 'ہوم',
        'tools': 'ٹولز',
        'files': 'فائلیں',
        'device_files': 'ڈیوائس فائلیں',
        'recent': 'حالیہ',
        'favorites': 'پسندیدہ',
        'search': 'تلاش',
        'search_hint': 'پی ڈی ایف فائلوں میں تلاش کریں...',
        'search_history': 'تلاش کی تاریخ',
        'clear': 'صاف کریں',
        'scan': 'اسکین',
        'pick_file': 'فائل منتخب کریں',
        'permission_title': 'فائل تک رسائی کی اجازت درکار ہے',
        'permission_message': 'تمام پی ڈی ایف فائلوں کی فہرست بنانے کے لیے فائل تک رسائی کی اجازت درکار ہے۔ آپ ترتیبات سے اجازت دے سکتے ہیں۔',
        'grant_permission': 'فائل تک رسائی کی اجازت دیں',
        'cancel': 'منسوخ',
        'no_files': 'کوئی پی ڈی ایف فائل نہیں ملی',
        'scan_again': 'دوبارہ اسکین کریں',
        'no_recent': 'کوئی حالیہ فائل نہیں',
        'no_favorites': 'کوئی پسندیدہ نہیں',
        'share': 'اشتراک',
        'rename': 'نام تبدیل کریں',
        'print': 'پرنٹ',
        'delete': 'حذف کریں',
        'delete_title': 'فائل حذف کریں',
        'delete_message': 'کیا آپ واقعی فائل حذف کرنا چاہتے ہیں؟ اس عمل کو واپس نہیں کیا جا سکتا۔',
        'confirm_delete': 'حذف کریں',
        'cloud_storage': 'کلاؤڈ اسٹوریج',
        'email_integration': 'ای میل انضمام',
        'more_files': 'مزید فائلوں کے لیے براؤز کریں',
        'about': 'متعلق',
        'help': 'مدد اور سپورٹ',
        'app_language': 'ایپ کی زبان',
        'privacy': 'رازداری',
        'privacy_policy': 'رازداری کی پالیسی',
        'close': 'بند کریں',
      },
      'za': {
        'home': 'Keye',
        'tools': 'Hacet',
        'files': 'Dosya',
        'device_files': 'Dosyayê Cihazî',
        'recent': 'Nezdî',
        'favorites': 'Hewlî',
        'search': 'Cî',
        'search_hint': 'Di dosyayanê PDF de cî bike...',
        'search_history': 'Dîroka Cîkirinê',
        'clear': 'Paqij bike',
        'scan': 'Pêl bike',
        'pick_file': 'Dosya weçîne',
        'permission_title': 'Destûra Dosyayê Pêwîst e',
        'permission_message': 'Destûra dosyayê ji bo lîstekirina hemû dosyayên PDF pêwîst e. Hûn dikarin ji Saziyan destûr bidin.',
        'grant_permission': 'Destûra Dosyayê Bidin',
        'cancel': 'Betal bike',
        'no_files': 'Dosyeya PDF nehate dîtin',
        'scan_again': 'Dîsa pêl bike',
        'no_recent': 'Dosyeyên nezdî tune',
        'no_favorites': 'Hewlî tune',
        'share': 'Parve bike',
        'rename': 'Nav biguherîne',
        'print': 'Çap bike',
        'delete': 'Jê bibe',
        'delete_title': 'Dosyeyê Jê Bibe',
        'delete_message': 'Ma hûn bawer dikin ku hûn dixwazin dosyeyê jê bibin? Ev çalakî nabe vegerandin.',
        'confirm_delete': 'Jê Bibe',
        'cloud_storage': 'Embara Ewrê',
        'email_integration': 'Têkiliya E-nameyê',
        'more_files': 'Ji bo Dosyeyên Zêdetir Bigerin',
        'about': 'Derheq',
        'help': 'Alîkarî & Piştgirî',
        'app_language': 'Zimanê Appê',
        'privacy': 'Nihênî',
        'privacy_policy': 'Sîyaseta Nihênîbûnê',
        'close': 'Bigre',
      },
      'zh': {
        'home': '首页',
        'tools': '工具',
        'files': '文件',
        'device_files': '设备文件',
        'recent': '最近',
        'favorites': '收藏',
        'search': '搜索',
        'search_hint': '在PDF文件中搜索...',
        'search_history': '搜索历史',
        'clear': '清除',
        'scan': '扫描',
        'pick_file': '选择文件',
        'permission_title': '需要文件访问权限',
        'permission_message': '需要文件访问权限才能列出所有PDF文件。您可以从设置中授予权限。',
        'grant_permission': '授予文件访问权限',
        'cancel': '取消',
        'no_files': '未找到PDF文件',
        'scan_again': '重新扫描',
        'no_recent': '没有最近的文件',
        'no_favorites': '没有收藏',
        'share': '分享',
        'rename': '重命名',
        'print': '打印',
        'delete': '删除',
        'delete_title': '删除文件',
        'delete_message': '您确定要删除该文件吗？此操作无法撤销。',
        'confirm_delete': '删除',
        'cloud_storage': '云存储',
        'email_integration': '电子邮件集成',
        'more_files': '浏览更多文件',
        'about': '关于',
        'help': '帮助与支持',
        'app_language': '应用语言',
        'privacy': '隐私',
        'privacy_policy': '隐私政策',
        'close': '关闭',
      },
    };
    
    return allTranslations[languageCode] ?? allTranslations['en']!;
  }

  static String translate(BuildContext context, String key) {
    final languageManager = LanguageManagerProvider.of(context);
    final languageCode = languageManager?.currentLanguage ?? 'en';
    final translations = getTranslations(languageCode);
    return translations[key] ?? key;
  }
}

// LanguageManager provider
class LanguageManagerProvider extends InheritedWidget {
  final LanguageManager languageManager;

  const LanguageManagerProvider({
    super.key,
    required super.child,
    required this.languageManager,
  });

  static LanguageManager? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LanguageManagerProvider>()?.languageManager;
  }

  @override
  bool updateShouldNotify(LanguageManagerProvider oldWidget) {
    return languageManager != oldWidget.languageManager;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  
  // Uygulama klasörünü oluştur
  await _createAppFolder();
  
  final initialIntent = await _getInitialIntent();
  
  runApp(PdfManagerApp(initialIntent: initialIntent));
}

Future<void> _createAppFolder() async {
  try {
    final path = '/storage/emulated/0/Download/PDF Reader';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  } catch (e) {
    print('Klasör oluşturma hatası: $e');
  }
}

class PdfManagerApp extends StatefulWidget {
  final Map<String, dynamic>? initialIntent;

  const PdfManagerApp({super.key, this.initialIntent});

  @override
  State<PdfManagerApp> createState() => _PdfManagerAppState();
}

class _PdfManagerAppState extends State<PdfManagerApp> {
  late LanguageManager _languageManager;
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.detectDeviceLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageManagerProvider(
      languageManager: _languageManager,
      child: MaterialApp(
        title: 'PDF Reader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          primaryColor: Color(0xFFD32F2F),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            elevation: 2,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFFD32F2F),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
          tabBarTheme: TabBarTheme(
            labelColor: Color(0xFFD32F2F),
            unselectedLabelColor: Colors.grey,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.0, color: Color(0xFFD32F2F)),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.red,
          primaryColor: Color(0xFFD32F2F),
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            elevation: 2,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.grey[800],
            selectedItemColor: Color(0xFFD32F2F),
            unselectedItemColor: Colors.grey[400],
            type: BottomNavigationBarType.fixed,
          ),
          tabBarTheme: TabBarTheme(
            labelColor: Color(0xFFD32F2F),
            unselectedLabelColor: Colors.grey[400],
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.0, color: Color(0xFFD32F2F)),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            color: Colors.grey[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        themeMode: _themeManager.themeMode,
        home: HomePage(
          initialIntent: widget.initialIntent,
          languageManager: _languageManager,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? initialIntent;
  final LanguageManager languageManager;

  const HomePage({
    super.key, 
    this.initialIntent,
    required this.languageManager,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<String> _pdfFiles = [];
  List<String> _favoriteFiles = [];
  List<String> _recentFiles = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _permissionGranted = false;
  int _currentTabIndex = 0;
  
  late TabController _mainTabController;
  late TabController _homeSubTabController;

  bool _isFabOpen = false;
  bool _isSearchMode = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Database? _database;

  // Basitleştirilmiş başlıklar - Dil desteği için AppTranslations kullanacağız
  List<String> get _tabTitles => [
    AppTranslations.translate(context, 'home'),
    AppTranslations.translate(context, 'tools'),
    AppTranslations.translate(context, 'files'),
  ];
  
  List<String> get _homeTabTitles => [
    AppTranslations.translate(context, 'device_files'),
    AppTranslations.translate(context, 'recent'),
    AppTranslations.translate(context, 'favorites'),
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController.addListener(_handleTabChange);

    _homeSubTabController = TabController(length: 3, vsync: this);
    _homeSubTabController.addListener(() {
      setState(() {});
    });

    _initDatabase();
    _checkPermission();
    _loadSearchHistory();
    
    _intentChannel.setMethodCallHandler(_handleIntentMethodCall);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialIntent();
    });
    
    // Dil değişikliklerini dinle
    widget.languageManager.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      'pdf_reader.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT UNIQUE,
            added_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE recents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT UNIQUE,
            opened_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT UNIQUE,
            searched_date TEXT
          )
        ''');
      },
    );
    await _loadFavorites();
    await _loadRecents();
  }

  Future<void> _loadFavorites() async {
    if (_database == null) return;
    final List<Map<String, dynamic>> maps = await _database!.query('favorites');
    setState(() {
      _favoriteFiles = List.generate(maps.length, (i) => maps[i]['file_path']);
    });
  }

  Future<void> _loadRecents() async {
    if (_database == null) return;
    final List<Map<String, dynamic>> maps = await _database!.query('recents');
    setState(() {
      _recentFiles = List.generate(maps.length, (i) => maps[i]['file_path']);
    });
  }

  Future<void> _loadSearchHistory() async {
    if (_database == null) return;
    final List<Map<String, dynamic>> maps = await _database!.query(
      'search_history',
      orderBy: 'searched_date DESC',
      limit: 10
    );
    setState(() {
      _searchHistory = List.generate(maps.length, (i) => maps[i]['query']);
    });
  }

  Future<void> _addToSearchHistory(String query) async {
    if (_database == null) return;
    await _database!.insert(
      'search_history',
      {
        'query': query,
        'searched_date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadSearchHistory();
  }

  Future<void> _clearSearchHistory() async {
    if (_database == null) return;
    await _database!.delete('search_history');
    await _loadSearchHistory();
  }

  Future<void> _addToFavorites(String filePath) async {
    if (_database == null) return;
    await _database!.insert(
      'favorites',
      {
        'file_path': filePath,
        'added_date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadFavorites();
  }

  Future<void> _removeFromFavorites(String filePath) async {
    if (_database == null) return;
    await _database!.delete(
      'favorites',
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
    await _loadFavorites();
  }

  Future<void> _addToRecents(String filePath) async {
    if (_database == null) return;
    await _database!.insert(
      'recents',
      {
        'file_path': filePath,
        'opened_date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadRecents();
  }

  void _handleTabChange() {
    setState(() {
      _currentTabIndex = _mainTabController.index;
    });
  }

  Future<dynamic> _handleIntentMethodCall(MethodCall call) async {
    if (call.method == 'onNewIntent') {
      final intentData = Map<String, dynamic>.from(call.arguments);
      _processExternalPdfIntent(intentData);
    }
    return null;
  }

  void _handleInitialIntent() {
    if (widget.initialIntent != null && widget.initialIntent!.isNotEmpty) {
      _processExternalPdfIntent(widget.initialIntent!);
    }
  }

  void _processExternalPdfIntent(Map<String, dynamic> intentData) {
    final action = intentData['action'];
    final uri = intentData['uri'];
    try {
      if ((action == 'android.intent.action.VIEW' || action == 'android.intent.action.SEND') && uri != null) {
        _handleExternalPdfOpening(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ PDF açılırken hata: $e')),
        );
      }
    }
  }

  Future<void> _handleExternalPdfOpening(String uri) async {
    try {
      String sourcePath = uri;
      if (uri.startsWith('content://')) {
        sourcePath = await _pdfViewerChannel.invokeMethod('convertContentUri', {'uri': uri});
      }

      final downloadDir = Directory('/storage/emulated/0/Download/PDF Reader');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final fileName = _extractFileNameFromUri(uri);
      final newPath = '${downloadDir.path}/$fileName';
      
      try {
        final sourceFile = File(sourcePath);
        if (await sourceFile.exists()) {
          await sourceFile.copy(newPath);
        }
      } catch (e) {
         // Hata yok say
      }

      final fileToOpen = File(newPath).existsSync() ? newPath : sourcePath;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewerScreen(
            fileUri: fileToOpen,
            fileName: fileName,
            languageManager: widget.languageManager,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ PDF açılırken hata: $e')),
      );
    }
  }

  String _extractFileNameFromUri(String uri) {
    try {
      final uriObj = Uri.parse(uri);
      final segments = uriObj.pathSegments;
      if (segments.isNotEmpty) {
        String fileName = segments.last;
        if (fileName.contains('?')) {
          fileName = fileName.split('?').first;
        }
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          fileName = '$fileName.pdf';
        }
        return fileName;
      }
    } catch (e) {
      // Hata yok say
    }
    return 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  Future<void> _checkPermission() async {
    Permission permission = await _getRequiredPermission();
    var status = await permission.status;
    setState(() {
      _permissionGranted = status.isGranted;
    });
    if (_permissionGranted) {
      _scanDeviceForPdfs();
    }
  }

  Future<Permission> _getRequiredPermission() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 30) {
      return Permission.manageExternalStorage;
    }
    return Permission.storage;
  }

  Future<void> _requestPermission() async {
    Permission permission = await _getRequiredPermission();
    var status = await permission.request();
    setState(() {
      _permissionGranted = status.isGranted;
    });
    if (status.isGranted) {
      _createAppFolder();
      _scanDeviceForPdfs();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'permission_title'),
          style: TextStyle(color: Color(0xFFD32F2F))
        ),
        content: Text(AppTranslations.translate(context, 'permission_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate(context, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(AppTranslations.translate(context, 'grant_permission'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _scanDeviceForPdfs() async {
    setState(() {
      _isLoading = true;
      _pdfFiles.clear();
    });

    try {
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
        (await getExternalStorageDirectory())?.path,
      ];

      for (var path in commonPaths) {
        if (path != null) {
          await _scanDirectory(path);
        }
      }
    } catch (e) {
      // Hata yok say
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final entities = dir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            if (!_pdfFiles.contains(entity.path)) {
              setState(() {
                _pdfFiles.add(entity.path);
              });
            }
          }
        }
      }
    } catch (e) {
      // Erişim hatası vs. olabilir, yoksay
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        await _addToRecents(filePath);
        _openViewer(filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçilirken hata: $e')),
      );
    }
  }

  void _openViewer(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya bulunamadı: ${p.basename(path)}')),
        );
        return;
      }

      await _addToRecents(path);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewerScreen(
            file: file,
            fileName: p.basename(path),
            languageManager: widget.languageManager,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF açılırken hata: $e')),
      );
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareFiles([filePath], text: 'PDF Dosyası');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paylaşım hatası: $e')),
      );
    }
  }

  Future<void> _printFile(String filePath) async {
    try {
      final file = File(filePath);
      final data = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) => data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yazdırma hatası: $e')),
      );
    }
  }

  Future<void> _deleteFile(String filePath) async {
    final fileName = p.basename(filePath);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate(context, 'delete_title')),
        content: Text('"$fileName" ${AppTranslations.translate(context, 'delete_message')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate(context, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final file = File(filePath);
                await file.delete();
                setState(() {
                  _pdfFiles.remove(filePath);
                  _favoriteFiles.remove(filePath);
                  _recentFiles.remove(filePath);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dosya silindi: $fileName')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silme hatası: $e')),
                );
              }
            },
            child: Text(AppTranslations.translate(context, 'confirm_delete'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        Future.delayed(Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      _addToSearchHistory(query.trim());
    }
    setState(() {});
  }

  Widget _buildHomeContent() {
    return TabBarView(
      controller: _homeSubTabController,
      physics: null, 
      children: [
        _buildDeviceFiles(),
        _buildRecentFiles(),
        _buildFavorites(),
      ],
    );
  }

  Widget _buildDeviceFiles() {
    List<String> displayedFiles = _pdfFiles;
    final searchQuery = _searchController.text.trim().toLowerCase();
    
    if (_isSearchMode && searchQuery.isNotEmpty) {
      displayedFiles = _pdfFiles.where((file) => 
        p.basename(file).toLowerCase().contains(searchQuery)
      ).toList();
    }

    if (!_permissionGranted) {
      return _buildPermissionRequest();
    }
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (displayedFiles.isEmpty) {
      return _buildEmptyState();
    }
    return _buildPdfList(displayedFiles);
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppTranslations.translate(context, 'permission_title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
            ),
            SizedBox(height: 8),
            Text(
              AppTranslations.translate(context, 'permission_message'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(AppTranslations.translate(context, 'grant_permission')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFD32F2F)),
          SizedBox(height: 16),
          Text('PDF dosyaları taranıyor...', style: TextStyle(color: Color(0xFFD32F2F))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _isSearchMode && _searchController.text.isNotEmpty 
                ? AppTranslations.translate(context, 'search_history')
                : AppTranslations.translate(context, 'no_files'),
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _scanDeviceForPdfs,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            child: Text(AppTranslations.translate(context, 'scan_again'), style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: _pickPdfFile,
            child: Text(AppTranslations.translate(context, 'pick_file'), style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfList(List<String> files) {
    return Column(
      children: [
        if (_isSearchMode && _searchHistory.isNotEmpty)
          _buildSearchHistory(),
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (_, i) => _buildFileItem(files[i], false),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.translate(context, 'search_history'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    AppTranslations.translate(context, 'clear'),
                    style: TextStyle(color: Colors.grey)
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) => ActionChip(
                label: Text(query),
                onPressed: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
                backgroundColor: Color(0xFFF5F5F5),
                labelStyle: TextStyle(color: Color(0xFFD32F2F)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(String filePath, bool isFavorite) {
    final fileName = p.basename(filePath);
    final isFavorited = _favoriteFiles.contains(filePath);
    final file = File(filePath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final modifiedDate = file.existsSync() ? file.lastModifiedSync() : DateTime.now();

    String formatFileSize(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }

    String formatDate(DateTime date) {
      return '${date.day}.${date.month}.${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
        ),
        title: Text(fileName, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2),
            Text(
              '${formatFileSize(fileSize)} - ${formatDate(modifiedDate)}',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        onTap: () => _openViewer(filePath),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFavorited ? Icons.star : Icons.star_border,
                color: isFavorited ? Colors.amber : Colors.grey,
              ),
              onPressed: () {
                if (isFavorited) {
                  _removeFromFavorites(filePath);
                } else {
                  _addToFavorites(filePath);
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleFileAction(value, filePath),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(value: 'share', child: Text(AppTranslations.translate(context, 'share'))),
                PopupMenuItem(value: 'rename', child: Text(AppTranslations.translate(context, 'rename'))),
                PopupMenuItem(value: 'print', child: Text(AppTranslations.translate(context, 'print'))),
                PopupMenuItem(value: 'delete', child: Text(AppTranslations.translate(context, 'delete'), style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileAction(String action, String filePath) {
    switch (action) {
      case 'share':
        _shareFile(filePath);
        break;
      case 'print':
        _printFile(filePath);
        break;
      case 'delete':
        _deleteFile(filePath);
        break;
      case 'rename':
        _showRenameDialog(filePath);
        break;
    }
  }

  void _showRenameDialog(String filePath) {
    final fileName = p.basename(filePath);
    final TextEditingController renameController = TextEditingController(text: p.withoutExtension(fileName));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate(context, 'rename')),
        content: TextField(
          controller: renameController,
          decoration: InputDecoration(
            labelText: 'Yeni dosya adı',
            suffixText: '.pdf',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate(context, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            onPressed: () async {
              final newName = '${renameController.text}.pdf';
              final newPath = '${p.dirname(filePath)}/$newName';
              
              try {
                await File(filePath).rename(newPath);
                setState(() {
                  final index = _pdfFiles.indexOf(filePath);
                  if (index != -1) {
                    _pdfFiles[index] = newPath;
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dosya yeniden adlandırıldı')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Yeniden adlandırma hatası: $e')),
                );
              }
            },
            child: Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFiles() {
    if (_recentFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppTranslations.translate(context, 'no_recent'),
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'PDF dosyalarını açtıkça burada görünecekler.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _recentFiles.length,
      itemBuilder: (_, i) => _buildFileItem(_recentFiles[i], false),
    );
  }

  Widget _buildFavorites() {
    if (_favoriteFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppTranslations.translate(context, 'no_favorites'),
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Beğendiğiniz dosyaları yıldız simgesine tıklayarak\nfavorilere ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _favoriteFiles.length,
      itemBuilder: (_, i) => _buildFileItem(_favoriteFiles[i], true),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Yakında eklenecek! 🚀'),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }

  Widget _buildFilesTab() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            AppTranslations.translate(context, 'files'),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            AppTranslations.translate(context, 'cloud_storage'),
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)
          ),
        ),
        _buildCloudItem('Google Drive', 'assets/icon/drive.png', false, () => _launchCloudService('Google Drive')),
        _buildCloudItem('OneDrive', 'assets/icon/onedrive.png', false, () => _launchCloudService('OneDrive')),
        _buildCloudItem('Dropbox', 'assets/icon/dropbox.png', false, () => _launchCloudService('Dropbox')),
        
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            AppTranslations.translate(context, 'email_integration'),
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)
          ),
        ),
        _buildGmailItem(),
        
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: _buildCloudItem(
            AppTranslations.translate(context, 'more_files'),
            Icons.folder_open,
            true,
            _pickPdfFile
          ),
        ),
      ],
    );
  }

  Future<void> _launchCloudService(String service) async {
    final urls = {
      'Google Drive': 'https://drive.google.com',
      'OneDrive': 'https://onedrive.live.com',
      'Dropbox': 'https://www.dropbox.com',
      'Gmail': 'https://gmail.com',
    };
    if (urls.containsKey(service)) {
      final url = Uri.parse(urls[service]!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showComingSoon(service);
      }
    }
  }

  Widget _buildCloudItem(String title, dynamic icon, bool isIcon, Function onTap) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: isIcon 
            ? Icon(icon as IconData, size: 24, color: Color(0xFFD32F2F))
            : Image.asset(icon as String, width: 24, height: 24),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.add, color: Color(0xFFD32F2F)),
        onTap: () => onTap(),
      ),
    );
  }

  Widget _buildGmailItem() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Image.asset('assets/icon/gmail.png', width: 24, height: 24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('E-postalardaki PDF\'ler', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('Gmail', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Icon(Icons.add, color: Color(0xFFD32F2F)),
        onTap: () => _launchCloudService('Gmail'),
      ),
    );
  }

  Widget _buildFabMenu() {
    if (_currentTabIndex != 0) return SizedBox.shrink();

    return Stack(
      children: [
        if (_isFabOpen) ...[
          Positioned(
            bottom: 70,
            right: 0,
            child: Column(
              children: [
                _buildSubFabItem(AppTranslations.translate(context, 'pick_file'), Icons.attach_file, _pickPdfFile),
                SizedBox(height: 12),
                _buildSubFabItem(AppTranslations.translate(context, 'scan'), Icons.document_scanner, () => _showComingSoon('Tarama')),
                SizedBox(height: 12),
                _buildSubFabItem('Görsel', Icons.image, () => _showComingSoon('Görselden PDF')),
              ],
            ),
          ),
        ],
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: _isFabOpen ? Color(0xFFB71C1C) : Color(0xFFD32F2F),
            onPressed: _toggleFab,
            child: AnimatedRotation(
              turns: _isFabOpen ? 0.125 : 0,
              duration: Duration(milliseconds: 300),
              child: Icon(_isFabOpen ? Icons.close : Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubFabItem(String text, IconData icon, Function onTap) {
    return GestureDetector(
      onTap: () {
        _toggleFab();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 20, color: Color(0xFFD32F2F)),
            ),
            SizedBox(width: 8),
            Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFD32F2F))),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 160, 
            decoration: BoxDecoration(
              color: Color(0xFFD32F2F),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      child: Image.asset('assets/icon/logo.png', width: 32, height: 32),
                    ),
                    SizedBox(height: 12),
                    Text('Dev Software', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('PDF Reader - Görüntüleyici & Editör', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          _buildDrawerItem(Icons.info, AppTranslations.translate(context, 'about'), _showAboutDialog),
          _buildDrawerItem(Icons.help, AppTranslations.translate(context, 'help'), _showHelpSupport),
          Divider(),
          _buildDrawerSubItem(AppTranslations.translate(context, 'app_language'), _showAppLanguageDialog),
          _buildDrawerSubItem(AppTranslations.translate(context, 'privacy'), _showPrivacyPolicy),
        ],
      ),
    );
  }

  void _showAppLanguageDialog() {
    final languageList = widget.languageManager.getLanguageList();
    final currentLang = widget.languageManager.currentLanguage;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'app_language'),
          style: TextStyle(color: Color(0xFFD32F2F))
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languageList.length,
            itemBuilder: (context, index) {
              final lang = languageList[index];
              return ListTile(
                title: Text(lang['name']!),
                trailing: currentLang == lang['code']
                    ? Icon(Icons.check, color: Color(0xFFD32F2F))
                    : null,
                onTap: () async {
                  await widget.languageManager.setLanguage(lang['code']!);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${lang['name']} - Dil değiştirildi! ✅'),
                      backgroundColor: Color(0xFFD32F2F),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(color: Color(0xFFD32F2F))
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    final TextEditingController messageController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'help'),
          style: TextStyle(color: Color(0xFFD32F2F))
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sorununuzu veya önerinizi bize iletin:'),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta Adresiniz',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Mesajınız',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate(context, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            onPressed: () {
              if (messageController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                );
                return;
              }
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'devsoftwaremail@gmail.com',
                queryParameters: {
                  'subject': 'PDF Reader Destek Talebi',
                  'body': 'E-posta: ${emailController.text}\n\nMesaj: ${messageController.text}',
                },
              );
              launchUrl(emailLaunchUri);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mesajınız e-posta uygulamasına yönlendiriliyor...')),
              );
            },
            child: Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'privacy_policy'),
          style: TextStyle(color: Color(0xFFD32F2F))
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu uygulama kullanıcı gizliliği ve güvenliği ilkesini benimseyerek geliştirilmiştir. Daha fazla bilgi için gizlilik politikamıza göz atın.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://docs.google.com/document/d/1nvIEnIz0nKCNHdiVMNw2-iMltjMxZwaw5TuPVKWLn4M/edit?usp=sharing');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Text(
                  AppTranslations.translate(context, 'privacy_policy'),
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(color: Color(0xFFD32F2F))
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'about'),
          style: TextStyle(color: Color(0xFFD32F2F))
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PDF Reader v1.0.1', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Gelişmiş PDF görüntüleme ve yönetim uygulaması.'),
              SizedBox(height: 16),
              Text('Kullanılan Teknolojiler:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Flutter + Dart'),
              Text('• PDF.js'),
              Text('• HTML5 + WEB Kütüphaneleri'),
              SizedBox(height: 16),
              Text('© 2024 Dev Software'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(color: Color(0xFFD32F2F))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Function onTap) {
    return ListTile(
      leading: Icon(icon, size: 24, color: Color(0xFFD32F2F)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildDrawerSubItem(String title, Function onTap) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Color(0xFFD32F2F),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: _toggleSearchMode,
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: AppTranslations.translate(context, 'search_hint'),
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: _performSearch,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: Text(_tabTitles[_currentTabIndex]),
      actions: [
        if (_currentTabIndex == 0) ...[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _toggleSearchMode,
          ),
        ],
        IconButton(
          icon: Image.asset('assets/icon/logo.png', width: 24, height: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
      bottom: _currentTabIndex == 0 
          ? PreferredSize(
              preferredSize: Size.fromHeight(48.0),
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.white,
                child: TabBar(
                  controller: _homeSubTabController,
                  tabs: _homeTabTitles.map((title) => Tab(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Color(0xFFD32F2F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                  indicatorColor: Color(0xFFD32F2F),
                  labelColor: Color(0xFFD32F2F),
                  unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? Colors.grey[800] : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent, 
      ),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _isSearchMode ? _buildSearchAppBar() : _buildNormalAppBar(),
        drawer: _buildDrawer(),
        body: TabBarView(
          controller: _mainTabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildHomeContent(),
            ToolsScreen(
              onPickFile: _pickPdfFile,
              languageManager: widget.languageManager,
            ),
            _buildFilesTab(),
          ],
        ),
        floatingActionButton: _buildFabMenu(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            _mainTabController.animateTo(index);
            setState(() => _currentTabIndex = index);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: AppTranslations.translate(context, 'home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: AppTranslations.translate(context, 'tools'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: AppTranslations.translate(context, 'files'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _homeSubTabController.dispose();
    _database?.close();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}

class ViewerScreen extends StatefulWidget {
  final File? file;
  final String? fileUri;
  final String fileName;
  final LanguageManager languageManager;

  const ViewerScreen({
    super.key,
    this.file,
    this.fileUri,
    required this.fileName,
    required this.languageManager,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  InAppWebViewController? _controller;
  bool _loaded = false;
  double _progress = 0;

  String _viewerUrl() {
    try {
      String fileUri;
      if (widget.fileUri != null) {
        fileUri = widget.fileUri!;
      } else if (widget.file != null) {
        fileUri = Uri.file(widget.file!.path).toString();
      } else {
        throw Exception('No file or URI provided');
      }
      final encodedFileUri = Uri.encodeComponent(fileUri);
      
      // WebView dil parametresini ekle
      final langParam = widget.languageManager.webViewLangCode;
      final viewerUrl = 'file:///android_asset/flutter_assets/assets/web/viewer.html?file=$encodedFileUri&lang=$langParam';
      
      print('WebView URL with lang: $viewerUrl');
      return viewerUrl;
    } catch (e) {
      final langParam = widget.languageManager.webViewLangCode;
      return 'file:///android_asset/flutter_assets/assets/web/viewer.html?lang=$langParam';
    }
  }

  Future<void> _saveEditedPdfToDownloads(String filename, String base64Data) async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download/PDF Reader');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // "update_" prefix ile yeni dosya adı oluştur
      String baseName = p.basenameWithoutExtension(filename);
      
      if (baseName.toLowerCase().startsWith('update_')) {
        baseName = baseName.substring(7);
      }
      
      final newFileName = 'update_$baseName.pdf';
      final filePath = '${downloadDir.path}/$newFileName';

      final bytes = base64Decode(base64Data);
      await File(filePath).writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF başarıyla kaydedildi: $newFileName'),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('📁 PDF kaydedildi: $filePath');
    } catch (e) {
      print('❌ PDF kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ PDF kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, style: TextStyle(fontSize: 16)),
        backgroundColor: Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              if (widget.file != null) {
                Share.shareFiles([widget.file!.path], text: 'PDF Dosyası');
              } else if (widget.fileUri != null) {
                 Share.shareFiles([widget.fileUri!], text: 'PDF Dosyası');
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              if (widget.file != null) {
                final data = await widget.file!.readAsBytes();
                await Printing.layoutPdf(onLayout: (_) => data);
              } else if (widget.fileUri != null) {
                final file = File(widget.fileUri!);
                if (await file.exists()) {
                   final data = await file.readAsBytes();
                   await Printing.layoutPdf(onLayout: (_) => data);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_loaded && _progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
            ),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_viewerUrl())),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    allowFileAccess: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    supportZoom: true,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    
                    controller.addJavaScriptHandler(
                      handlerName: 'onPdfSaved',
                      callback: (args) {
                        if (args.length >= 2) {
                          final filename = args[0] as String;
                          final base64Data = args[1] as String;
                          _saveEditedPdfToDownloads(filename, base64Data);
                        }
                        return {};
                      },
                    );
                    
                    widget.languageManager.addListener(() {
                      final newUrl = _viewerUrl();
                      controller.loadUrl(urlRequest: URLRequest(url: WebUri(newUrl)));
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      _loaded = true;
                      _progress = 1.0;
                    });
                  },
                ),
                if (!_loaded)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD32F2F)),
                        SizedBox(height: 20),
                        Text('PDF Yükleniyor...', style: TextStyle(color: Color(0xFFD32F2F))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
