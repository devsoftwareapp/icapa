// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  
  runApp(PdfManagerApp());
}

class PdfManagerApp extends StatelessWidget {
  const PdfManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Reader',
      theme: ThemeData(primarySwatch: Colors.red),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _pdfFiles = [];
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  Future<void> _initDir() async {
    _currentPath = (await getApplicationDocumentsDirectory()).path;
    _scanFiles();
  }

  Future<void> _scanFiles() async {
    if (_currentPath == null) return;
    
    final dir = Directory(_currentPath!);
    if (await dir.exists()) {
      final entities = dir.listSync();
      final pdfPaths = entities
          .where((e) => e is File && e.path.toLowerCase().endsWith('.pdf'))
          .map((e) => e.path)
          .toList();
      
      setState(() => _pdfFiles = pdfPaths);
    }
  }

  Future<void> _importFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (res != null && res.files.single.path != null) {
      final path = res.files.single.path!;
      final imported = File(path);
      final newPath = p.join(_currentPath!, p.basename(path));
      await imported.copy(newPath);
      _scanFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF imported: ${p.basename(path)}')),
      );
    }
  }

  void _openViewer(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found: ${p.basename(path)}')),
        );
        return;
      }

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
        SnackBar(content: Text('Error opening PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Reader')),
      body: _pdfFiles.isEmpty
          ? const Center(child: Text('No PDF files found'))
          : ListView.builder(
              itemCount: _pdfFiles.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(p.basename(_pdfFiles[i])),
                onTap: () => _openViewer(_pdfFiles[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importFile,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ViewerScreen extends StatefulWidget {
  final File file;
  final String fileName;

  const ViewerScreen({
    super.key,
    required this.file,
    required this.fileName,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  InAppWebViewController? _controller;
  bool _loaded = false;

  String _viewerUrl() {
    try {
      String fileUri = Uri.file(widget.file.path).toString();
      final encodedFileUri = Uri.encodeComponent(fileUri);
      final viewerUrl = 'file:///android_asset/flutter_assets/assets/web/viewer.html?file=$encodedFileUri';
      return viewerUrl;
    } catch (e) {
      return 'file:///android_asset/flutter_assets/assets/web/viewer.html';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
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
            onLoadStop: (controller, url) {
              setState(() => _loaded = true);
            },
          ),
          if (!_loaded)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 20),
                  Text('Loading PDF...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
