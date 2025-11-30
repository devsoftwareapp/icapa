// lib/gen/l10n.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // ✅ BU SATIRLARI EKLEYİN:
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('tr'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('zh'),
    Locale('hi'),
    Locale('ar'),
    Locale('ru'),
    Locale('pt'),
    Locale('id'),
    Locale('ur'),
    Locale('ja'),
    Locale('sw'),
    Locale('bn'),
    Locale('fi'), // Kurmanci
    Locale('cs'), // Zazaki
  ];

  // Hardcoded strings - tüm diller için İngilizce
  String get appTitle => "PDF Reader";
  String get appSubtitle => "Advanced PDF Manager";
  String get home => "Home";
  String get tools => "Tools";
  String get files => "Files";
  String get searchPdfs => "Search PDFs";
  String get scan => "Scan";
  String get fromImage => "From Image";
  String get selectFile => "Select File";
  String get permissionRequired => "Permission Required";
  String get fileAccessPermission => "File access permission is required to scan for PDF files on your device.";
  String get grantPermission => "Grant Permission";
  String get goToSettings => "Go to Settings";
  String get cancel => "Cancel";
  String get share => "Share";
  String get rename => "Rename";
  String get print => "Print";
  String get delete => "Delete";
  String get confirmDelete => "Confirm Delete";
  String get deleteConfirmation => "Are you sure you want to delete \"{fileName}\"?";
  String get fileDeleted => "File deleted";
  String get deleteError => "Delete error";
  String get fileShared => "File shared";
  String get fileShareError => "File share error";
  String get filePrinted => "File printed";
  String get printError => "Print error";
  String get confirmRename => "Confirm Rename";
  String get newFileName => "New file name";
  String get fileRenamed => "File renamed";
  String get renameError => "Rename error";
  String get save => "Save";
  String get searchHistory => "Search History";
  String get clearHistory => "Clear History";
  String get recent => "Recent";
  String get favorites => "Favorites";
  String get noRecentFiles => "No recent files";
  String get noFavorites => "No favorites";
  String get onDevice => "On Device";
  String get comingSoon => "Coming Soon";
  String get cloudStorage => "Cloud Storage";
  String get googleDrive => "Google Drive";
  String get oneDrive => "OneDrive";
  String get dropbox => "Dropbox";
  String get emailIntegration => "Email Integration";
  String get pdfsFromEmails => "PDFs from Emails";
  String get gmail => "Gmail";
  String get browseForMoreFiles => "Browse for more files";
  String get about => "About";
  String get helpAndSupport => "Help & Support";
  String get languages => "Languages";
  String get privacy => "Privacy";
  String get aboutPdfReader => "About PDF Reader";
  String get advancedPdfViewing => "Advanced PDF viewing and management";
  String get close => "Close";
  String get helpSupport => "Help & Support";
  String get describeIssue => "Describe your issue";
  String get yourEmail => "Your Email";
  String get yourMessage => "Your Message";
  String get fillAllFields => "Please fill all fields";
  String get send => "Send";
  String get messageRedirecting => "Message redirecting to email app";
  String get searchLanguage => "Search language";
  String get noLanguageFound => "No language found";
  String get fileSelection => "File selection";
  String get fileNotFound => "File not found";
  String get pdfOpenError => "PDF open error";
  String get pdfLoading => "PDF Loading";
  String get pdfSavedSuccess => "PDF saved successfully";
  String get pdfSaveError => "PDF save error";
  String get privacyPolicy => "Privacy Policy";
  String get noResults => "No results found";
  String get noPdfFiles => "No PDF files found";
  String get loading => "Loading";
  String get scanAgain => "Scan Again";
  String get systemLanguage => "System Language";
  String get sameAsDevice => "Same as device";
  String get languageChangeRestart => "Language changed. Restart the app for changes to take effect.";
  String get restart => "Restart";
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
