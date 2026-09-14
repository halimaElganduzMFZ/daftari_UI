import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_dashboard.dart';
import '../../data/static/static_employee_dashboard.dart';

/// تبويب «طلباتي» — طلبات إجازة وأذونات للموظف الحالي.
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

enum _RequestFilter { all, leaves, permissions }

class _LeavesScreenState extends State<LeavesScreen> {
  _RequestFilter _filter = _RequestFilter.all;

  static bool _isLeave(RequestKind kind) => switch (kind) {
        RequestKind.annualLeave || RequestKind.emergencyLeave => true,
        RequestKind.delayPermission ||
        RequestKind.earlyLeavePermission ||
        RequestKind.other =>
          false,
      };

  @override
  Widget build(BuildContext context) {
    final data = StaticEmployeeDashboard.data;
    final filtered = [
      for (final r in data.requests)
        if (_filter == _RequestFilter.all ||
            (_filter == _RequestFilter.leaves && _isLeave(r.kind)) ||
            (_filter == _RequestFilter.permissions && !_isLeave(r.kind)))
          r,
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'طلباتي',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'متابعة طلبات الإجازة والأذونات وحالاتها',
            style: TextStyle(color: AppColors.slate),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'سنوية',
                  value: '${data.annualBalance}',
                  icon: FontAwesomeIcons.calendarCheck,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'طارئة',
                  value: '${data.emergencyBalance}',
                  icon: FontAwesomeIcons.bolt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'أذونات',
                  value: '${data.permissionBalanceRemaining ?? '—'}',
                  icon: FontAwesomeIcons.clockRotateLeft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _filter == _RequestFilter.all,
                onTap: () => setState(() => _filter = _RequestFilter.all),
              ),
              _FilterChip(
                label: 'إجازات',
                selected: _filter == _RequestFilter.leaves,
                onTap: () => setState(() => _filter = _RequestFilter.leaves),
              ),
              _FilterChip(
                label: 'أذونات',
                selected: _filter == _RequestFilter.permissions,
                onTap: () =>
                    setState(() => _filter = _RequestFilter.permissions),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const AppSurface(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.inbox,
                      size: 28,
                      color: AppColors.slate,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'لا توجد طلبات في هذا التصنيف',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'قدّم طلباً جديداً من تبويب تقديم أو الرئيسية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((request) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: FaIcon(
                              _kindIcon(request.kind),
                              size: 15,
                              color: AppColors.goldDeep,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _kindLabel(request.kind),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('yyyy/MM/dd')
                                      .format(request.requestedAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: _statusLabel(request.status),
                            tone: _statusTone(request.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        request.note,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLeave(request.kind) ? 'طلب إجازة' : 'طلب إذن',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDeep,
                        ),
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

  static FaIconData _kindIcon(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => FontAwesomeIcons.hourglassHalf,
        RequestKind.earlyLeavePermission => FontAwesomeIcons.doorOpen,
        RequestKind.emergencyLeave => FontAwesomeIcons.triangleExclamation,
        RequestKind.annualLeave => FontAwesomeIcons.calendarCheck,
        RequestKind.other => FontAwesomeIcons.fileLines,
      };

  static String _kindLabel(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => 'إذن تأخير',
        RequestKind.earlyLeavePermission => 'إذن خروج مبكر',
        RequestKind.emergencyLeave => 'إجازة طارئة',
        RequestKind.annualLeave => 'إجازة سنوية',
        RequestKind.other => 'طلب آخر',
      };

  static String _statusLabel(RequestStatus status) => switch (status) {
        RequestStatus.pending => 'قيد المراجعة',
        RequestStatus.approved => 'مقبولة',
        RequestStatus.rejected => 'مرفوضة',
      };

  static StatusTone _statusTone(RequestStatus status) => switch (status) {
        RequestStatus.pending => StatusTone.warning,
        RequestStatus.approved => StatusTone.success,
        RequestStatus.rejected => StatusTone.danger,
      };
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          FaIcon(icon, size: 14, color: AppColors.goldDeep),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.charcoal,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.goldSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? AppColors.goldDeep : AppColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}
