import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget createWebView() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const MobileWebView();
  } else {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.desktop_mac_rounded, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              "Desktop WebView support is under development.\nPlease run the application on Android, iOS, or Chrome.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileWebView extends StatefulWidget {
  const MobileWebView({super.key});

  @override
  State<MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _assetUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF111C18))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;
            _assetUrl ??= url.split('#').first;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme == 'file' &&
                (_assetUrl == null || request.url.split('#').first == _assetUrl)) {
              return NavigationDecision.navigate;
            }
            // Do not load untrusted remote pages into the app's JavaScript-enabled WebView.
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'IqamahNative',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            if (data['action'] == 'shareBackup') {
              final content = data['content'] as String;
              final filename = data['filename'] as String? ?? 'iqamah_backup.json';
              final bytes = utf8.encode(content);
              final xFile = XFile.fromData(
                bytes,
                mimeType: 'application/json',
                name: filename,
              );
              // ignore: deprecated_member_use
              await Share.shareXFiles(
                [xFile],
                subject: 'Iqamah Backup Export',
                text: 'Here is your Iqamah backup file.',
              );
            }
          } catch (_) {
            // Silently fall back if sharing fails or is cancelled
          }
        },
      )
      ..loadFlutterAsset('assets/web/index.html');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.runJavaScript(
        "window.dispatchEvent(new Event('iqamah-resume'));",
      ).catchError((Object _) { /* Loading errors are handled by the delegate. */ });
    }
  }

  Future<void> _handleBack() async {
    final closedDialog = await _controller.runJavaScriptReturningResult(
      "(() => { const dialog = document.querySelector('dialog[open]'); if (dialog) { dialog.close(); return true; } return false; })()",
    );
    if (closedDialog == true || closedDialog.toString() == 'true') return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (Platform.isAndroid) {
      await SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        try { await _handleBack(); } catch (_) { /* Keep the current screen on controller failure. */ }
      },
      child: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_hasError)
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('অ্যাপ লোড করা যায়নি / Unable to load app'),
            TextButton(
              onPressed: () => _controller.loadFlutterAsset('assets/web/index.html'),
              child: const Text('আবার চেষ্টা করুন / Retry'),
            ),
          ])),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF91D5B4)),
            ),
          ),
      ]),
    );
  }
}
