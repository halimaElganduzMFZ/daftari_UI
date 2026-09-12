import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/leave_request.dart';
import '../../data/repositories/repositories.dart';

class LeavesScreen extends StatelessWidget {
  const LeavesScreen({super.key});

  static const _repo = StaticLeaveRepository();

  @override
  Widget build(BuildContext context) {
    final leaves = _repo.getLeaves();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            AppStrings.leaves,
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
          ...leaves.map((leave) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            leave.employeeName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        StatusPill(
                          label: _statusLabel(leave.status),
                          tone: _statusTone(leave.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_typeLabel(leave.type)} • ${leave.dayCount} يوم',
                      style: const TextStyle(color: AppColors.slate),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leave.reason,
                      style: const TextStyle(fontSize: 13),
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

  static String _typeLabel(LeaveType type) => switch (type) {
        LeaveType.annual => 'سنوية',
        LeaveType.sick => 'مرضية',
        LeaveType.emergency => 'طارئة',
        LeaveType.unpaid => 'بدون راتب',
      };

  static String _statusLabel(LeaveStatus status) => switch (status) {
        LeaveStatus.pending => 'قيد المراجعة',
        LeaveStatus.approved => 'مقبولة',
        LeaveStatus.rejected => 'مرفوضة',
      };

  static StatusTone _statusTone(LeaveStatus status) => switch (status) {
        LeaveStatus.pending => StatusTone.warning,
        LeaveStatus.approved => StatusTone.success,
        LeaveStatus.rejected => StatusTone.danger,
      };
}
