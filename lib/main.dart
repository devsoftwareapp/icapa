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
import 'package:provider/provider.dart'; // ← IMPORT EN ÜSTTE

// Import generated localization
import 'gen/l10n.dart';
import 'tools_screen.dart';
import 'app_languages.dart';

// Intent handling için
final MethodChannel _intentChannel = MethodChannel('app.channel.shared/data');
final MethodChannel _pdfViewerChannel = MethodChannel('pdf_viewer_channel');

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

class PdfManagerApp extends StatelessWidget {
  final Map<String, dynamic>? initialIntent;
  final ThemeManager _themeManager = ThemeManager();
  final LanguageProvider _languageProvider = LanguageProvider();

  PdfManagerApp({super.key, this.initialIntent});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LanguageProvider>(
      create: (context) => _languageProvider,
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return FutureBuilder<Locale>(
            future: _getInitialLocale(languageProvider),
            builder: (context, snapshot) {
              final locale = snapshot.data ?? const Locale('en');
              
              return MaterialApp(
                title: 'PDF Reader',
                debugShowCheckedModeBanner: false,
                
                // Localization ayarları - ARTIK AÇIK
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                
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
                home: HomePage(initialIntent: initialIntent),
              );
            },
          );
        },
      ),
    );
  }

  Future<Locale> _getInitialLocale(LanguageProvider languageProvider) async {
    await languageProvider.loadLanguage();
    return languageProvider.currentLocale;
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? initialIntent;

  const HomePage({super.key, this.initialIntent});

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
  final ThemeManager _themeManager = ThemeManager();

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
          SnackBar(content: Text('❌ ${AppLocalizations.of(context).pdfOpenError}: $e')),
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
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${AppLocalizations.of(context).pdfOpenError}: $e')),
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
        title: Text(AppLocalizations.of(context).permissionRequired, style: TextStyle(color: Color(0xFFD32F2F))),
        content: Text(AppLocalizations.of(context).fileAccessPermission),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(AppLocalizations.of(context).goToSettings, style: TextStyle(color: Colors.white)),
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
        SnackBar(content: Text('${AppLocalizations.of(context).fileSelection} hatası: $e')),
      );
    }
  }

  void _openViewer(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).fileNotFound}: ${p.basename(path)}')),
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
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).pdfOpenError}: $e')),
      );
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareFiles([filePath], text: 'PDF Dosyası');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fileShared)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).fileShareError}: $e')),
      );
    }
  }

  Future<void> _printFile(String filePath) async {
    try {
      final file = File(filePath);
      final data = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) => data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).filePrinted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).printError}: $e')),
      );
    }
  }

  Future<void> _deleteFile(String filePath) async {
    final fileName = p.basename(filePath);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDelete),
        content: Text(AppLocalizations.of(context).deleteConfirmation.replaceFirst('{fileName}', fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
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
                  SnackBar(content: Text('${AppLocalizations.of(context).fileDeleted}: $fileName')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${AppLocalizations.of(context).deleteError}: $e')),
                );
              }
            },
            child: Text(AppLocalizations.of(context).delete, style: TextStyle(color: Colors.white)),
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
              AppLocalizations.of(context).permissionRequired,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).fileAccessPermission,
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
              child: Text(AppLocalizations.of(context).grantPermission),
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
          Text(AppLocalizations.of(context).loading, style: TextStyle(color: Color(0xFFD32F2F))),
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
                ? AppLocalizations.of(context).noResults
                : AppLocalizations.of(context).noPdfFiles,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _scanDeviceForPdfs,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            child: Text(AppLocalizations.of(context).scanAgain, style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: _pickPdfFile,
            child: Text(AppLocalizations.of(context).selectFile, style: TextStyle(color: Color(0xFFD32F2F))),
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
                Text(AppLocalizations.of(context).searchHistory, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(AppLocalizations.of(context).clearHistory, style: TextStyle(color: Colors.grey)),
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
                PopupMenuItem(value: 'share', child: Text(AppLocalizations.of(context).share)),
                PopupMenuItem(value: 'rename', child: Text(AppLocalizations.of(context).rename)),
                PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context).print)),
                PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context).delete, style: TextStyle(color: Colors.red))),
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
        title: Text(AppLocalizations.of(context).confirmRename),
        content: TextField(
          controller: renameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).newFileName,
            suffixText: '.pdf',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
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
                  SnackBar(content: Text(AppLocalizations.of(context).fileRenamed)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${AppLocalizations.of(context).renameError}: $e')),
                );
              }
            },
            child: Text(AppLocalizations.of(context).save, style: TextStyle(color: Colors.white)),
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
              AppLocalizations.of(context).noRecentFiles,
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
              AppLocalizations.of(context).noFavorites,
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
        content: Text('$feature - ${AppLocalizations.of(context).comingSoon}! 🚀'),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }

  Widget _buildFilesTab() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context).files, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(AppLocalizations.of(context).cloudStorage, style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        _buildCloudItem(AppLocalizations.of(context).googleDrive, 'assets/icon/drive.png', false, () => _launchCloudService(AppLocalizations.of(context).googleDrive)),
        _buildCloudItem(AppLocalizations.of(context).oneDrive, 'assets/icon/onedrive.png', false, () => _launchCloudService(AppLocalizations.of(context).oneDrive)),
        _buildCloudItem(AppLocalizations.of(context).dropbox, 'assets/icon/dropbox.png', false, () => _launchCloudService(AppLocalizations.of(context).dropbox)),
        
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(AppLocalizations.of(context).emailIntegration, style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        _buildGmailItem(),
        
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: _buildCloudItem(AppLocalizations.of(context).browseForMoreFiles, Icons.folder_open, true, _pickPdfFile),
        ),
      ],
    );
  }

  Future<void> _launchCloudService(String service) async {
    final urls = {
      AppLocalizations.of(context).googleDrive: 'https://drive.google.com',
      AppLocalizations.of(context).oneDrive: 'https://onedrive.live.com',
      AppLocalizations.of(context).dropbox: 'https://www.dropbox.com',
      AppLocalizations.of(context).gmail: 'https://gmail.com',
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
            Text(AppLocalizations.of(context).pdfsFromEmails, style: TextStyle(fontWeight: FontWeight.w500)),
            Text(AppLocalizations.of(context).gmail, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Icon(Icons.add, color: Color(0xFFD32F2F)),
        onTap: () => _launchCloudService(AppLocalizations.of(context).gmail),
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
                _buildSubFabItem(AppLocalizations.of(context).selectFile, Icons.attach_file, _pickPdfFile),
                SizedBox(height: 12),
                _buildSubFabItem(AppLocalizations.of(context).scan, Icons.document_scanner, () => _showComingSoon('Tarama')),
                SizedBox(height: 12),
                _buildSubFabItem(AppLocalizations.of(context).fromImage, Icons.image, () => _showComingSoon('Görselden PDF')),
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
                    Text(AppLocalizations.of(context).appSubtitle, style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          
          // DİL SEÇİMİ BÖLÜMÜ
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return ExpansionTile(
                leading: Icon(Icons.language, color: Color(0xFFD32F2F)),
                title: Text(AppLocalizations.of(context).languages),
                children: [
                  LanguageDialogContent(languageProvider: languageProvider),
                ],
              );
            },
          ),

          _buildDrawerItem(Icons.info, AppLocalizations.of(context).about, _showAboutDialog),
          _buildDrawerItem(Icons.help, AppLocalizations.of(context).helpAndSupport, _showHelpSupport),
          Divider(),
          _buildDrawerSubItem(AppLocalizations.of(context).privacy, _showPrivacyPolicy),
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
        title: Text(AppLocalizations.of(context).helpSupport, style: TextStyle(color: Color(0xFFD32F2F))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).describeIssue),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).yourEmail,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).yourMessage,
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
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            onPressed: () {
              if (messageController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).fillAllFields)),
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
                SnackBar(content: Text(AppLocalizations.of(context).messageRedirecting)),
              );
            },
            child: Text(AppLocalizations.of(context).send, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showComingSoon(AppLocalizations.of(context).privacyPolicy);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).aboutPdfReader, style: TextStyle(color: Color(0xFFD32F2F))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocalizations.of(context).appTitle} v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(AppLocalizations.of(context).advancedPdfViewing),
              SizedBox(height: 16),
              Text('© 2024 Dev Software'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close, style: TextStyle(color: Color(0xFFD32F2F))),
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
          hintText: AppLocalizations.of(context).searchPdfs,
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
    final appLocalizations = AppLocalizations.of(context);
    
    final List<String> tabTitles = [appLocalizations.home, appLocalizations.tools, appLocalizations.files];
    final List<String> homeTabTitles = [appLocalizations.onDevice, appLocalizations.recent, appLocalizations.favorites];

    return AppBar(
      title: Text(tabTitles[_currentTabIndex]),
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
                  tabs: homeTabTitles.map((title) => Tab(
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
            ToolsScreen(onPickFile: _pickPdfFile),
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
              label: AppLocalizations.of(context).home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: AppLocalizations.of(context).tools,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: AppLocalizations.of(context).files,
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

  const ViewerScreen({
    super.key,
    this.file,
    this.fileUri,
    required this.fileName,
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
      final viewerUrl = 'file:///android_asset/flutter_assets/assets/web/viewer.html?file=$encodedFileUri';
      return viewerUrl;
    } catch (e) {
      return 'file:///android_asset/flutter_assets/assets/web/viewer.html';
    }
  }

  // PDF kaydetme işlevi
  Future<void> _savePdf(String filename, String base64Data) async {
    try {
      // Base64 veriyi decode et
      final bytes = base64.decode(base64Data);
      
      // Kaydetme dizinini oluştur
      final downloadDir = Directory('/storage/emulated/0/Download/PDF Reader');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      // Yeni dosya adını oluştur (Saved_ öneki ile)
      String originalName = widget.fileName;
      if (originalName.toLowerCase().endsWith('.pdf')) {
        originalName = originalName.substring(0, originalName.length - 4);
      }
      final newFileName = 'Saved_$originalName.pdf';
      final filePath = '${downloadDir.path}/$newFileName';
      
      // Dosyayı kaydet
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).pdfSavedSuccess}: $newFileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('PDF saved to: $filePath');
      
    } catch (e) {
      print('PDF kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).pdfSaveError}: $e'),
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
                    
                    // JavaScript handler'ı ekle
                    controller.addJavaScriptHandler(
                      handlerName: 'onPdfSaved',
                      callback: (args) {
                        if (args.length >= 2) {
                          final filename = args[0] as String;
                          final base64Data = args[1] as String;
                          _savePdf(filename, base64Data);
                        }
                      },
                    );
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
                        Text(AppLocalizations.of(context).pdfLoading, style: TextStyle(color: Color(0xFFD32F2F))),
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

// LanguageDialogContent widget'ı
class LanguageDialogContent extends StatefulWidget {
  final LanguageProvider languageProvider;

  const LanguageDialogContent({super.key, required this.languageProvider});

  @override
  State<LanguageDialogContent> createState() => _LanguageDialogContentState();
}

class _LanguageDialogContentState extends State<LanguageDialogContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
        SizedBox(
          height: 300,
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
                      trailing: widget.languageProvider.currentLanguage?.code == language.code
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
