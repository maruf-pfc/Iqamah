import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Conditionally import the platform-specific WebView implementation
import 'webview_widget/webview_stub.dart'
    if (dart.library.html) 'webview_widget/webview_web.dart'
    if (dart.library.io) 'webview_widget/webview_mobile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system status bar and navigation bar styles for a premium native look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF111C18),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const IqamahMobileApp());
}

class IqamahMobileApp extends StatelessWidget {
  const IqamahMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iqamah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111C18),
      ),
      home: const IqamahWebViewScreen(),
    );
  }
}

class IqamahWebViewScreen extends StatelessWidget {
  const IqamahWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111C18),
      body: SafeArea(
        top: true,
        bottom: true,
        child: createWebView(),
      ),
    );
  }
}
