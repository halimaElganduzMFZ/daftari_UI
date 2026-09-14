import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_dashboard.dart';
import '../../data/static/static_employee_dashboard.dart';

/// تبويب «طلباتي» — فلاتر سنة/نوع/حالة + عرض المزيد.
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

enum _TypeFilter { all, leaves, permissions }

enum _StatusFilter { all, pending, approved, rejected }

class _LeavesScreenState extends State<LeavesScreen> {
  static const _pageSize = 8;

  _TypeFilter _typeFilter = _TypeFilter.all;
  _StatusFilter _statusFilter = _StatusFilter.all;
  late int _year;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    final years = _availableYears;
    _year = years.isEmpty ? DateTime.now().year : years.first;
  }

  List<int> get _availableYears {
    final years = {
      for (final r in StaticEmployeeDashboard.data.requests) r.requestedAt.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  static bool _isLeave(RequestKind kind) => switch (kind) {
        RequestKind.annualLeave ||
        RequestKind.emergencyLeave ||
        RequestKind.studyLeave =>
          true,
        RequestKind.delayPermission ||
        RequestKind.earlyLeavePermission ||
        RequestKind.other =>
          false,
      };

  List<EmployeeRequest> get _filtered {
    return [
      for (final r in StaticEmployeeDashboard.data.requests)
        if (r.requestedAt.year == _year)
          if (_typeFilter == _TypeFilter.all ||
              (_typeFilter == _TypeFilter.leaves && _isLeave(r.kind)) ||
              (_typeFilter == _TypeFilter.permissions && !_isLeave(r.kind)))
            if (_statusFilter == _StatusFilter.all ||
                (_statusFilter == _StatusFilter.pending &&
                    r.status == RequestStatus.pending) ||
                (_statusFilter == _StatusFilter.approved &&
                    r.status == RequestStatus.approved) ||
                (_statusFilter == _StatusFilter.rejected &&
                    r.status == RequestStatus.rejected))
              r,
    ];
  }

  void _resetPaging() => _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final data = StaticEmployeeDashboard.data;
    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
            'تصفّح سجلك بالسنة والنوع — بدون صفحات مرقّمة',
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
          const Text(
            'السنة',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final year in _availableYears) ...[
                  _FilterChip(
                    label: '$year',
                    selected: _year == year,
                    onTap: () => setState(() {
                      _year = year;
                      _resetPaging();
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _typeFilter == _TypeFilter.all,
                onTap: () => setState(() {
                  _typeFilter = _TypeFilter.all;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'إجازات',
                selected: _typeFilter == _TypeFilter.leaves,
                onTap: () => setState(() {
                  _typeFilter = _TypeFilter.leaves;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'أذونات',
                selected: _typeFilter == _TypeFilter.permissions,
                onTap: () => setState(() {
                  _typeFilter = _TypeFilter.permissions;
                  _resetPaging();
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'كل الحالات',
                selected: _statusFilter == _StatusFilter.all,
                onTap: () => setState(() {
                  _statusFilter = _StatusFilter.all;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'معلّقة',
                selected: _statusFilter == _StatusFilter.pending,
                onTap: () => setState(() {
                  _statusFilter = _StatusFilter.pending;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'مقبولة',
                selected: _statusFilter == _StatusFilter.approved,
                onTap: () => setState(() {
                  _statusFilter = _StatusFilter.approved;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'مرفوضة',
                selected: _statusFilter == _StatusFilter.rejected,
                onTap: () => setState(() {
                  _statusFilter = _StatusFilter.rejected;
                  _resetPaging();
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            filtered.isEmpty
                ? 'لا نتائج لهذا الفلتر'
                : 'عرض ${visible.length} من ${filtered.length} طلب',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 10),
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
                      'جرّب سنة أو تصنيفاً آخر',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (final request in visible)
              Padding(
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
                      if (request.attachment != null) ...[
                        const SizedBox(height: 10),
                        AttachmentChip(
                          attachment: request.attachment!,
                          dense: true,
                          viewerSubtitle: _kindLabel(request.kind),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (hasMore)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _visibleCount =
                      (_visibleCount + _pageSize).clamp(0, filtered.length);
                }),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'عرض المزيد (${filtered.length - visible.length})',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.goldDeep,
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static FaIconData _kindIcon(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => FontAwesomeIcons.hourglassHalf,
        RequestKind.earlyLeavePermission => FontAwesomeIcons.doorOpen,
        RequestKind.emergencyLeave => FontAwesomeIcons.triangleExclamation,
        RequestKind.annualLeave => FontAwesomeIcons.calendarCheck,
        RequestKind.studyLeave => FontAwesomeIcons.graduationCap,
        RequestKind.other => FontAwesomeIcons.fileLines,
      };

  static String _kindLabel(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => 'إذن تأخير',
        RequestKind.earlyLeavePermission => 'إذن خروج مبكر',
        RequestKind.emergencyLeave => 'إجازة طارئة',
        RequestKind.annualLeave => 'إجازة سنوية',
        RequestKind.studyLeave => 'إجازة دراسية',
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
