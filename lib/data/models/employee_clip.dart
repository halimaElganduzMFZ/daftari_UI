enum EmployeeClipKind { timesheetCard, paySlip, message, other }

class EmployeeClip {
  const EmployeeClip({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    required this.fileName,
  });

  final String id;
  final String title;
  final DateTime date;
  final EmployeeClipKind kind;
  final String fileName;
}
