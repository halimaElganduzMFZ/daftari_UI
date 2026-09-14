import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/models/employee.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_manager_attendance.dart';

/// عرض بصمات الموظفين — بحث بالاسم أو الرقم الوظيفي + فترة زمنية.
class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() =>
      _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  static const _pageSize = 12;

  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');

  Employee? _selectedEmployee;
  DateTime? _fromDate;
  DateTime? _toDate;
  List<EmployeeDayAttendance>? _results;
  bool _loading = false;
  String? _error;
  String _query = '';
  int _visibleCount = _pageSize;

  List<Employee> get _matches =>
      StaticManagerAttendance.searchEmployees(_query);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) {
        _toDate = picked;
      }
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() => _toDate = picked);
  }

  void _selectEmployee(Employee employee) {
    setState(() {
      _selectedEmployee = employee;
      _searchController.text =
          '${employee.fullName} · ${employee.employeeNumber}';
      _query = employee.employeeNumber;
      _error = null;
      _results = null;
      _visibleCount = _pageSize;
    });
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _query = '';
      _selectedEmployee = null;
      _results = null;
      _error = null;
      _visibleCount = _pageSize;
    });
  }

  Future<void> _fetch() async {
    if (_selectedEmployee == null) {
      setState(() => _error = 'ابحث واختر الموظف أولاً');
      return;
    }
    if (_fromDate == null || _toDate == null) {
      setState(() => _error = 'حدد تاريخ البداية والنهاية');
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      setState(() => _error = 'تاريخ النهاية يجب أن يكون بعد البداية');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final rows = StaticManagerAttendance.fetchSheet(
      employeeNumber: _selectedEmployee!.employeeNumber,
      from: _fromDate!,
      to: _toDate!,
    );

    setState(() {
      _results = rows;
      _loading = false;
      _visibleCount = _pageSize;
      if (rows.isEmpty) {
        _error = 'لا توجد بيانات لعرضها';
      }
    });
  }

  Color _statusColor(EmployeeDayAttendance row) {
    if (row.isPresent) return AppColors.success;
    if (row.isAbsent) return AppColors.danger;
    if (row.dayKind == AttendanceDayKind.weekend ||
        row.dayKind == AttendanceDayKind.holiday) {
      return AppColors.info;
    }
    if (row.dayKind == AttendanceDayKind.leave) return AppColors.goldDeep;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final structure = AppSession.activeStructure?.name ?? 'الهيكل';
    final results = _results;
    final present = results?.where((r) => r.isPresent).length ?? 0;
    final absent = results?.where((r) => r.isAbsent).length ?? 0;
    final other = (results?.length ?? 0) - present - absent;
    final matches = _matches;
    // أظهر القائمة أثناء الكتابة، وأخفها بعد اختيار واضح.
    final showList = _query.trim().isNotEmpty &&
        (_selectedEmployee == null ||
            _searchController.text !=
                '${_selectedEmployee!.fullName} · ${_selectedEmployee!.employeeNumber}');

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
            'عرض بصمات الموظفين',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ابحث بالاسم أو الرقم الوظيفي، ثم اختر أي فترة زمنية (ليست مقيّدة بالشهر الحالي) واعرض السجل.',
            style: TextStyle(color: AppColors.slate, height: 1.45),
          ),
          const SizedBox(height: 16),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'الموظف',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                      // إن غيّر النص بعد الاختيار، ألغِ التحديد.
                      if (_selectedEmployee != null) {
                        final locked =
                            '${_selectedEmployee!.fullName} · ${_selectedEmployee!.employeeNumber}';
                        if (value != locked) {
                          _selectedEmployee = null;
                          _results = null;
                        }
                      }
                      _error = null;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'الاسم أو الرقم الوظيفي (مثال: أحمد أو FZ-10021)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
                if (_selectedEmployee != null && !showList) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.gold.withValues(alpha: 0.22),
                          child: Text(
                            _selectedEmployee!.fullName.characters.first,
                            style: const TextStyle(
                              color: AppColors.goldDeep,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEmployee!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              Text(
                                '${_selectedEmployee!.employeeNumber} · ${_selectedEmployee!.department}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'تغيير',
                          onPressed: _clearSearch,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.goldDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showList) ...[
                  const SizedBox(height: 8),
                  if (matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'لا يوجد موظف بهذا الاسم أو الرقم',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.slate),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, index) {
                          final e = matches[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.gold.withValues(alpha: 0.16),
                              child: Text(
                                e.fullName.characters.first,
                                style: const TextStyle(
                                  color: AppColors.goldDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              e.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                              ),
                            ),
                            subtitle: Text(
                              '${e.employeeNumber} · ${e.department}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.slate,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.slate,
                            ),
                            onTap: () => _selectEmployee(e),
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'من تاريخ',
                        value: _fromDate == null
                            ? null
                            : _dateFormat.format(_fromDate!),
                        onTap: _pickFrom,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateField(
                        label: 'إلى تاريخ',
                        value: _toDate == null
                            ? null
                            : _dateFormat.format(_toDate!),
                        onTap: _pickTo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _fetch,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_loading ? 'جاري الجلب...' : 'عرض'),
                  ),
                ),
                if (_error != null && results == null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (results != null) ...[
            const SizedBox(height: 20),
            Text(
              'سجل الحضور والغياب'
              '${_selectedEmployee == null ? '' : ' — ${_selectedEmployee!.fullName}'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'حاضر',
                    value: '$present',
                    color: AppColors.success,
                  ),
                  _SummaryChip(
                    label: 'غياب',
                    value: '$absent',
                    color: AppColors.danger,
                  ),
                  _SummaryChip(
                    label: 'أخرى',
                    value: '$other',
                    color: AppColors.info,
                  ),
                  _SummaryChip(
                    label: 'أيام',
                    value: '${results.length}',
                    color: AppColors.goldDeep,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const AppSurface(
                child: Text(
                  'لا توجد بيانات لعرضها',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate),
                ),
              )
            else ...[
              Text(
                'عرض ${results.take(_visibleCount).length} من ${results.length} يوم',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 10),
              ...results.take(_visibleCount).map((row) {
                final color = _statusColor(row);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppSurface(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${row.weekdayLabel} — ${_dateFormat.format(row.date)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.dayKindLabel,
                                style: const TextStyle(
                                  color: AppColors.slate,
                                  fontSize: 12.5,
                                ),
                              ),
                              if (row.checkIn != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'دخول ${row.checkIn}'
                                  '${row.checkOut != null ? ' · خروج ${row.checkOut}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 130),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            row.statusLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_visibleCount < results.length)
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _visibleCount =
                        (_visibleCount + _pageSize).clamp(0, results.length);
                  }),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text(
                    'عرض المزيد (${results.length - _visibleCount})',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.goldDeep,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? 'اختر التاريخ',
                      style: TextStyle(
                        color:
                            value == null ? AppColors.slate : AppColors.charcoal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.goldDeep,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
