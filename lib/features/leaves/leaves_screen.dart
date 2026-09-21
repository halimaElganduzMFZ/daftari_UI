import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_dashboard.dart';
import '../../data/repositories/dashboard_repository.dart';

/// تبويب «طلباتي» — بديل `by_type.php` وقوائم الطلبات في `index.php`.
///
/// - الحالة والنوع يُرسلان للخادم (`GET /me/requests?status=&type=`).
/// - أنواع الفلترة من `GET /lookups/request-types` (أذونات + إجازات).
/// - الفترة تُطبَّق محلياً على الصفحات المحمّلة لأن الـ API لا يوفر
///   `from/to` لهذا المسار؛ عند ضيق النتائج تُجلب صفحات إضافية تلقائياً.
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key, this.repository});

  /// للاختبار — الافتراضي [AppServices.dashboard].
  final DashboardRepository? repository;

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  static const _pageSize = 20;
  static const _autoLoadPages = 5;

  DashboardRepository get _repo => widget.repository ?? AppServices.dashboard;

  EmployeeDashboardData? _dashboard;
  List<RequestPanelType>? _types;

  RequestStatus? _status;
  RequestPanelType? _type;
  DateTime? _from;
  DateTime? _to;

  final _items = <EmployeeRequest>[];
  int _page = 0;
  bool _hasNext = true;
  int? _total;
  bool _loading = false;
  Object? _error;
  int _feedSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadTypes();
    _reload();
  }

  // ─── تحميل ──────────────────────────────────────────────────────────────

  Future<void> _loadSummary() async {
    try {
      final data = await _repo.load();
      if (mounted) setState(() => _dashboard = data);
    } catch (_) {
      // الملخص تكميلي؛ القائمة لها معالجة أخطائها.
    }
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _repo.requestTypes();
      if (mounted) setState(() => _types = types);
    } catch (_) {
      if (mounted) setState(() => _types = const []);
    }
  }

  Future<void> _reload() async {
    _feedSeq++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasNext = true;
      _total = null;
      _error = null;
    });
    await _loadMore(auto: true);
  }

  Future<void> _loadMore({bool auto = false}) async {
    if (_loading || !_hasNext) return;
    final seq = _feedSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.requests(
        status: _status,
        type: _type?.code,
        page: _page + 1,
        limit: _pageSize,
        withTotal: _page == 0,
      );
      if (!mounted || seq != _feedSeq) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
        _total ??= page.total;
        _loading = false;
      });
      // فلتر الفترة محلي: إن كانت النتائج المرئية قليلة جلبنا المزيد تلقائياً.
      if (auto && _hasNext && _page < _autoLoadPages && _visible.length < 8) {
        await _loadMore(auto: true);
      }
    } catch (e) {
      if (!mounted || seq != _feedSeq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  // ─── فلاتر ──────────────────────────────────────────────────────────────

  List<EmployeeRequest> get _visible => [
        for (final r in _items)
          if (DateRangeFilterBar.inRange(r.fromDate ?? r.requestedAt, _from, _to)) r,
      ];

  bool get _hasDateFilter => _from != null || _to != null;

  void _setStatus(RequestStatus? status) {
    if (status == _status) return;
    setState(() => _status = status);
    _reload();
  }

  void _setType(RequestPanelType? type) {
    if (type?.code == _type?.code) return;
    setState(() => _type = type);
    _reload();
  }

  Future<void> _pickType() async {
    final types = _types;
    if (types == null) return;
    final picked = await showModalBottomSheet<_TypeChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TypePickerSheet(types: types, selectedCode: _type?.code),
    );
    if (picked == null) return;
    _setType(picked.type);
  }

  void _onDateChanged() {
    setState(() {});
    if (_hasNext && !_loading && _visible.length < 8) {
      _loadMore(auto: true);
    }
  }

  // ─── العرض ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = _dashboard;
    final visible = _visible;
    final hiddenByDate = _items.length - visible.length;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: () async {
          _loadSummary();
          await _reload();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
              'تصفّح سجلك حسب الحالة والنوع والفترة',
              style: TextStyle(color: AppColors.slate),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'سنوية',
                    value: data == null
                        ? '…'
                        : data.annualBalanceAvailable
                            ? '${data.annualBalance}'
                            : '—',
                    icon: FontAwesomeIcons.calendarCheck,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'طارئة',
                    value: data == null ? '…' : '${data.emergencyBalance}',
                    icon: FontAwesomeIcons.bolt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'أذونات',
                    value: data == null
                        ? '…'
                        : '${data.permissionBalanceRemaining ?? '—'}',
                    icon: FontAwesomeIcons.clockRotateLeft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'الحالة',
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
                  label: 'كل الحالات',
                  count: data?.counts == null
                      ? null
                      : data!.counts!.pending +
                          data.counts!.approved +
                          data.counts!.rejected,
                  selected: _status == null,
                  onTap: () => _setStatus(null),
                ),
                for (final s in RequestStatus.values)
                  _FilterChip(
                    label: _statusLabel(s),
                    count: data?.counts?.of(s),
                    selected: _status == s,
                    onTap: () => _setStatus(s),
                  ),
              ],
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
            _TypeSelector(
              type: _type,
              loading: _types == null,
              onTap: _types == null ? null : _pickType,
              onClear: _type == null ? null : () => _setType(null),
            ),
            const SizedBox(height: 12),
            DateRangeFilterBar(
              from: _from,
              to: _to,
              hint: 'الفترة (تاريخ الطلب) — تُطبَّق على النتائج المحمّلة',
              onFromChanged: (d) {
                _from = d;
                if (_to != null && _to!.isBefore(d)) _to = d;
                _onDateChanged();
              },
              onToChanged: (d) {
                _to = d;
                if (_from != null && _from!.isAfter(d)) _from = d;
                _onDateChanged();
              },
              onCleared: () {
                _from = null;
                _to = null;
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Text(
              _resultsLabel(visible.length, hiddenByDate),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null && _items.isEmpty)
              _ErrorCard(error: _error!, onRetry: _reload)
            else if (_loading && _items.isEmpty)
              for (var i = 0; i < 3; i++) const _RequestSkeleton()
            else if (visible.isEmpty && !_loading)
              _EmptyCard(
                hasDateFilter: _hasDateFilter,
                canLoadMore: _hasNext,
                onLoadMore: _hasNext ? () => _loadMore() : null,
              )
            else ...[
              for (final request in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RequestCard(request: request),
                ),
              if (_error != null) _ErrorCard(error: _error!, onRetry: _loadMore),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              else if (_hasNext)
                OutlinedButton.icon(
                  onPressed: () => _loadMore(),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text(
                    _total == null
                        ? 'تحميل المزيد'
                        : 'تحميل المزيد (${_total! - _items.length} متبقٍ)',
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
      ),
    );
  }

  String _resultsLabel(int visibleCount, int hiddenByDate) {
    if (_loading && _items.isEmpty) return 'جاري التحميل…';
    final parts = <String>[];
    parts.add(
      _total == null
          ? 'عرض $visibleCount طلب'
          : 'عرض $visibleCount من $_total طلب',
    );
    if (hiddenByDate > 0) parts.add('$hiddenByDate خارج الفترة المحددة');
    return parts.join(' · ');
  }

  static String _statusLabel(RequestStatus status) => switch (status) {
        RequestStatus.pending => 'معلّقة',
        RequestStatus.approved => 'مقبولة',
        RequestStatus.rejected => 'مرفوضة',
      };
}

// ─── بطاقة الطلب ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final EmployeeRequest request;

  static FaIconData _kindIcon(EmployeeRequest r) {
    final code = r.code ?? '';
    return switch (r.kind) {
      RequestKind.delayPermission => FontAwesomeIcons.hourglassHalf,
      RequestKind.earlyLeavePermission => FontAwesomeIcons.doorOpen,
      RequestKind.emergencyLeave => FontAwesomeIcons.triangleExclamation,
      RequestKind.annualLeave => FontAwesomeIcons.calendarCheck,
      RequestKind.studyLeave => FontAwesomeIcons.graduationCap,
      RequestKind.other => switch (code) {
          'MARRIAGE_LEAVE' => FontAwesomeIcons.ring,
          'HAJJ_LEAVE' => FontAwesomeIcons.kaaba,
          'MATERNITY_LEAVE' || 'IDDAH_LEAVE' => FontAwesomeIcons.personDress,
          'GATE_EXEMPTION' => FontAwesomeIcons.carSide,
          _ => r.toDate != null
              ? FontAwesomeIcons.umbrellaBeach
              : FontAwesomeIcons.idBadge,
        },
    };
  }

  static bool _isLeave(EmployeeRequest r) => switch (r.kind) {
        RequestKind.annualLeave ||
        RequestKind.emergencyLeave ||
        RequestKind.studyLeave =>
          true,
        RequestKind.delayPermission || RequestKind.earlyLeavePermission => false,
        RequestKind.other => r.toDate != null ||
            const {
              'MARRIAGE_LEAVE',
              'HAJJ_LEAVE',
              'MATERNITY_LEAVE',
              'IDDAH_LEAVE',
            }.contains(r.code),
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

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd');
    final from = request.fromDate;
    final to = request.toDate;
    final period = from == null
        ? null
        : to == null || to == from
            ? fmt.format(from)
            : '${fmt.format(from)} – ${fmt.format(to)}';
    final days = request.days;

    return AppSurface(
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
                  _kindIcon(request),
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
                      request.displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'قُدّم ${fmt.format(request.requestedAt)}',
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
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaChip(
                icon: _isLeave(request)
                    ? FontAwesomeIcons.umbrellaBeach
                    : FontAwesomeIcons.clockRotateLeft,
                label: _isLeave(request) ? 'إجازة' : 'إذن',
              ),
              if (period != null)
                _MetaChip(icon: FontAwesomeIcons.calendarDays, label: period),
              if (days != null && days > 0)
                _MetaChip(
                  icon: FontAwesomeIcons.hashtag,
                  label: '$days ${days == 1 ? 'يوم' : 'أيام'}',
                ),
            ],
          ),
          if (request.rejectReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                'سبب الرفض: ${request.rejectReason}',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: AppColors.goldDeep),
          const SizedBox(width: 5),
          Text(
            label,
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

// ─── اختيار النوع ────────────────────────────────────────────────────────────

class _TypeChoice {
  const _TypeChoice(this.type);
  final RequestPanelType? type;
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.type,
    required this.loading,
    required this.onTap,
    required this.onClear,
  });

  final RequestPanelType? type;
  final bool loading;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final has = type != null;
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: has ? AppColors.goldSoft : AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FaIcon(
                    has
                        ? (type!.isLeave
                            ? FontAwesomeIcons.umbrellaBeach
                            : FontAwesomeIcons.clockRotateLeft)
                        : FontAwesomeIcons.layerGroup,
                    size: 14,
                    color: AppColors.goldDeep,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  has ? type!.label : 'كل الأنواع',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: has ? AppColors.goldDeep : AppColors.charcoal,
                  ),
                ),
                Text(
                  has
                      ? type!.group
                      : loading
                          ? 'جاري تحميل الأنواع…'
                          : 'اضغط للبحث حسب النوع (أذونات / إجازات)',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.slate),
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'إزالة فلتر النوع',
              onPressed: onClear,
              icon: const FaIcon(
                FontAwesomeIcons.circleXmark,
                size: 16,
                color: AppColors.slate,
              ),
            )
          else
            const FaIcon(
              FontAwesomeIcons.chevronDown,
              size: 12,
              color: AppColors.slate,
            ),
        ],
      ),
    );
  }
}

class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet({required this.types, this.selectedCode});

  final List<RequestPanelType> types;
  final String? selectedCode;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<RequestPanelType>>{};
    for (final t in types) {
      groups.putIfAbsent(t.group, () => []).add(t);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.folderOpen,
                  size: 16,
                  color: AppColors.goldDeep,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'بحث حسب النوع',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              children: [
                _TypeRow(
                  label: 'كل الأنواع',
                  icon: FontAwesomeIcons.layerGroup,
                  selected: selectedCode == null,
                  onTap: () => Navigator.pop(context, const _TypeChoice(null)),
                ),
                if (types.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'تعذر تحميل قائمة الأنواع',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate),
                    ),
                  ),
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                  for (final t in entry.value)
                    _TypeRow(
                      label: t.label,
                      icon: t.isLeave
                          ? FontAwesomeIcons.umbrellaBeach
                          : FontAwesomeIcons.clockRotateLeft,
                      selected: t.code == selectedCode,
                      onTap: () => Navigator.pop(context, _TypeChoice(t)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.goldSoft : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                FaIcon(icon, size: 14, color: AppColors.goldDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: selected ? AppColors.goldDeep : AppColors.charcoal,
                    ),
                  ),
                ),
                if (selected)
                  const FaIcon(
                    FontAwesomeIcons.circleCheck,
                    size: 15,
                    color: AppColors.goldDeep,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── حالات ───────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.hasDateFilter,
    required this.canLoadMore,
    this.onLoadMore,
  });

  final bool hasDateFilter;
  final bool canLoadMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.inbox, size: 28, color: AppColors.slate),
            const SizedBox(height: 10),
            const Text(
              'لا توجد طلبات في هذا التصنيف',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasDateFilter && canLoadMore
                  ? 'لم تُحمَّل كل الصفحات بعد — حمّل المزيد أو وسّع الفترة'
                  : 'جرّب حالة أو نوعاً أو فترة أخرى',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 13),
            ),
            if (hasDateFilter && canLoadMore && onLoadMore != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onLoadMore, child: const Text('تحميل المزيد')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final message = e is ApiException
        ? e.isNetwork
            ? 'تعذر الوصول إلى الخادم. تأكد من الشبكة ثم أعد المحاولة.'
            : e.isUnauthorized
                ? 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى.'
                : e.message
        : 'حدث خطأ غير متوقع.';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 15,
                color: AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ),
        ],
      ),
    );
  }
}

class _RequestSkeleton extends StatelessWidget {
  const _RequestSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, [double h = 12]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppSurface(
        child: Row(
          children: [
            bar(40, 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(140),
                  const SizedBox(height: 8),
                  bar(90, 10),
                ],
              ),
            ),
            bar(64, 24),
          ],
        ),
      ),
    );
  }
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
    this.count,
  });

  final String label;
  final int? count;
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
            count == null ? label : '$label ($count)',
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
