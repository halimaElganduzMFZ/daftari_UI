import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_timesheet_day.dart';
import '../../data/static/static_employee_timesheet.dart';

/// تايم شيت الحضور والانصراف مع pagination.
class AttendanceTimesheetScreen extends StatefulWidget {
  const AttendanceTimesheetScreen({super.key});

  @override
  State<AttendanceTimesheetScreen> createState() =>
      _AttendanceTimesheetScreenState();
}

class _AttendanceTimesheetScreenState extends State<AttendanceTimesheetScreen> {
  static const _pageSize = 8;
  int _visible = _pageSize;

  @override
  Widget build(BuildContext context) {
    final days = StaticEmployeeTimesheet.days;
    final visible = days.take(_visible).toList();
    final hasMore = _visible < days.length;
    final workDays = days.where((d) => d.isWorkDay).length;
    final lateDays = days.where((d) => d.delayLabel != null).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('حضور وانصراف')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF2F2F2F), Color(0xFF4A4034)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.fingerprint,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'سجل البصمة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'أيام حضورك وانصرافك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MiniStat(label: 'أيام دوام', value: '$workDays'),
                    const SizedBox(width: 10),
                    _MiniStat(label: 'تأخير', value: '$lateDays'),
                    const SizedBox(width: 10),
                    _MiniStat(label: 'المعروض', value: '${visible.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'عرض ${visible.length} من ${days.length}',
            style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          for (final day in visible) ...[
            _DayCard(day: day),
            const SizedBox(height: 10),
          ],
          if (hasMore)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _visible = (_visible + _pageSize).clamp(0, days.length);
              }),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('عرض المزيد (${days.length - visible.length})'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.goldDeep,
                side: const BorderSide(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final EmployeeTimesheetDay day;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy/MM/dd — EEEE', 'ar');
    final tone = switch (day.statusLabel) {
      'غائب' => StatusTone.danger,
      'متأخر' => StatusTone.warning,
      'عطلة' => StatusTone.neutral,
      _ => StatusTone.success,
    };

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateFmt.format(day.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              StatusPill(label: day.statusLabel, tone: tone),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            day.dayTypeLabel,
            style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
          ),
          if (day.isWorkDay) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _Stamp(label: 'حضور', value: day.checkIn ?? '—', inBound: true),
                const SizedBox(width: 8),
                _Stamp(label: 'استراحة', value: day.breakOut ?? '—'),
                const SizedBox(width: 8),
                _Stamp(label: 'عودة', value: day.breakIn ?? '—'),
                const SizedBox(width: 8),
                _Stamp(label: 'انصراف', value: day.checkOut ?? '—', outBound: true),
              ],
            ),
            if (day.delayLabel != null) ...[
              const SizedBox(height: 10),
              Text(
                day.delayLabel!,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.value,
    this.inBound = false,
    this.outBound = false,
  });

  final String label;
  final String value;
  final bool inBound;
  final bool outBound;

  @override
  Widget build(BuildContext context) {
    final color = inBound
        ? AppColors.success
        : outBound
            ? AppColors.info
            : AppColors.slate;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: color)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
