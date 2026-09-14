import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/session/app_session.dart';

/// بصمات موظفي الهيكل — شاشة تصميم أولية للمدير.
class ManagerAttendanceScreen extends StatelessWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final structure = AppSession.activeStructure?.name ?? 'الهيكل';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            structure,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'بصمات الموظفين',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'متابعة حضور وانصراف موظفي الهيكل الذي تديره.',
            style: TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 18),
          AppSurface(
            child: Column(
              children: const [
                Icon(Icons.fingerprint_rounded, size: 36, color: AppColors.gold),
                SizedBox(height: 12),
                Text(
                  'عرض البصمات قريباً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'نجهّز واجهة عرض بصمات الموظفين لهذا الهيكل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
