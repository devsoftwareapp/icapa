// lib/app_languages.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguages {
  // Dil veri modeli
  static class Language {
    final String code;
    final String name;
    final String nativeName;
    final String flag;

    const Language({
      required this.code,
      required this.name,
      required this.nativeName,
      required this.flag,
    });
  }

  // Desteklenen diller listesi
  static final List<Language> supportedLanguages = [
    Language(code: 'en_US', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    Language(code: 'tr_TR', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    Language(code: 'es_ES', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'fr_FR', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'de_DE', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'zh_CN', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    Language(code: 'hi_IN', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    Language(code: 'ar_AR', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    Language(code: 'ru_RU', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    Language(code: 'pt_BR', name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷'),
    Language(code: 'id_ID', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
    Language(code: 'ur_PK', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
    Language(code: 'ja_JP', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'sw_TZ', name: 'Swahili', nativeName: 'Kiswahili', flag: '🇹🇿'),
    Language(code: 'bn_BD', name: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
    Language(code: 'fi_FI', name: 'Kurmanci', nativeName: 'Kurdî - Zarava Kurmancî', flag: '🇫🇮'),
    Language(code: 'cs_CS', name: 'Zazakî', nativeName: 'Kurdî - Zarava Zazakî', flag: '🇿🇼'),
  ];

  // SharedPreferences anahtarı
  static const String _selectedLanguageKey = 'selected_language';
  static const String _userHasSelectedLanguageKey = 'user_has_selected_language';

  // Mevcut dil kodunu al
  static Future<String> getCurrentLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Kullanıcı daha önce dil seçmiş mi kontrol et
    final bool userHasSelected = prefs.getBool(_userHasSelectedLanguageKey) ?? false;
    
    if (userHasSelected) {
      // Kullanıcı seçimi öncelikli
      final String? savedLanguage = prefs.getString(_selectedLanguageKey);
      if (savedLanguage != null && _isLanguageSupported(savedLanguage)) {
        return savedLanguage;
      }
    }
    
    // Sistem dilini al
    final String systemLanguage = _getSystemLanguage();
    if (_isLanguageSupported(systemLanguage)) {
      return systemLanguage;
    }
    
    // Varsayılan dil
    return 'en_US';
  }

  // Sistem dilini al
  static String _getSystemLanguage() {
    final String systemLocale = Platform.localeName;
    final String systemLanguageCode = systemLocale.split('_')[0];
    
    // Sistem diline en yakın desteklenen dili bul
    for (var lang in supportedLanguages) {
      if (lang.code.startsWith(systemLanguageCode)) {
        return lang.code;
      }
    }
    
    return 'en_US';
  }

  // Dil destekleniyor mu kontrol et
  static bool _isLanguageSupported(String languageCode) {
    return supportedLanguages.any((lang) => lang.code == languageCode);
  }

  // Dil değiştir
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, languageCode);
    await prefs.setBool(_userHasSelectedLanguageKey, true);
  }

  // Kullanıcı seçimini sıfırla (sistem diline dön)
  static Future<void> resetToSystemLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLanguageKey);
    await prefs.setBool(_userHasSelectedLanguageKey, false);
  }

  // Dil kodundan dil objesi al
  static Language getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first, // fallback
    );
  }

  // Mevcut dil objesini al
  static Future<Language> getCurrentLanguage() async {
    final String code = await getCurrentLanguageCode();
    return getLanguageByCode(code);
  }

  // Dil değişikliği dinleyicisi
  static ValueNotifier<String> languageNotifier = ValueNotifier<String>('en_US');

  // Dil değişikliğini bildir
  static Future<void> notifyLanguageChange() async {
    final String currentCode = await getCurrentLanguageCode();
    languageNotifier.value = currentCode;
  }
}

// Dil değişikliği için provider
class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en_US';

  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage() async {
    _currentLanguage = await AppLanguages.getCurrentLanguageCode();
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    await AppLanguages.setLanguage(languageCode);
    _currentLanguage = languageCode;
    AppLanguages.languageNotifier.value = languageCode;
    notifyListeners();
  }

  Future<void> resetToSystem() async {
    await AppLanguages.resetToSystemLanguage();
    await loadLanguage();
    AppLanguages.languageNotifier.value = _currentLanguage;
  }
}

// Dil seçim dialogu
class LanguageDialog {
  static void show(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Uygulama Dili',
          style: TextStyle(
            color: Color(0xFFD32F2F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: _LanguageList(languageProvider: languageProvider),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageList extends StatefulWidget {
  final LanguageProvider languageProvider;

  const _LanguageList({required this.languageProvider});

  @override
  State<_LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<_LanguageList> {
  String _currentLanguage = 'en_US';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    _currentLanguage = await AppLanguages.getCurrentLanguageCode();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Sistem Dili Seçeneği
        ListTile(
          leading: Icon(Icons.language, color: Color(0xFFD32F2F)),
          title: Text(
            'Sistem Dili (Tavsiye)',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('Cihaz dilinizle aynı'),
          trailing: _currentLanguage == 'system' 
              ? Icon(Icons.check, color: Color(0xFFD32F2F))
              : null,
          onTap: () async {
            await widget.languageProvider.resetToSystem();
            Navigator.pop(context);
            _showRestartMessage(context);
          },
        ),
        Divider(),
        
        // Desteklenen Diller
        ...AppLanguages.supportedLanguages.map((language) => ListTile(
          leading: Text(
            language.flag,
            style: TextStyle(fontSize: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language.nativeName,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                language.name,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: _currentLanguage == language.code
              ? Icon(Icons.check, color: Color(0xFFD32F2F))
              : null,
          onTap: () async {
            await widget.languageProvider.changeLanguage(language.code);
            Navigator.pop(context);
            _showRestartMessage(context);
          },
        )).toList(),
      ],
    );
  }

  void _showRestartMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dil değişikliği uygulama yeniden başlatılınca etkili olacak',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFD32F2F),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Yeniden Başlat',
          textColor: Colors.white,
          onPressed: () {
            SystemNavigator.pop();
          },
        ),
      ),
    );
  }
}
