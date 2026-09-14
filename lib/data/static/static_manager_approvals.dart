/// حالة إجراء المدير على الطلب.
enum ManagerDecision { pending, approved, rejected }

/// نوع الطلب المعروض للمدير.
enum ManagerRequestKind { leave, permission }

/// طلب بانتظار موافقة المدير — بيانات ثابتة للتصميم.
class PendingManagerRequest {
  PendingManagerRequest({
    required this.id,
    required this.employeeName,
    required this.employeeNumber,
    required this.kind,
    required this.typeLabel,
    required this.statusLabel,
    required this.submittedAt,
    this.notes,
    this.decision = ManagerDecision.pending,
    this.rejectReason,
  });

  final String id;
  final String employeeName;
  final String employeeNumber;
  final ManagerRequestKind kind;
  final String typeLabel;
  String statusLabel;
  final DateTime submittedAt;
  final String? notes;
  ManagerDecision decision;
  String? rejectReason;

  bool get isPending => decision == ManagerDecision.pending;
}

/// بيانات ثابتة لشاشة موافقات المدير (index.php).
abstract final class StaticManagerApprovals {
  static final List<PendingManagerRequest> pending = [
    PendingManagerRequest(
      id: 'r1',
      employeeName: 'أحمد محمد العلي',
      employeeNumber: 'FZ-10021',
      kind: ManagerRequestKind.permission,
      typeLabel: 'إذن خروج شخصي',
      statusLabel: 'طلب من الموظف',
      submittedAt: DateTime(2026, 9, 12, 9, 40),
      notes: 'مراجعة طبية قصيرة',
    ),
    PendingManagerRequest(
      id: 'r2',
      employeeName: 'سارة خالد المنصور',
      employeeNumber: 'FZ-10045',
      kind: ManagerRequestKind.leave,
      typeLabel: 'إجازة اعتيادية',
      statusLabel: 'طلب من الموظف',
      submittedAt: DateTime(2026, 9, 11, 14, 15),
      notes: 'من 20 إلى 22 سبتمبر',
    ),
    PendingManagerRequest(
      id: 'r3',
      employeeName: 'يوسف إبراهيم الحربي',
      employeeNumber: 'FZ-10078',
      kind: ManagerRequestKind.permission,
      typeLabel: 'إذن مهمة عمل',
      statusLabel: 'طلب من الموظف',
      submittedAt: DateTime(2026, 9, 10, 11, 5),
    ),
    PendingManagerRequest(
      id: 'r4',
      employeeName: 'نورة فهد الشمري',
      employeeNumber: 'FZ-10102',
      kind: ManagerRequestKind.leave,
      typeLabel: 'إجازة مرضية',
      statusLabel: 'طلب من الموظف',
      submittedAt: DateTime(2026, 9, 9, 8, 20),
      notes: 'مرفق تقرير طبي',
    ),
  ];

  static int get approvedThisMonth => 12;
  static int get rejectedThisMonth => 3;
  static int get pendingCount =>
      pending.where((r) => r.isPending).length;
}
