// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PdfReaderApp());
}

class PdfReaderApp extends StatelessWidget {
  const PdfReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFD32F2F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late InAppWebViewController _webViewController;
  bool _isLoading = true;

  String _getWebViewUrl() {
    return 'file:///android_asset/flutter_assets/assets/web/index.html';
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<Map<String, dynamic>> files = [];
        
        for (var file in result.files) {
          if (file.path != null) {
            // Dosyayı uygulama dizinine kopyala
            final appDir = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = file.name.replaceAll(RegExp(r'[^\w\s.-]'), '_');
            final newPath = '${appDir.path}/pdf_${timestamp}_$fileName';
            
            final sourceFile = File(file.path!);
            final destFile = File(newPath);
            
            try {
              await sourceFile.copy(destFile.path);
              
              files.add({
                'path': destFile.path,
                'name': fileName,
                'url': destFile.uri.toString(),
                'size': file.size,
                'date': DateTime.now().toIso8601String(),
              });
              
              print('📄 PDF kopyalandı: $fileName -> $newPath');
            } catch (e) {
              print('❌ Kopyalama hatası: $e');
            }
          }
        }
        
        // WebView'e dosyaları gönder
        if (files.isNotEmpty) {
          String jsonData = _convertToJson(files);
          await _webViewController.evaluateJavascript(source: '''
            if (typeof addPdfFiles === 'function') {
              addPdfFiles($jsonData);
            } else {
              console.error('addPdfFiles function not found');
            }
          ''');
        }
      }
    } catch (e) {
      print('❌ File picker error: $e');
    }
  }

  String _convertToJson(List<Map<String, dynamic>> files) {
    List<String> items = [];
    for (var file in files) {
      items.add('''
        {
          "path": "${file['path']}",
          "name": "${file['name']}",
          "url": "${file['url']}",
          "size": ${file['size'] ?? 0},
          "date": "${file['date']}"
        }
      ''');
    }
    return '[${items.join(',')}]';
  }

  void _openPdfViewer(String pdfPath, String pdfName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfPath: pdfPath,
          pdfName: pdfName,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  void _setupWebView() {
    // JavaScript handler'ları
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_getWebViewUrl())),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccess: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              supportZoom: true,
              clearCache: true,
              cacheMode: CacheMode.LOAD_DEFAULT,
              transparentBackground: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              print('✅ WebView created');
              
              // PDF açma handler'ı
              controller.addJavaScriptHandler(
                handlerName: 'openPdf',
                callback: (args) {
                  if (args.length >= 2) {
                    String pdfPath = args[0];
                    String pdfName = args[1];
                    _openPdfViewer(pdfPath, pdfName);
                  }
                  return {'success': true};
                },
              );
              
              // Dosya seçme handler'ı
              controller.addJavaScriptHandler(
                handlerName: 'pickFile',
                callback: (args) async {
                  await _pickPdfFile();
                  return {'success': true};
                },
              );
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
              print('✅ Index page loaded: $url');
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                _isLoading = false;
              });
              print('❌ Load error: $message');
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('🌐 Console: ${consoleMessage.message}');
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD32F2F)),
                    SizedBox(height: 20),
                    Text(
                      'PDF Reader Yükleniyor...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD32F2F),
        onPressed: _pickPdfFile,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.pdfName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late InAppWebViewController _webViewController;
  bool _isLoading = true;
  double _progress = 0;

  String _getViewerUrl() {
    // PDF.js viewer'ını kullan
    final encodedPath = Uri.encodeComponent(widget.pdfPath);
    return 'file:///android_asset/flutter_assets/assets/web/viewer.html?file=$encodedPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading && _progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
            ),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_getViewerUrl())),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    allowFileAccess: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    supportZoom: true,
                    clearCache: true,
                  ),
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                    });
                    print('📖 PDF yükleniyor: ${widget.pdfPath}');
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      _isLoading = false;
                    });
                    print('✅ PDF yüklendi: ${widget.pdfName}');
                  },
                  onLoadError: (controller, url, code, message) {
                    setState(() {
                      _isLoading = false;
                    });
                    print('❌ PDF load error: $message');
                    
                    // Fallback
                    controller.evaluateJavascript(source: '''
                      try {
                        if (typeof PDFViewerApplication !== 'undefined') {
                          PDFViewerApplication.open('file://${widget.pdfPath}');
                        }
                      } catch(e) {
                        console.error('PDF açma hatası:', e);
                      }
                    ''');
                  },
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD32F2F)),
                        SizedBox(height: 20),
                        Text('PDF yükleniyor...'),
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
