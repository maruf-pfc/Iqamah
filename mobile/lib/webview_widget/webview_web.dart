// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

Widget createWebView() {
  // Register the view factory for the iframe
  ui_web.platformViewRegistry.registerViewFactory(
    'iqamah-web-view',
    (int viewId) => html.IFrameElement()
      ..src = 'assets/assets/web/index.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%',
  );
  return const HtmlElementView(viewType: 'iqamah-web-view');
}
