import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../theme/app_colors.dart';

/// نسخة غير الويب — بطاقة إرشادية إلى أن يتوفر عارض محلي.
Widget buildPdfFrameImpl({required Uint8List bytes, required String viewType}) {
  return Container(
    color: const Color(0xFF1C1C1A),
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            size: 48,
            color: Colors.white70,
          ),
          const SizedBox(height: 12),
          const Text(
            'معاينة PDF المباشرة متاحة على نسخة الويب حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الـ bytes محمّلة وجاهزة — اربط عارض PDF أصلي لاحقاً للجوال',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, height: 1.4),
          ),
        ],
      ),
    );
  }
}
