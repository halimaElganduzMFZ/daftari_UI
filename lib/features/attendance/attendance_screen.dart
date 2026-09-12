import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/attendance_record.dart';
import '../../data/repositories/repositories.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  static const _repo = StaticAttendanceRepository();

  @override
  Widget build(BuildContext context) {
    final records = _repo.getToday();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            AppStrings.todayAttendance,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.staticModeHint,
            style: TextStyle(color: AppColors.slate),
          ),
          const SizedBox(height: 16),
          ...records.map((record) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppSurface(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.employeeName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.checkIn == null
                                ? 'بدون بصمة'
                                : 'دخول: ${record.checkIn}',
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: _label(record.state),
                      tone: _tone(record.state),
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

  static String _label(AttendanceState state) => switch (state) {
        AttendanceState.present => 'حاضر',
        AttendanceState.late => 'متأخر',
        AttendanceState.absent => 'غائب',
        AttendanceState.remote => 'عن بُعد',
      };

  static StatusTone _tone(AttendanceState state) => switch (state) {
        AttendanceState.present => StatusTone.success,
        AttendanceState.late => StatusTone.warning,
        AttendanceState.absent => StatusTone.danger,
        AttendanceState.remote => StatusTone.info,
      };
}
