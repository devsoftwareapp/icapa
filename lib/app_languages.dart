// lib/app_languages.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import generated localization
import 'gen/l10n.dart';

// Dil veri modeli - Ayrı bir class olarak
class Language {
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

class AppLanguages {
  // Desteklenen diller listesi - ARB dosya isimlerine göre
  static final List<Language> supportedLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    Language(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷'),
    Language(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili', flag: '🇹🇿'),
    Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
    Language(code: 'fi', name: 'Kurmanci', nativeName: 'Kurdî - Zarava Kurmancî', flag: '🇫🇮'),
    Language(code: 'cs', name: 'Zazakî', nativeName: 'Kurdî - Zarava Zazakî', flag: '🇿🇼'),
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
        print('✅ Kullanıcı tercihi: $savedLanguage');
        return savedLanguage;
      }
    }
    
    // Sistem dilini al (kullanıcı tercihi yoksa)
    final String systemLanguage = _getSystemLanguage();
    if (_isLanguageSupported(systemLanguage)) {
      print('✅ Sistem dili: $systemLanguage');
      return systemLanguage;
    }
    
    // Varsayılan dil
    print('✅ Varsayılan dil: en');
    return 'en';
  }

  // Sistem dilini al
  static String _getSystemLanguage() {
    try {
      final String systemLocale = Platform.localeName;
      print('🔍 Sistem locale: $systemLocale');
      
      final String systemLanguageCode = systemLocale.split('_')[0].toLowerCase();
      
      // Sistem dilini desteklenen dillerde ara
      for (var lang in supportedLanguages) {
        if (lang.code.toLowerCase() == systemLanguageCode) {
          return lang.code;
        }
      }
      
      // Sistem diline en yakın dili bul
      for (var lang in supportedLanguages) {
        if (systemLanguageCode.startsWith(lang.code.toLowerCase()) || 
            lang.code.toLowerCase().startsWith(systemLanguageCode)) {
          return lang.code;
        }
      }
      
    } catch (e) {
      print('❌ Sistem dili alınamadı: $e');
    }
    
    return 'en';
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
    print('✅ Dil değiştirildi: $languageCode');
  }

  // Kullanıcı seçimini sıfırla (sistem diline dön)
  static Future<void> resetToSystemLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLanguageKey);
    await prefs.setBool(_userHasSelectedLanguageKey, false);
    print('✅ Sistem diline dönüldü');
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
  static ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

  // Dil değişikliğini bildir
  static Future<void> notifyLanguageChange() async {
    final String currentCode = await getCurrentLanguageCode();
    languageNotifier.value = currentCode;
  }

  // Locale dönüşümü için yardımcı metod
  static Locale getLocaleFromCode(String code) {
    // Basit dil kodundan Locale oluştur
    return Locale(code);
  }

  // Desteklenen Locale listesi - AppLocalizations'tan al
  static List<Locale> get supportedLocales {
    return AppLocalizations.supportedLocales;
  }

  // Kullanıcı dil seçimi yapmış mı kontrol et
  static Future<bool> get hasUserSelectedLanguage async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userHasSelectedLanguageKey) ?? false;
  }
}

// Dil değişikliği için provider
class LanguageProvider with ChangeNotifier {
  Language? _currentLanguage;
  Locale _currentLocale = const Locale('en');

  Language? get currentLanguage => _currentLanguage;
  Locale get currentLocale => _currentLocale;

  Future<void> loadLanguage() async {
    final String code = await AppLanguages.getCurrentLanguageCode();
    _currentLanguage = AppLanguages.getLanguageByCode(code);
    _currentLocale = AppLanguages.getLocaleFromCode(code);
    print('📱 Dil yüklendi: $code - $_currentLocale');
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    await AppLanguages.setLanguage(languageCode);
    _currentLanguage = AppLanguages.getLanguageByCode(languageCode);
    _currentLocale = AppLanguages.getLocaleFromCode(languageCode);
    AppLanguages.languageNotifier.value = languageCode;
    print('🔄 Dil değiştirildi: $languageCode - $_currentLocale');
    notifyListeners();
  }

  Future<void> resetToSystem() async {
    await AppLanguages.resetToSystemLanguage();
    await loadLanguage();
    AppLanguages.languageNotifier.value = _currentLanguage?.code ?? 'en';
    print('🔄 Sistem diline dönüldü');
  }
}

// Dil seçim dialogu
class LanguageDialog {
  static void show(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).languages,
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
              AppLocalizations.of(context).close,
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
  String _currentLanguage = 'en';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadCurrentLanguage() async {
    _currentLanguage = await AppLanguages.getCurrentLanguageCode();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = _searchQuery.isEmpty
        ? AppLanguages.supportedLanguages
        : AppLanguages.supportedLanguages.where((lang) =>
            lang.name.toLowerCase().contains(_searchQuery) ||
            lang.nativeName.toLowerCase().contains(_searchQuery) ||
            lang.code.toLowerCase().contains(_searchQuery))
        .toList();

    return Column(
      children: [
        // Arama kutusu
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).searchLanguage,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: filteredLanguages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).noLanguageFound,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    // Sistem Dili Seçeneği
                    FutureBuilder<bool>(
                      future: AppLanguages.hasUserSelectedLanguage,
                      builder: (context, snapshot) {
                        final hasUserSelection = snapshot.data ?? false;
                        return ListTile(
                          leading: Icon(Icons.language, color: Color(0xFFD32F2F)),
                          title: Text(
                            AppLocalizations.of(context).systemLanguage,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(AppLocalizations.of(context).sameAsDevice),
                          trailing: !hasUserSelection 
                              ? Icon(Icons.check, color: Color(0xFFD32F2F))
                              : null,
                          onTap: () async {
                            await widget.languageProvider.resetToSystem();
                            Navigator.pop(context);
                            _showRestartMessage(context);
                          },
                        );
                      },
                    ),
                    Divider(),
                    
                    // Desteklenen Diller
                    ...filteredLanguages.map((language) => ListTile(
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
                ),
        ),
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
                AppLocalizations.of(context).languageChangeRestart,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFD32F2F),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context).restart,
          textColor: Colors.white,
          onPressed: () {
            SystemNavigator.pop();
          },
        ),
      ),
    );
  }
}
