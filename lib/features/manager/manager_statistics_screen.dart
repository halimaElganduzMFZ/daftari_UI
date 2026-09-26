import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';

import '../../core/widgets/app_surface.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../data/repositories/manager_repository.dart';
import 'remote_manager_widgets.dart';
import 'remote_manager_requests_screen.dart';

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

/// Compact home entry — opens the full monthly-approvals page.
class ManagerStatisticsEntry extends StatelessWidget {
  const ManagerStatisticsEntry({
    super.key,
    required this.repository,
    this.requestTypes = const [],
  });
  final ManagerRepository repository;
  final List<ManagerJson> requestTypes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ManagerStatisticsScreen(
              repository: repository,
              requestTypes: requestTypes,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.charcoal, Color(0xFF514637)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.goldSoft,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حركة الموافقات الشهرية',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'الإجماليات والتوزيع حسب النوع — صفحة منفصلة',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.goldSoft,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ManagerStatisticsScreen extends StatelessWidget {
  const ManagerStatisticsScreen({
    super.key,
    required this.repository,
    this.requestTypes = const [],
  });
  final ManagerRepository repository;
  final List<ManagerJson> requestTypes;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('حركة الموافقات'),
      leading: IconButton(
        tooltip: 'رجوع للرئيسية',
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ManagerStatisticsPanel(
          repository: repository,
          requestTypes: requestTypes,
        ),
      ],
    ),
  );
}

class ManagerStatisticsPanel extends StatefulWidget {
  const ManagerStatisticsPanel({
    super.key,
    required this.repository,
    this.revision = 0,
    this.requestTypes = const [],
  });
  final ManagerRepository repository;
  final int revision;
  final List<ManagerJson> requestTypes;
  @override
  State<ManagerStatisticsPanel> createState() => _ManagerStatisticsPanelState();
}

class _ManagerStatisticsPanelState extends State<ManagerStatisticsPanel> {
  Map? _manager;
  Object? _error;
  bool _loading = true;
  int _seq = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ManagerStatisticsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.client.getJson('/me/dashboard');
      if (!mounted || seq != _seq) return;
      setState(() => _manager = result['manager'] as Map?);
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _manager?['monthlyApprovals'] as Map?;
    final absences = _manager?['absences'] as Map?;
    final totals = absences?['status'] == 'ok'
        ? (absences?['summary'] as Map?)
        : null;
    final ready = !_loading && _error == null && monthly != null;
    final total = (monthly?['total'] as num?)?.toInt() ?? 0;
    void openType(String? type) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManagerMonthlyApprovalsScreen(
          repository: widget.repository,
          month: monthly?['month'] as String?,
          type: type,
        ),
      ),
    );
    final rows = (monthly?['types'] as List? ?? []).whereType<Map>().toList();
    // Summary types are exact filters. Keep aliases separate so a tile always
    // opens precisely the events counted by the server for that label.
    final entries = <String, Map>{};
    for (final type in widget.requestTypes) {
      final label = type['label'] as String?;
      if (label != null) {
        entries[label] = {
          'type': label,
          'count': 0,
          'category': type['category'],
        };
      }
    }
    for (final row in rows) {
      final label = row['type'] as String?;
      if (label != null) entries[label] = {...?entries[label], ...row};
    }
    final groups = <String, List<Map>>{
      'الأذونات ومهام العمل': [],
      'الإجازات': [],
      'أنواع أخرى': [],
    };
    for (final entry in entries.values) {
      final group = entry['category'] == 'permission'
          ? 'الأذونات ومهام العمل'
          : entry['category'] == 'leave'
          ? 'الإجازات'
          : 'أنواع أخرى';
      groups[group]!.add(entry);
    }
    for (final group in groups.values) {
      group.sort(
        (a, b) =>
            ((b['count'] as num?) ?? 0).compareTo((a['count'] as num?) ?? 0),
      );
    }
    final active = rows.where((r) => (r['count'] as num? ?? 0) > 0).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.charcoal, Color(0xFF514637)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: AppColors.goldSoft,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ملخص حركة الموافقات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'تحديث الملخص',
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  'الشهر: ${managerText(monthly?['month'])}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ready ? '$total' : '—',
                      style: const TextStyle(
                        color: AppColors.goldSoft,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إجمالي موافقاتك هذا الشهر',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ready
                                ? 'موزّعة على $active أنواع من الطلبات'
                                : 'جاري قراءة الملخص',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'حركات الموافقة التي أجريتها بنفسك ضمن جميع تكليفاتك',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.goldSoft,
                  ),
                  onPressed: () => openType(null),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text('الموافقات الشهرية (${ready ? total : '—'})'),
                ),
              ],
            ),
          ),
          if (_error != null) ManagerError(error: _error!, retry: _load),
          if (!_loading && monthly == null)
            TextButton(
              onPressed: _load,
              child: const Text('تعذر تحميل الملخص — إعادة المحاولة'),
            ),
          if (ready) ...[
            const SizedBox(height: 18),
            for (final group in groups.entries.where(
              (g) => g.value.isNotEmpty,
            )) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${group.value.fold<num>(0, (sum, e) => sum + (e['count'] as num? ?? 0))} موافقة',
                      style: const TextStyle(
                        color: AppColors.goldDeep,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _ApprovalGrid(
                children: [
                  for (final entry in group.value)
                    _ApprovalTile(
                      label: managerText(entry['type']),
                      count: (entry['count'] as num? ?? 0).toInt(),
                      total: total,
                      icon: group.key == 'الإجازات'
                          ? Icons.event_available_outlined
                          : Icons.assignment_turned_in_outlined,
                      onTap: () => openType(entry['type'] as String?),
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            if (total == 0)
              const Text(
                'لا توجد موافقات مسجلة باسمك لهذا الشهر حتى الآن.',
                textAlign: TextAlign.center,
              ),
            if (monthly['historicalApprovalsIncluded'] == false)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'لا يشمل الموافقات القديمة قبل بدء تسجيل حركات الموافقة.',
                  style: TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ),
          ],
          const SizedBox(height: 8),
          AppSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_busy_outlined, color: AppColors.goldDeep),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'غياب الموظفين',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'ضمن جميع الهياكل المخوّلة لك',
                  style: TextStyle(color: AppColors.slate, fontSize: 12),
                ),
                if (!_loading && _error == null && totals != null) ...[
                  const SizedBox(height: 16),
                  _ApprovalGrid(
                    children: [
                      _AbsenceMetric(
                        label: 'غياب فعلي',
                        value: totals['actualAbsenceDays'],
                        icon: Icons.person_off_outlined,
                      ),
                      _AbsenceMetric(
                        label: 'بسبب مخالفة البوابة',
                        value: totals['gateAbsenceDays'],
                        icon: Icons.directions_car_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'الإجمالي: ${managerText(totals['totalAbsenceDays'])} يوم',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (totals['affectedEmployees'] != null)
                    Text(
                      'الموظفون المتأثرون: ${totals['affectedEmployees']}',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                ],
                if (!_loading && totals == null)
                  const Text('إحصاءات الغياب غير متاحة حالياً.'),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('عرض الموظفين وتفاصيل الأيام'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ManagerAbsencesScreen(repository: widget.repository),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalGrid extends StatelessWidget {
  const _ApprovalGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth < 290
          ? 1
          : c.maxWidth < 650
          ? 2
          : c.maxWidth < 1000
          ? 3
          : 4;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children)
            SizedBox(
              width: (c.maxWidth - (columns - 1) * 10) / columns,
              child: child,
            ),
        ],
      );
    },
  );
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({
    required this.label,
    required this.count,
    required this.total,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final int count;
  final int total;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Material(
      color: count > 0 ? AppColors.surface : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: count > 0
              ? AppColors.gold.withValues(alpha: .4)
              : AppColors.line,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.goldDeep),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: AppColors.slate,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'موافقة',
                    style: TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
                color: AppColors.gold,
                backgroundColor: AppColors.goldSoft,
              ),
              const SizedBox(height: 6),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}٪ من الإجمالي · التفاصيل',
                style: const TextStyle(color: AppColors.slate, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbsenceMetric extends StatelessWidget {
  const _AbsenceMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final Object? value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.goldSoft.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.goldDeep, size: 20),
        const SizedBox(height: 8),
        Text(
          managerText(value),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slate),
        ),
      ],
    ),
  );
}

class ManagerMonthlyApprovalsScreen extends StatefulWidget {
  const ManagerMonthlyApprovalsScreen({
    super.key,
    required this.repository,
    this.month,
    this.type,
  });
  final ManagerRepository repository;
  final String? month;
  final String? type;
  @override
  State<ManagerMonthlyApprovalsScreen> createState() =>
      _ManagerMonthlyApprovalsScreenState();
}

class _ManagerMonthlyApprovalsScreenState
    extends State<ManagerMonthlyApprovalsScreen> {
  late DateTime _month;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month =
        DateTime.tryParse('${widget.month}-01') ??
        DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل الموافقات الشهرية')),
    body: ManagerPagedList(
      key: ValueKey(_month),
      load: (page) async {
        final json = await widget.repository.client.getJson(
          '/manager/statistics/monthly-approvals/requests',
          query: {
            'month': _iso(_month).substring(0, 7),
            'page': '$page',
            'limit': '20',
            'withTotal': 'true',
            if (widget.type != null) 'type': widget.type!,
          },
        );
        final parsed = ManagerPage.fromJson(json);
        // Approval events have requestId, not the id expected by the shared pager.
        return ManagerPage(
          [
            for (final row in parsed.items)
              {
                ...row,
                'id':
                    '${row['requestId']}:${row['approvalLevel']}:${row['approvedAt']}',
              },
          ],
          parsed.hasNext,
          parsed.total,
        );
      },
      header: [
        Row(
          children: [
            IconButton(
              tooltip: 'الشهر السابق',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: Text(
                _iso(_month).substring(0, 7),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'الشهر التالي',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
          ],
        ),
        if (widget.type != null) Text('نوع الطلب: ${widget.type}'),
        const Text(
          'حركات الموافقة المسجلة باسمك؛ الموافقة المرحلية لا تعني اكتمال اعتماد الطلب.',
        ),
      ],
      itemBuilder: (row) => AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              managerText(row['employeeName']),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ManagerInfo('الرقم الوظيفي', row['employeeNumber']),
            ManagerInfo('نوع الطلب', row['type']),
            ManagerInfo('تاريخ الموافقة', row['approvedAt']),
            Text(row['isFinal'] == true ? 'موافقة نهائية' : 'موافقة مرحلية'),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ManagerRequestDetailScreen(
                    repository: widget.repository,
                    path: '/manager/requests',
                    item: {'id': row['requestId']},
                    canDecide: false,
                  ),
                ),
              ),
              child: const Text('تفاصيل الطلب'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AbsenceTotals extends StatelessWidget {
  const AbsenceTotals({super.key, required this.totals});
  final Map totals;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      for (final entry in const {
        'actualAbsenceDays': 'غياب فعلي',
        'gateAbsenceDays': 'غياب بسبب البوابة',
        'totalAbsenceDays': 'إجمالي أيام الغياب',
      }.entries)
        Text('${entry.value}: ${managerText(totals[entry.key])}'),
    ],
  );
}

class ManagerAbsencesScreen extends StatefulWidget {
  const ManagerAbsencesScreen({
    super.key,
    required this.repository,
    this.employeeId,
    this.employeeName,
    this.from,
    this.to,
  });
  final ManagerRepository repository;
  final String? employeeId;
  final String? employeeName;
  final DateTime? from;
  final DateTime? to;
  @override
  State<ManagerAbsencesScreen> createState() => _ManagerAbsencesScreenState();
}

class _ManagerAbsencesScreenState extends State<ManagerAbsencesScreen> {
  late DateTime _from;
  late DateTime _to;
  String _query = '';
  Map? _summary;
  String? _status;
  int _generation = 0;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.from ?? DateTime(now.year, now.month, 1);
    _to = widget.to ?? DateTime(now.year, now.month, now.day);
  }

  void _change(VoidCallback change) => setState(() {
    change();
    _generation++;
    _request++;
    _summary = null;
    _status = null;
  });
  Future<ManagerPage> _load(int page) async {
    final request = ++_request;
    if (_to.isBefore(_from) || _to.difference(_from).inDays >= 366) {
      throw const ApiException(
        message: 'اختر فترة صحيحة لا تتجاوز 366 يوماً',
        statusCode: 400,
      );
    }
    final detail = widget.employeeId != null;
    final json = await widget.repository.client.getJson(
      '/manager/statistics/absences${detail ? '/employees/${widget.employeeId}' : ''}',
      query: {
        'from': _iso(_from),
        'to': _iso(_to),
        'page': '$page',
        'limit': '20',
        'withTotal': 'true',
        if (!detail && _query.isNotEmpty) 'q': _query,
      },
    );
    if (mounted && request == _request) {
      setState(() {
        _summary = json['summary'] as Map?;
        _status = json['status'] as String?;
      });
    }
    if (json['status'] != 'ok') {
      throw const ApiException(
        message: 'تعذر جلب أرشيف الغياب. حاول لاحقاً.',
        statusCode: 503,
      );
    }
    if (!detail) return ManagerPage.fromJson(json);
    final days = (json['days'] as List).cast<Map>();
    return ManagerPage(
      [
        for (final day in days)
          Map<String, dynamic>.from({...day, 'id': day['date']}),
      ],
      false,
      days.length,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.employeeId == null
            ? 'غياب موظفي الهياكل المخوّلة'
            : 'غياب ${widget.employeeName ?? 'الموظف'}',
      ),
    ),
    body: ManagerPagedList(
      key: ValueKey(_generation),
      load: _load,
      header: [
        DateRangeFilterBar(
          from: _from,
          to: _to,
          onFromChanged: (d) => _change(() => _from = d),
          onToChanged: (d) => _change(() => _to = d),
        ),
        const SizedBox(height: 12),
        if (_status == 'ok' && _summary != null)
          AppSurface(child: AbsenceTotals(totals: _summary!)),
        if (widget.employeeId == null) ...[
          const SizedBox(height: 12),
          TextField(
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'بحث باسم الموظف أو رقمه',
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: (s) => _change(() => _query = s.trim()),
          ),
          const Text(
            'الإجمالي لجميع الهياكل المخوّلة، ولا يتغير عند البحث عن موظف.',
          ),
        ],
      ],
      itemBuilder: (row) => AppSurface(
        child: widget.employeeId == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${managerText(row['name'])} — ${managerText(row['number'])}',
                  ),
                  const SizedBox(height: 8),
                  AbsenceTotals(totals: row),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManagerAbsencesScreen(
                          repository: widget.repository,
                          employeeId: '${row['id']}',
                          employeeName: row['name'] as String?,
                          from: _from,
                          to: _to,
                        ),
                      ),
                    ),
                    child: const Text('تفاصيل أيام الغياب'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    managerText(row['date']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (row['actual'] == true) const Text('غياب فعلي'),
                  if (row['gate'] == true)
                    const Text('غياب بسبب مخالفة البوابة'),
                  ManagerInfo('الوصف', row['description']),
                ],
              ),
      ),
    ),
  );
}
