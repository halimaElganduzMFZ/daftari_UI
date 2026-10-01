import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/large_text.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    // الأيقونة تميّز الحالة لمن لا يفرّق بين الألوان.
    final (foreground, background, icon) = switch (tone) {
      StatusTone.success => (
        AppColors.success,
        const Color(0xFFE8F0EB),
        Icons.check_circle_rounded,
      ),
      StatusTone.warning => (
        AppColors.warning,
        AppColors.goldSoft,
        Icons.schedule_rounded,
      ),
      StatusTone.danger => (
        AppColors.danger,
        const Color(0xFFF3E8E8),
        Icons.cancel_rounded,
      ),
      StatusTone.neutral => (
        AppColors.slate,
        const Color(0xFFEEEEEE),
        Icons.remove_circle_outline_rounded,
      ),
      StatusTone.info => (
        AppColors.info,
        const Color(0xFFE8EEF3),
        Icons.info_outline_rounded,
      ),
    };

    return Semantics(
      label: 'الحالة: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(icon, size: 13, color: foreground, applyTextScaling: true),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// محتوى وبجانبه [StatusPill]. مع الخط الكبير تنزل الشارة تحت المحتوى،
/// فيبقى للنص عرضه كاملاً بدل أن تضيّقه الشارة.
class StatusPillRow extends StatelessWidget {
  const StatusPillRow({
    super.key,
    required this.content,
    required this.pill,
    this.gap = 0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget content;
  final Widget pill;

  /// المسافة ومحاذاة الشارة حين تكونان في صف واحد.
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (isLargeText(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: 8),
          Align(alignment: AlignmentDirectional.centerStart, child: pill),
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(child: content),
        if (gap > 0) SizedBox(width: gap),
        pill,
      ],
    );
  }
}

enum StatusTone { success, warning, danger, neutral, info }
