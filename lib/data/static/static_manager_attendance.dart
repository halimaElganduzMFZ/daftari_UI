/// صف بصمة موظف لشاشة المدير.
class ManagerPunchRow {
  const ManagerPunchRow({
    required this.employeeName,
    required this.employeeNumber,
    required this.checkIn,
    this.checkOut,
    required this.statusLabel,
    required this.isComplete,
  });

  final String employeeName;
  final String employeeNumber;
  final String checkIn;
  final String? checkOut;
  final String statusLabel;
  final bool isComplete;
}

/// بيانات ثابتة لعرض بصمات موظفي الهيكل.
abstract final class StaticManagerAttendance {
  static final List<ManagerPunchRow> today = [
    const ManagerPunchRow(
      employeeName: 'أحمد محمد العلي',
      employeeNumber: 'FZ-10021',
      checkIn: '07:52',
      checkOut: '15:05',
      statusLabel: 'مكتمل',
      isComplete: true,
    ),
    const ManagerPunchRow(
      employeeName: 'سارة خالد المنصور',
      employeeNumber: 'FZ-10045',
      checkIn: '08:10',
      checkOut: null,
      statusLabel: 'لم ينصرف بعد',
      isComplete: false,
    ),
    const ManagerPunchRow(
      employeeName: 'يوسف إبراهيم الحربي',
      employeeNumber: 'FZ-10078',
      checkIn: '07:45',
      checkOut: '14:58',
      statusLabel: 'مكتمل',
      isComplete: true,
    ),
    const ManagerPunchRow(
      employeeName: 'نورة فهد الشمري',
      employeeNumber: 'FZ-10102',
      checkIn: '—',
      checkOut: null,
      statusLabel: 'لم يحضر',
      isComplete: false,
    ),
    const ManagerPunchRow(
      employeeName: 'ماجد عبدالعزيز القحطاني',
      employeeNumber: 'FZ-10130',
      checkIn: '08:02',
      checkOut: '15:12',
      statusLabel: 'مكتمل',
      isComplete: true,
    ),
  ];

  static int get presentCount =>
      today.where((r) => r.checkIn != '—').length;
  static int get missingCount =>
      today.where((r) => r.checkIn == '—').length;
}
