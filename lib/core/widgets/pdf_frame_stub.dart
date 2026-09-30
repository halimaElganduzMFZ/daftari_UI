import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// نسخة غير الويب (أندرويد / iOS / سطح المكتب) — معاينة أصلية عبر `PdfPreview`.
Widget buildPdfFrameImpl({
  required Uint8List bytes,
  required String viewType,
}) {
  return PdfPreview(
    build: (_) async => bytes,
    useActions: false,
    canChangeOrientation: false,
    canChangePageFormat: false,
    canDebug: false,
    scrollViewDecoration: const BoxDecoration(color: Color(0xFF1C1C1A)),
    loadingWidget: const Center(
      child: CircularProgressIndicator(color: Colors.white70),
    ),
    onError: (context, error) => const _PdfPreviewError(),
  );
}

const bool pdfFrameSupportsNativePreviewImpl = true;

class _PdfPreviewError extends StatelessWidget {
  const _PdfPreviewError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.white70),
          SizedBox(height: 12),
          Text(
            'تعذّر عرض ملف PDF على هذا الجهاز.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
