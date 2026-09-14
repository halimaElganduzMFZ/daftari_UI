import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_manager_approvals.dart';

/// الطلبات السابقة — فلتر سنة/حالة + عرض المزيد.
class ManagerHistoryScreen extends StatefulWidget {
  const ManagerHistoryScreen({super.key});

  @override
  State<ManagerHistoryScreen> createState() => _ManagerHistoryScreenState();
}

enum _HistoryKind { all, leave, permission }

enum _HistoryStatus { all, approved, rejected }

class _ManagerHistoryScreenState extends State<ManagerHistoryScreen> {
  static const _pageSize = 12;

  final _dateFormat = DateFormat('yyyy/MM/dd — HH:mm', 'ar');
  final _searchController = TextEditingController();

  late int _year;
  _HistoryKind _kind = _HistoryKind.all;
  _HistoryStatus _status = _HistoryStatus.all;
  String _query = '';
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    final years = _availableYears;
    _year = years.isEmpty ? DateTime.now().year : years.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _availableYears {
    final years = {
      for (final r in StaticManagerApprovals.history) r.submittedAt.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<PendingManagerRequest> get _filtered {
    final q = _query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[\s\-]'), '');
    return [
      for (final r in StaticManagerApprovals.history)
        if (r.submittedAt.year == _year)
          if (_kind == _HistoryKind.all ||
              (_kind == _HistoryKind.leave &&
                  r.kind == ManagerRequestKind.leave) ||
              (_kind == _HistoryKind.permission &&
                  r.kind == ManagerRequestKind.permission))
            if (_status == _HistoryStatus.all ||
                (_status == _HistoryStatus.approved &&
                    r.decision == ManagerDecision.approved) ||
                (_status == _HistoryStatus.rejected &&
                    r.decision == ManagerDecision.rejected))
              if (q.isEmpty ||
                  r.employeeName.toLowerCase().contains(q) ||
                  r.employeeNumber.toLowerCase().contains(q) ||
                  r.employeeNumber
                      .toLowerCase()
                      .replaceAll(RegExp(r'[\s\-]'), '')
                      .contains(qDigits))
                r,
    ];
  }

  void _resetPaging() => _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final structure = AppSession.activeStructure?.name ?? 'الهيكل';
    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

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
            'سجل المعتمد والمرفوض — صفِّ بالسنة وابحث بالاسم أو الرقم',
            style: TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {
              _query = value;
              _resetPaging();
            }),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الرقم الوظيفي',
              prefixIcon: const Icon(Icons.badge_outlined),
              filled: true,
              fillColor: AppColors.background,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _resetPaging();
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
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
                  _Chip(
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: 'الكل',
                selected: _kind == _HistoryKind.all,
                onTap: () => setState(() {
                  _kind = _HistoryKind.all;
                  _resetPaging();
                }),
              ),
              _Chip(
                label: 'إجازات',
                selected: _kind == _HistoryKind.leave,
                onTap: () => setState(() {
                  _kind = _HistoryKind.leave;
                  _resetPaging();
                }),
              ),
              _Chip(
                label: 'أذونات',
                selected: _kind == _HistoryKind.permission,
                onTap: () => setState(() {
                  _kind = _HistoryKind.permission;
                  _resetPaging();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: 'كل الحالات',
                selected: _status == _HistoryStatus.all,
                onTap: () => setState(() {
                  _status = _HistoryStatus.all;
                  _resetPaging();
                }),
              ),
              _Chip(
                label: 'معتمد',
                selected: _status == _HistoryStatus.approved,
                onTap: () => setState(() {
                  _status = _HistoryStatus.approved;
                  _resetPaging();
                }),
              ),
              _Chip(
                label: 'مرفوض',
                selected: _status == _HistoryStatus.rejected,
                onTap: () => setState(() {
                  _status = _HistoryStatus.rejected;
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
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 36, color: AppColors.gold),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد طلبات سابقة لهذا الفلتر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'جرّب سنة أو بحثاً آخر',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate, fontSize: 13),
                  ),
                ],
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
                          CircleAvatar(
                            backgroundColor: AppColors.goldSoft,
                            child: Text(
                              request.employeeName.characters.first,
                              style: const TextStyle(
                                color: AppColors.goldDeep,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.employeeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${request.employeeNumber} · ${request.typeLabel}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: request.decision == ManagerDecision.approved
                                ? 'معتمد'
                                : 'مرفوض',
                            tone: request.decision == ManagerDecision.approved
                                ? StatusTone.success
                                : StatusTone.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _dateFormat.format(request.submittedAt),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.slate,
                        ),
                      ),
                      if (request.notes != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          request.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                      if (request.rejectReason != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'سبب الرفض: ${request.rejectReason}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (request.attachment != null) ...[
                        const SizedBox(height: 10),
                        AttachmentChip(
                          attachment: request.attachment!,
                          dense: true,
                          viewerSubtitle:
                              '${request.employeeName} · ${request.typeLabel}',
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
}

class _Chip extends StatelessWidget {
  const _Chip({
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
