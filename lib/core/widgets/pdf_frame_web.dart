import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registeredViews = <String>{};

/// يعرض PDF الحقيقي عبر iframe + Blob URL من الـ bytes / Base64 المفكوك.
Widget buildPdfFrameImpl({
  required Uint8List bytes,
  required String viewType,
}) {
  if (!_registeredViews.contains(viewType)) {
    // انسخ bytes لأن الـ factory قد تُستدعى لاحقاً.
    final payload = Uint8List.fromList(bytes);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final blob = html.Blob([payload], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final element = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'fullscreen';
      return element;
    });
    _registeredViews.add(viewType);
  }

  return HtmlElementView(viewType: viewType);
}

const bool pdfFrameSupportsNativePreviewImpl = true;
