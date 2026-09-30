import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_manager_approvals.dart';

/// مراجعة الطلبات السابقة — بحث بنوع الطلب والتواريخ مع تقسيم وصفحات.
class ManagerHistoryScreen extends StatefulWidget {
  const ManagerHistoryScreen({super.key});

  @override
  State<ManagerHistoryScreen> createState() => _ManagerHistoryScreenState();
}

enum _KindFilter { all, leave, permission }

enum _StatusFilter { all, approved, rejected }

class _ManagerHistoryScreenState extends State<ManagerHistoryScreen> {
  static const _pageSize = 10;

  final _dateFormat = DateFormat('yyyy/MM/dd — HH:mm', 'ar');
  final _monthFormat = DateFormat('MMMM yyyy', 'ar');
  final _searchController = TextEditingController();

  _KindFilter _kind = _KindFilter.all;
  _StatusFilter _status = _StatusFilter.all;
  DateTime? _from;
  DateTime? _to;
  String _query = '';
  int _visibleCount = _pageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PendingManagerRequest> get _filtered {
    final q = _query.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'[\s\-]'), '');
    return [
      for (final r in StaticManagerApprovals.history)
        if (DateRangeFilterBar.inRange(r.submittedAt, _from, _to))
          if (_kind == _KindFilter.all ||
              (_kind == _KindFilter.leave &&
                  r.kind == ManagerRequestKind.leave) ||
              (_kind == _KindFilter.permission &&
                  r.kind == ManagerRequestKind.permission))
            if (_status == _StatusFilter.all ||
                (_status == _StatusFilter.approved &&
                    r.decision == ManagerDecision.approved) ||
                (_status == _StatusFilter.rejected &&
                    r.decision == ManagerDecision.rejected))
              if (q.isEmpty ||
                  r.employeeName.toLowerCase().contains(q) ||
                  r.employeeNumber.toLowerCase().contains(q) ||
                  r.employeeNumber
                      .toLowerCase()
                      .replaceAll(RegExp(r'[\s\-]'), '')
                      .contains(qDigits) ||
                  r.typeLabel.toLowerCase().contains(q))
                r,
    ];
  }

  Map<String, List<PendingManagerRequest>> _groupByMonth(
    List<PendingManagerRequest> items,
  ) {
    final map = <String, List<PendingManagerRequest>>{};
    for (final r in items) {
      final key = _monthFormat.format(r.submittedAt);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  void _resetPaging() => _visibleCount = _pageSize;

  void _openDetails(PendingManagerRequest request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RequestDetailsSheet(
        request: request,
        dateFormat: _dateFormat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final structure = AppSession.activeStructure?.name ?? 'الهيكل';
    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;
    final grouped = _groupByMonth(visible);
    final approvedCount =
        filtered.where((r) => r.decision == ManagerDecision.approved).length;
    final rejectedCount =
        filtered.where((r) => r.decision == ManagerDecision.rejected).length;

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
            'مراجعة الطلبات',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'تفاصيل ما وافقت عليه أو رفضته — صفِّ بالنوع والتاريخ',
            style: TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 14),
          AppSurface(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFFF6EFE4), AppColors.surface],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  _StatBlock(
                    label: 'المعروض',
                    value: '${filtered.length}',
                    color: AppColors.charcoal,
                  ),
                  _divider(),
                  _StatBlock(
                    label: 'موافق',
                    value: '$approvedCount',
                    color: AppColors.success,
                  ),
                  _divider(),
                  _StatBlock(
                    label: 'مرفوض',
                    value: '$rejectedCount',
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {
              _query = value;
              _resetPaging();
            }),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الرقم أو نوع الطلب',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
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
          DateRangeFilterBar(
            from: _from,
            to: _to,
            hint: 'من تاريخ / إلى تاريخ لتصفية قراراتك',
            onFromChanged: (d) => setState(() {
              _from = d;
              _resetPaging();
            }),
            onToChanged: (d) => setState(() {
              _to = d;
              _resetPaging();
            }),
            onCleared: () => setState(() {
              _from = null;
              _to = null;
              _resetPaging();
            }),
          ),
          const SizedBox(height: 12),
          const Text(
            'نوع الطلب',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _kind == _KindFilter.all,
                onTap: () => setState(() {
                  _kind = _KindFilter.all;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'إجازات',
                selected: _kind == _KindFilter.leave,
                onTap: () => setState(() {
                  _kind = _KindFilter.leave;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'أذونات',
                selected: _kind == _KindFilter.permission,
                onTap: () => setState(() {
                  _kind = _KindFilter.permission;
                  _resetPaging();
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'نتيجة القرار',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _status == _StatusFilter.all,
                onTap: () => setState(() {
                  _status = _StatusFilter.all;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'موافق عليها',
                selected: _status == _StatusFilter.approved,
                onTap: () => setState(() {
                  _status = _StatusFilter.approved;
                  _resetPaging();
                }),
              ),
              _FilterChip(
                label: 'مرفوضة',
                selected: _status == _StatusFilter.rejected,
                onTap: () => setState(() {
                  _status = _StatusFilter.rejected;
                  _resetPaging();
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            filtered.isEmpty
                ? 'لا نتائج لهذا الفلتر'
                : 'عرض ${visible.length} من ${filtered.length} — مقسّمة بالشهر',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const AppSurface(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 36, color: AppColors.gold),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد قرارات مطابقة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'غيّر الفترة أو نوع الطلب أو كلمة البحث',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate, fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.goldDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${entry.value.length})',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              for (final request in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryCard(
                    request: request,
                    dateFormat: _dateFormat,
                    onTap: () => _openDetails(request),
                  ),
                ),
            ],
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

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.line,
      );
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.request,
    required this.dateFormat,
    required this.onTap,
  });

  final PendingManagerRequest request;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final approved = request.decision == ManagerDecision.approved;
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (approved ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  request.employeeName.characters.first,
                  style: TextStyle(
                    color: approved ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
                label: approved ? 'موافق' : 'مرفوض',
                tone: approved ? StatusTone.success : StatusTone.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.slate,
              ),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(request.submittedAt),
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
              ),
              const Spacer(),
              Text(
                request.kind == ManagerRequestKind.leave ? 'إجازة' : 'إذن',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldDeep,
                ),
              ),
            ],
          ),
          if (request.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              request.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.charcoal,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'عرض التفاصيل',
                style: TextStyle(
                  color: AppColors.goldDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 12,
                color: AppColors.goldDeep,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  const _RequestDetailsSheet({
    required this.request,
    required this.dateFormat,
  });

  final PendingManagerRequest request;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final approved = request.decision == ManagerDecision.approved;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.employeeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                StatusPill(
                  label: approved ? 'موافق' : 'مرفوض',
                  tone: approved ? StatusTone.success : StatusTone.danger,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.employeeNumber,
              style: const TextStyle(
                color: AppColors.goldDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AppSurface(
              child: Column(
                children: [
                  _DetailRow(label: 'نوع الطلب', value: request.typeLabel),
                  _DetailRow(
                    label: 'التصنيف',
                    value: request.kind == ManagerRequestKind.leave
                        ? 'إجازة'
                        : 'إذن',
                  ),
                  _DetailRow(
                    label: 'تاريخ التقديم',
                    value: dateFormat.format(request.submittedAt),
                  ),
                  _DetailRow(
                    label: 'حالة العرض',
                    value: request.statusLabel,
                  ),
                  if (request.notes != null)
                    _DetailRow(label: 'ملاحظة الموظف', value: request.notes!),
                  if (request.rejectReason != null)
                    _DetailRow(
                      label: 'سبب الرفض',
                      value: request.rejectReason!,
                      danger: true,
                    ),
                ],
              ),
            ),
            if (request.attachment != null) ...[
              const SizedBox(height: 12),
              AttachmentChip(
                attachment: request.attachment!,
                viewerSubtitle:
                    '${request.employeeName} · ${request.typeLabel}',
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: danger ? AppColors.danger : AppColors.charcoal,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
