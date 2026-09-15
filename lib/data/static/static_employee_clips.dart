import '../models/employee_clip.dart';

/// قصاصات ومستندات الموظف (بديل getYourPdfs.php).
abstract final class StaticEmployeeClips {
  static final clips = <EmployeeClip>[
    EmployeeClip(
      id: 'c1',
      title: 'بطاقة زمنية للموظف',
      date: DateTime(2026, 9, 10),
      kind: EmployeeClipKind.timesheetCard,
      fileName: 'ETS_2026_09.pdf',
    ),
    EmployeeClip(
      id: 'c2',
      title: 'قسيمة مالية — أغسطس',
      date: DateTime(2026, 8, 28),
      kind: EmployeeClipKind.paySlip,
      fileName: 'payslip_2026_08.pdf',
    ),
    EmployeeClip(
      id: 'c3',
      title: 'قسائم إنتاج — الربع الثالث',
      date: DateTime(2026, 8, 15),
      kind: EmployeeClipKind.paySlip,
      fileName: 'production_q3.pdf',
    ),
    EmployeeClip(
      id: 'c4',
      title: 'رسالة للموظف — تحديث سياسات',
      date: DateTime(2026, 7, 22),
      kind: EmployeeClipKind.message,
      fileName: 'policy_update.pdf',
    ),
    EmployeeClip(
      id: 'c5',
      title: 'بطاقة زمنية — يوليو',
      date: DateTime(2026, 7, 5),
      kind: EmployeeClipKind.timesheetCard,
      fileName: 'ETS_2026_07.pdf',
    ),
    EmployeeClip(
      id: 'c6',
      title: 'قسيمة مالية — يوليو',
      date: DateTime(2026, 7, 1),
      kind: EmployeeClipKind.paySlip,
      fileName: 'payslip_2026_07.pdf',
    ),
    EmployeeClip(
      id: 'c7',
      title: 'رسالة اعتماد إجازة دراسية',
      date: DateTime(2026, 6, 18),
      kind: EmployeeClipKind.message,
      fileName: 'study_leave_note.pdf',
    ),
    EmployeeClip(
      id: 'c8',
      title: 'قسيمة مالية — يونيو',
      date: DateTime(2026, 6, 2),
      kind: EmployeeClipKind.paySlip,
      fileName: 'payslip_2026_06.pdf',
    ),
    EmployeeClip(
      id: 'c9',
      title: 'بطاقة زمنية — مايو',
      date: DateTime(2026, 5, 12),
      kind: EmployeeClipKind.timesheetCard,
      fileName: 'ETS_2026_05.pdf',
    ),
    EmployeeClip(
      id: 'c10',
      title: 'مستند آخر — إخلاء طرف مؤقت',
      date: DateTime(2026, 4, 30),
      kind: EmployeeClipKind.other,
      fileName: 'clearance_temp.pdf',
    ),
  ];
}
