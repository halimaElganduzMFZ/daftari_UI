import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      StatusTone.success => (AppColors.success, const Color(0xFFE8F0EB)),
      StatusTone.warning => (AppColors.warning, AppColors.goldSoft),
      StatusTone.danger => (AppColors.danger, const Color(0xFFF3E8E8)),
      StatusTone.neutral => (AppColors.slate, const Color(0xFFEEEEEE)),
      StatusTone.info => (AppColors.info, const Color(0xFFE8EEF3)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$1,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum StatusTone { success, warning, danger, neutral, info }
