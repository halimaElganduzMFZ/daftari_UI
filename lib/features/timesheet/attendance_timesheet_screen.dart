import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/timesheet.dart';
import '../../data/repositories/timesheet_repository.dart';
import 'timesheet_log_scaffold.dart';

/// تايم شيت الحضور والانصراف (بديل `time_sheet_employee.php`) — `GET /me/timesheet`.
///
/// يعرض بصمات اليوم الأربع مع شارة «الحالة (الوصف)» والعدّادات المحسوبة في الخادم.
class AttendanceTimesheetScreen extends StatelessWidget {
  const AttendanceTimesheetScreen({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.timesheet`.
  final TimesheetRepository? repository;

  @override
  Widget build(BuildContext context) {
    return TimesheetLogScaffold(
      title: 'حضور وانصراف',
      filterHint: 'تصفية سجل الحضور حسب الفترة',
      emptyText: 'لا توجد أيام مؤرشفة ضمن الفترة المحددة',
      unavailableText: 'سجل الحضور غير متاح',
      repository: repository,
      headerBuilder: (context, result, shown) =>
          _Header(result: result, shown: shown),
      dayBuilder: (context, day, result) => _DayCard(day: day),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.result, required this.shown});

  final TimesheetResult? result;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final s = result?.summary;
    String n(int? v) => v == null ? '—' : '$v';

    return Container(
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
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.fingerprint,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'سجل البصمة',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (result?.employee?.workplace case final wp?)
                Text(
                  wp,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              TimesheetMiniStat(label: 'أيام دوام', value: n(s?.workDays)),
              const SizedBox(width: 10),
              TimesheetMiniStat(
                label: 'حضور كامل',
                value: n(s?.presentFullDays),
              ),
              const SizedBox(width: 10),
              TimesheetMiniStat(label: 'إجازة', value: n(s?.leaveDays)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TimesheetMiniStat(label: 'غياب', value: n(s?.absenceDays)),
              const SizedBox(width: 10),
              TimesheetMiniStat(
                label: 'مخالفات بصمة',
                value: n(s?.timesheetViolationDays),
              ),
              const SizedBox(width: 10),
              TimesheetMiniStat(label: 'المعروض', value: '$shown'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final TimesheetDay day;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy/MM/dd — EEEE', 'ar');
    final att = day.attendance;
    final subtitle = [
      ?day.dayTypeName,
      ?day.workType,
      ?day.workplace,
    ].join(' · ');
    final showPunches = !day.isRest && (day.isWorkDay || !day.punches.isEmpty);

    return TimesheetDayCard(
      accent: rowAccentOf(day.tone),
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
              StatusPill(
                label: att.badge.text,
                tone: statusToneOf(att.badge.tone),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
            ),
          ],
          if (showPunches) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _Stamp(
                  label: 'حضور',
                  value: day.punches.checkIn ?? '—',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _Stamp(label: 'الثانية', value: day.punches.breakOut ?? '—'),
                const SizedBox(width: 8),
                _Stamp(label: 'الثالثة', value: day.punches.resume ?? '—'),
                const SizedBox(width: 8),
                _Stamp(
                  label: 'انصراف',
                  value: day.punches.checkOut ?? '—',
                  color: AppColors.info,
                ),
              ],
            ),
          ],
          if (att.work != null || att.undertime != null || att.overtime != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (att.work case final v?)
                  TimesheetMeta(label: 'ساعات العمل', value: v, width: 90),
                if (att.undertime case final v?)
                  TimesheetMeta(
                    label: 'نقص',
                    value: v,
                    width: 90,
                    valueColor: AppColors.warning,
                  ),
                if (att.overtime case final v?)
                  TimesheetMeta(
                    label: 'إضافي',
                    value: v,
                    width: 90,
                    valueColor: AppColors.success,
                  ),
              ],
            ),
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
    this.color = AppColors.slate,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(
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
