import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_manager_attendance.dart';

/// بصمات موظفي الهيكل — مقابل time_sheet_show.php.
class ManagerAttendanceScreen extends StatelessWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final structure = AppSession.activeStructure?.name ?? 'الهيكل';
    final rows = StaticManagerAttendance.today;

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
            'حضور اليوم لموظفي الهيكل الذي تديره.',
            style: TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 16),
          AppSurface(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'حضروا',
                    value: '${StaticManagerAttendance.presentCount}',
                    color: AppColors.success,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.line),
                Expanded(
                  child: _Stat(
                    label: 'لم يحضروا',
                    value: '${StaticManagerAttendance.missingCount}',
                    color: AppColors.danger,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.line),
                Expanded(
                  child: _Stat(
                    label: 'الإجمالي',
                    value: '${rows.length}',
                    color: AppColors.goldDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppSurface(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: row.isComplete
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: row.isComplete
                            ? AppColors.success
                            : AppColors.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.employeeNumber,
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${row.checkIn}${row.checkOut != null ? ' — ${row.checkOut}' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: row.isComplete
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slate,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
