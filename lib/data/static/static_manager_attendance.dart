import '../models/employee.dart';
import 'static_employees.dart';

/// نوع يوم الحضور.
enum AttendanceDayKind { work, weekend, holiday, leave }

/// صف يوم في سجل بصمات/حضور موظف.
class EmployeeDayAttendance {
  const EmployeeDayAttendance({
    required this.date,
    required this.weekdayLabel,
    required this.dayKind,
    required this.dayKindLabel,
    required this.statusLabel,
    this.checkIn,
    this.checkOut,
  });

  final DateTime date;
  final String weekdayLabel;
  final AttendanceDayKind dayKind;
  final String dayKindLabel;
  final String statusLabel;
  final String? checkIn;
  final String? checkOut;

  bool get isPresent => statusLabel == 'حاضر';
  bool get isAbsent => statusLabel == 'غياب';
}

/// بيانات ثابتة لشاشة عرض بصمات الموظفين (time_sheet_show.php).
abstract final class StaticManagerAttendance {
  /// موظفو الهيكل الذين يمكن للمدير عرض بصماتهم.
  static List<Employee> get structureEmployees => StaticEmployees.all
      .where((e) => e.status == EmploymentStatus.active)
      .toList(growable: false);

  /// جلب سجل الحضور لموظف ضمن فترة — بيانات تجريبية للتصميم.
  static List<EmployeeDayAttendance> fetchSheet({
    required String employeeNumber,
    required DateTime from,
    required DateTime to,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(start)) return const [];

    final days = <EmployeeDayAttendance>[];
    var cursor = start;
    var i = 0;
    while (!cursor.isAfter(end)) {
      days.add(_dayFor(employeeNumber, cursor, i));
      cursor = cursor.add(const Duration(days: 1));
      i++;
    }
    return days;
  }

  static EmployeeDayAttendance _dayFor(
    String employeeNumber,
    DateTime date,
    int index,
  ) {
    final weekday = date.weekday; // 1=Mon ... 7=Sun
    final weekdayLabel = _weekdayAr(weekday);

    // جمعة/سبت عطلة أسبوعية في النموذج التجريبي.
    if (weekday == DateTime.friday || weekday == DateTime.saturday) {
      return EmployeeDayAttendance(
        date: date,
        weekdayLabel: weekdayLabel,
        dayKind: AttendanceDayKind.weekend,
        dayKindLabel: 'عطلة أسبوعية',
        statusLabel: 'عطلة أسبوعية',
      );
    }

    // نمط متنوع حسب رقم الموظف والفهرس لإظهار حالات حقيقية.
    final seed = employeeNumber.hashCode.abs() + index;
    final mod = seed % 11;

    if (mod == 0) {
      return EmployeeDayAttendance(
        date: date,
        weekdayLabel: weekdayLabel,
        dayKind: AttendanceDayKind.leave,
        dayKindLabel: 'دوام العمل',
        statusLabel: 'إجازة اعتيادية',
      );
    }
    if (mod == 1) {
      return EmployeeDayAttendance(
        date: date,
        weekdayLabel: weekdayLabel,
        dayKind: AttendanceDayKind.work,
        dayKindLabel: 'دوام العمل',
        statusLabel: 'غياب',
      );
    }
    if (mod == 2) {
      return EmployeeDayAttendance(
        date: date,
        weekdayLabel: weekdayLabel,
        dayKind: AttendanceDayKind.work,
        dayKindLabel: 'دوام العمل',
        statusLabel: 'تأخير في بصمة الدخول',
        checkIn: '08:42',
        checkOut: '15:05',
      );
    }
    if (mod == 3) {
      return EmployeeDayAttendance(
        date: date,
        weekdayLabel: weekdayLabel,
        dayKind: AttendanceDayKind.work,
        dayKindLabel: 'دوام العمل',
        statusLabel: 'انصراف مبكر',
        checkIn: '07:55',
        checkOut: '13:20',
      );
    }

    final inHour = 7 + (seed % 2);
    final inMin = (seed * 3) % 50;
    final outHour = 14 + (seed % 2);
    final outMin = (seed * 5) % 55;
    return EmployeeDayAttendance(
      date: date,
      weekdayLabel: weekdayLabel,
      dayKind: AttendanceDayKind.work,
      dayKindLabel: 'دوام العمل',
      statusLabel: 'حاضر',
      checkIn:
          '${inHour.toString().padLeft(2, '0')}:${inMin.toString().padLeft(2, '0')}',
      checkOut:
          '${outHour.toString().padLeft(2, '0')}:${outMin.toString().padLeft(2, '0')}',
    );
  }

  static String _weekdayAr(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      default:
        return 'الأحد';
    }
  }
}
