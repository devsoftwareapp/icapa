// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:file_picker/file_picker.dart';

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
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;
        
        // WebView'e dosyayı gönder
        await _webViewController.evaluateJavascript(source: '''
          if (typeof addPdfFile === 'function') {
            addPdfFile('$filePath', '$fileName');
          } else {
            console.log('addPdfFile function not found');
          }
        ''');
      }
    } catch (e) {
      print('File picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reader'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickPdfFile,
            tooltip: 'PDF Ekle',
          ),
        ],
      ),
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
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              print('✅ WebView created: ${_getWebViewUrl()}');
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
              print('✅ Index page loaded successfully');
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
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD32F2F)),
                  SizedBox(height: 20),
                  Text('PDF Reader yükleniyor...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
