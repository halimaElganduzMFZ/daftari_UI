import '../models/employee_timesheet_day.dart';

/// سجل حضور وانصراف تجريبي — أيام كافية لاختبار pagination.
abstract final class StaticEmployeeTimesheet {
  static final List<EmployeeTimesheetDay> days = _build();

  static List<EmployeeTimesheetDay> _build() {
    final list = <EmployeeTimesheetDay>[];
    final start = DateTime(2026, 9, 14);
    for (var i = 0; i < 42; i++) {
      final date = start.subtract(Duration(days: i));
      final weekday = date.weekday;
      final isWeekend = weekday == DateTime.friday || weekday == DateTime.saturday;
      if (isWeekend) {
        list.add(
          EmployeeTimesheetDay(
            id: 't$i',
            date: date,
            dayType: DayType.weekend,
            dayTypeLabel: 'عطلة أسبوعية',
            statusLabel: 'عطلة',
          ),
        );
        continue;
      }

      final late = i % 7 == 2;
      final absent = i % 11 == 0;
      list.add(
        EmployeeTimesheetDay(
          id: 't$i',
          date: date,
          dayType: DayType.work,
          dayTypeLabel: 'دوام عمل',
          checkIn: absent ? null : (late ? '08:24' : '07:5${i % 10}'),
          breakOut: absent ? null : '12:00',
          breakIn: absent ? null : '12:45',
          checkOut: absent ? null : '15:3${i % 8}',
          delayLabel: late ? 'تأخير 24 د' : null,
          statusLabel: absent ? 'غائب' : (late ? 'متأخر' : 'حاضر'),
        ),
      );
    }
    return List.unmodifiable(list);
  }
}
