import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/session/app_session.dart';

/// الطلبات السابقة — شاشة تصميم أولية للمدير.
class ManagerHistoryScreen extends StatelessWidget {
  const ManagerHistoryScreen({super.key});

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
            'الطلبات السابقة',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سجل ما تم اعتماده أو رفضه سابقاً ضمن هذا الهيكل.',
            style: TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 18),
          AppSurface(
            child: Column(
              children: const [
                Icon(Icons.history_rounded, size: 36, color: AppColors.gold),
                SizedBox(height: 12),
                Text(
                  'لا توجد طلبات سابقة للعرض حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ستظهر هنا الطلبات المكتملة بعد ربط البيانات.',
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
