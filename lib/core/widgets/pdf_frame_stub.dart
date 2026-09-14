import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// نسخة غير الويب — بطاقة إرشادية إلى أن يتوفر عارض محلي.
Widget buildPdfFrameImpl({
  required Uint8List bytes,
  required String viewType,
}) {
  return Container(
    color: const Color(0xFF1C1C1A),
    alignment: Alignment.center,
    child: const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.white70),
          SizedBox(height: 12),
          Text(
            'معاينة PDF المباشرة متاحة على نسخة الويب حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'الـ bytes محمّلة وجاهزة — اربط عارض PDF أصلي لاحقاً للجوال',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

const bool pdfFrameSupportsNativePreviewImpl = false;
