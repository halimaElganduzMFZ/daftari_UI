/// موظف منقطع عن العمل (AWOL) — مقابل awol_suspension_table في PHP.
class AwolEmployee {
  const AwolEmployee({
    required this.id,
    required this.employeeNumber,
    required this.fullName,
    required this.department,
    required this.firstAbsentDate,
    required this.suspendedDays,
    this.note,
  });

  final String id;
  final String employeeNumber;
  final String fullName;
  final String department;
  final DateTime firstAbsentDate;
  final int suspendedDays;
  final String? note;
}

/// بيانات ثابتة لإشعارات المنقطعين عند المدير.
abstract final class StaticAwol {
  static final List<AwolEmployee> absentees = [
    AwolEmployee(
      id: 'a1',
      employeeNumber: 'FZ-10110',
      fullName: 'رامي صالح العتيبي',
      department: 'وحدة الشؤون الإدارية',
      firstAbsentDate: DateTime(2026, 9, 8),
      suspendedDays: 5,
      note: 'لم تسجّل أي بصمة منذ أول يوم انقطاع',
    ),
    AwolEmployee(
      id: 'a2',
      employeeNumber: 'FZ-10128',
      fullName: 'لينا عبدالرحمن الغامدي',
      department: 'وحدة الشؤون الإدارية',
      firstAbsentDate: DateTime(2026, 9, 10),
      suspendedDays: 3,
    ),
    AwolEmployee(
      id: 'a3',
      employeeNumber: 'FZ-10088',
      fullName: 'فهد ناصر الدوسري',
      department: 'إدارة الموارد البشرية',
      firstAbsentDate: DateTime(2026, 9, 5),
      suspendedDays: 8,
      note: 'يتطلب مراجعة مدير الوحدة',
    ),
    AwolEmployee(
      id: 'a4',
      employeeNumber: 'FZ-10155',
      fullName: 'ميسون خالد الحربي',
      department: 'وحدة الشؤون الإدارية',
      firstAbsentDate: DateTime(2026, 9, 11),
      suspendedDays: 2,
    ),
  ];

  static int get notificationCount => absentees.length;
}
