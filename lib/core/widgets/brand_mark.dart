import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// شعار MFZ الدائري — نفس لغة شاشة الدخول والأيقونة.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 88,
    this.showSoftShadow = true,
  });

  final double size;
  final bool showSoftShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFC9A66B),
            AppColors.goldDeep,
          ],
        ),
        boxShadow: showSoftShadow
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'MFZ',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.26,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: size * 0.014,
          ),
        ),
      ),
    );
  }
}
