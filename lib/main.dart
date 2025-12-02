import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PdfTestPage extends StatefulWidget {
  @override
  State<PdfTestPage> createState() => _PdfTestPageState();
}

class _PdfTestPageState extends State<PdfTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialFile: "web/index.html",
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            allowFileAccess: true,
          ),
          android: AndroidInAppWebViewOptions(
            domStorageEnabled: true,
            allowContentAccess: true,
            allowFileAccess: true,
            useHybridComposition: true,
          ),
        ),
      ),
    );
  }
}
