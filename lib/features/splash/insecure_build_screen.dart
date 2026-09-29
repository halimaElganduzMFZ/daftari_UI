import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// تحل محل شاشة البداية في نسخة إصدار بُنيت بعنوان خادم غير https
/// (`ApiConfig.hasInsecureReleaseConfig`)، فلا يُرسل أي طلب.
class InsecureBuildScreen extends StatelessWidget {
  const InsecureBuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: AppColors.goldDeep,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يمكن تشغيل هذه النسخة',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لم تُهيّأ هذه النسخة بعنوان خادم آمن (HTTPS)، لذلك أُوقف '
                  'الاتصال حمايةً لبيانات الدخول. يرجى التواصل مع الدعم الفني.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
