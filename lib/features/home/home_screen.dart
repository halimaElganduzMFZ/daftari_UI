import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/leave_request.dart';
import '../../data/repositories/repositories.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _employees = StaticEmployeeRepository();
  static const _leaves = StaticLeaveRepository();
  static const _attendance = StaticAttendanceRepository();

  @override
  Widget build(BuildContext context) {
    final employees = _employees.getEmployees();
    final pending = _leaves.getPending();
    final today = _attendance.getToday();
    final presentCount = today
        .where(
          (r) =>
              r.state == AttendanceState.present ||
              r.state == AttendanceState.late ||
              r.state == AttendanceState.remote,
        )
        .length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.orgName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDeep,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      AppStrings.staticModeHint,
                      style: TextStyle(
                        color: AppColors.goldDeep,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'الموظفون',
                      value: '${employees.length}',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'حضور اليوم',
                      value: '$presentCount',
                      icon: Icons.verified_user_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'قيد المراجعة',
                      value: '${pending.length}',
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SectionHeader(title: AppStrings.quickActions),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(
                        child: _ActionTile(
                          title: 'طلب إجازة',
                          icon: Icons.event_note_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          title: 'سجل الحضور',
                          icon: Icons.fingerprint,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          title: 'دليل الموظفين',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: AppStrings.pendingLeaves,
                actionLabel: AppStrings.viewAll,
                onAction: () {},
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: pending.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = pending[index];
                return AppSurface(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_available_outlined,
                          color: AppColors.goldDeep,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _leaveTypeLabel(item.type),
                              style: const TextStyle(
                                color: AppColors.slate,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StatusPill(
                        label: 'قيد المراجعة',
                        tone: StatusTone.warning,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  static String _leaveTypeLabel(LeaveType type) => switch (type) {
        LeaveType.annual => 'إجازة سنوية',
        LeaveType.sick => 'إجازة مرضية',
        LeaveType.emergency => 'إجازة طارئة',
        LeaveType.unpaid => 'إجازة بدون راتب',
      };
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldDeep, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.slate, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      onTap: () {},
      child: Column(
        children: [
          Icon(icon, color: AppColors.goldDeep),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
