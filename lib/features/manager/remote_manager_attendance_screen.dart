import 'package:flutter/material.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../data/repositories/manager_repository.dart';
import '../../data/session/app_session.dart';
import 'remote_manager_widgets.dart';
import 'manager_statistics_screen.dart';

class RemoteManagerAttendanceScreen extends StatefulWidget {
  const RemoteManagerAttendanceScreen({super.key, this.repository});
  final ManagerRepository? repository;
  @override
  State<RemoteManagerAttendanceScreen> createState() =>
      _RemoteManagerAttendanceScreenState();
}

class _RemoteManagerAttendanceScreenState
    extends State<RemoteManagerAttendanceScreen> {
  ManagerRepository get _repo => widget.repository ?? AppServices.manager;
  final _list = GlobalKey<ManagerPagedListState>();
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _find() {
    setState(() => _query = _search.text.trim());
    _list.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ManagerPagedList(
      key: _list,
      load: (page) => _repo.page(
        '/manager/attendance/employees',
        page: page,
        filters: {'q': _query, 'structure': AppSession.activeStructure?.id},
      ),
      header: [
        const Text(
          'حضور وانصراف الموظفين',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر موظفًا لعرض بصماته خلال الفترة المطلوبة — ${AppSession.activeStructure?.name ?? 'الهياكل المخوّلة لك'}',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          maxLength: 100,
          onSubmitted: (_) => _find(),
          decoration: InputDecoration(
            labelText: 'اسم الموظف أو الرقم الوظيفي',
            suffixIcon: IconButton(
              onPressed: _find,
              icon: const Icon(Icons.search),
            ),
          ),
        ),
      ],
      itemBuilder: (employee) => AppSurface(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ManagerEmployeeAttendanceScreen(
              repository: _repo,
              employee: employee,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.fingerprint, color: AppColors.goldDeep),
          title: Text(managerText(employee['name'])),
          subtitle: Text(
            '${managerText(employee['number'])} · ${managerText((employee['workplace'] as Map?)?['name'])}',
          ),
          trailing: const Icon(Icons.chevron_left),
        ),
      ),
    ),
  );
}

class ManagerEmployeeAttendanceScreen extends StatefulWidget {
  const ManagerEmployeeAttendanceScreen({
    super.key,
    required this.repository,
    required this.employee,
  });
  final ManagerRepository repository;
  final ManagerJson employee;
  @override
  State<ManagerEmployeeAttendanceScreen> createState() =>
      _ManagerEmployeeAttendanceScreenState();
}

class _ManagerEmployeeAttendanceScreenState
    extends State<ManagerEmployeeAttendanceScreen> {
  late DateTime _from;
  late DateTime _to;
  ManagerJson? _result;
  Object? _error;
  bool _loading = false;
  int _sequence = 0;
  int _visible = 31;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final sequence = ++_sequence;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    if (_to.isBefore(_from) || _to.difference(_from).inDays >= 366) {
      setState(() {
        _loading = false;
        _error = 'اختر فترة صحيحة لا تتجاوز 366 يومًا.';
      });
      return;
    }
    try {
      final data = await widget.repository.client.getJson(
        '/manager/attendance/employees/${widget.employee['id']}',
        query: {
          'from': _from.toIso8601String().substring(0, 10),
          'to': _to.toIso8601String().substring(0, 10),
        },
      );
      if (!mounted || sequence != _sequence) return;
      setState(() {
        _result = data;
        _visible = 31;
      });
    } catch (e) {
      if (mounted && sequence == _sequence) setState(() => _error = e);
    } finally {
      if (mounted && sequence == _sequence) setState(() => _loading = false);
    }
  }

  Color _color(String? state) => switch (state) {
    'present' || 'excused' => AppColors.success,
    'absent' || 'irregular' => AppColors.danger,
    _ => AppColors.slate,
  };
  Widget _punch(Map day, String key) {
    final punch = (day['punches'] as Map?)?[key] as Map?;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(managerText(punch?['time']), textDirection: TextDirection.ltr),
        if (punch?['message'] != null)
          Text(
            managerText(punch?['message']),
            style: const TextStyle(fontSize: 11),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = (_result?['days'] as List? ?? []).cast<Map>();
    final summary = _result?['summary'] as Map?;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('جدول الحضور والانصراف')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    managerText(widget.employee['name']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  ManagerInfo('الرقم الوظيفي', widget.employee['number']),
                  DateRangeFilterBar(
                    from: _from,
                    to: _to,
                    onFromChanged: (date) {
                      setState(() => _from = date);
                      _load();
                    },
                    onToChanged: (date) {
                      setState(() => _to = date);
                      _load();
                    },
                  ),
                  TextButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث الجدول'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event_busy),
                    label: const Text('تفاصيل الغياب الفعلي وغياب البوابة'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManagerAbsencesScreen(
                          repository: widget.repository,
                          employeeId: '${widget.employee['id']}',
                          employeeName: widget.employee['name'] as String?,
                          from: _from,
                          to: _to,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              AppSurface(
                child: Column(
                  children: [
                    Text(
                      _error is String
                          ? _error as String
                          : managerError(_error!),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else if (_result?['status'] == 'unavailable')
              AppSurface(
                child: Column(
                  children: [
                    const Text('خدمة البصمات غير متاحة حاليًا. حاول لاحقًا.'),
                    TextButton(
                      onPressed: _load,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else ...[
              if (summary != null)
                AppSurface(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      for (final entry in const {
                        'days': 'الأيام',
                        'present': 'حضور',
                        'absent': 'غياب',
                        'excused': 'بإذن',
                        'irregular': 'بصمات غير منتظمة',
                        'leave': 'إجازة',
                        'off': 'عطلة',
                        'unknown': 'غير مصنف',
                      }.entries)
                        Text(
                          '${entry.value}: ${managerText(summary[entry.key])}',
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (days.isEmpty)
                const AppSurface(
                  child: Text('لا توجد سجلات حضور في هذه الفترة.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 66,
                    dataRowMaxHeight: 120,
                    columns: [
                      for (final title in [
                        'التاريخ / اليوم',
                        'نوع اليوم',
                        'الدخول',
                        'البصمة الثانية',
                        'البصمة الثالثة',
                        'الانصراف',
                        'الحالة',
                        'ملاحظة',
                      ])
                        DataColumn(label: Text(title)),
                    ],
                    rows: [
                      for (final day in days.take(_visible))
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${managerText(day['date'])}\n${managerText(day['weekdayName'])}',
                              ),
                            ),
                            DataCell(Text(managerText(day['dayTypeName']))),
                            for (final key in [
                              'checkIn',
                              'breakOut',
                              'resume',
                              'checkOut',
                            ])
                              DataCell(_punch(day, key)),
                            DataCell(
                              SizedBox(
                                width: 230,
                                child: Text(
                                  managerText(
                                    (day['verdict'] as Map?)?['text'],
                                  ),
                                  style: TextStyle(
                                    color: _color(
                                      (day['verdict'] as Map?)?['status']
                                          as String?,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(managerText(day['note'])),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              if (days.length > _visible)
                TextButton(
                  onPressed: () => setState(() => _visible += 31),
                  child: const Text('عرض المزيد'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
