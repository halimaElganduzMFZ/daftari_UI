import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'pdf_frame_stub.dart'
    if (dart.library.html) 'pdf_frame_web.dart';

/// إطار معاينة PDF من bytes — على الويب يعرض الملف الحقيقي عبر Blob.
Widget buildPdfFrame({
  required Uint8List bytes,
  required String viewType,
}) {
  return buildPdfFrameImpl(bytes: bytes, viewType: viewType);
}

bool get pdfFrameSupportsNativePreview => pdfFrameSupportsNativePreviewImpl;
