import '../models/employee_clip.dart';

/// قصاصات ومستندات الموظف (بديل getYourPdfs.php) — بيانات ثابتة للتصميم.
abstract final class StaticEmployeeClips {
  static final clips = <EmployeeClip>[
    EmployeeClip(
      id: 1001,
      title: 'بطاقة زمنية للموظف',
      date: DateTime(2026, 9, 10),
      kind: EmployeeClipKind.timesheetCard,
      fileName: 'ETS_2026_09.pdf',
    ),
    EmployeeClip(
      id: 1002,
      title: 'قسيمة مالية',
      date: DateTime(2026, 8, 28),
      kind: EmployeeClipKind.paySlip,
      fileName: 'Date_2026_08_50651.pdf',
    ),
    EmployeeClip(
      id: 1003,
      title: 'قسائم انتاج 50651',
      date: DateTime(2026, 8, 15),
      kind: EmployeeClipKind.productionVoucher,
      fileName: 'production_q3.pdf',
    ),
    EmployeeClip(
      id: 1004,
      title: 'رسالة للموظف',
      date: DateTime(2026, 7, 22),
      kind: EmployeeClipKind.message,
      fileName: 'policy_update.jpg',
      extension: 'jpg',
      contentType: 'image/jpeg',
    ),
    EmployeeClip(
      id: 1005,
      title: 'بطاقة زمنية للموظف',
      date: DateTime(2026, 7, 5),
      kind: EmployeeClipKind.timesheetCard,
      fileName: 'ETS_2026_07.pdf',
    ),
    EmployeeClip(
      id: 1006,
      title: 'قسيمة مالية',
      date: DateTime(2026, 7, 1),
      kind: EmployeeClipKind.paySlip,
      fileName: 'Date_2026_07_50651.pdf',
    ),
    EmployeeClip(
      id: 1007,
      title: 'رسالة للموظف',
      date: DateTime(2026, 6, 18),
      kind: EmployeeClipKind.message,
      fileName: 'study_leave_note.pdf',
    ),
    EmployeeClip(
      id: 1008,
      title: 'قسيمة مالية',
      date: DateTime(2026, 6, 2),
      kind: EmployeeClipKind.paySlip,
      fileName: 'Date_2026_06_50651.pdf',
    ),
    EmployeeClip(
      id: 1009,
      title: 'بطاقة زمنية للموظف',
      date: DateTime(2026, 5, 12),
      kind: EmployeeClipKind.timesheetCard,
      fileName: 'ETS_2026_05.pdf',
    ),
    EmployeeClip(
      id: 1010,
      title: 'قسيمة مالية',
      date: DateTime(2026, 4, 30),
      kind: EmployeeClipKind.paySlip,
      fileName: 'Date_2026_04_50651.pdf',
    ),
  ];
}
