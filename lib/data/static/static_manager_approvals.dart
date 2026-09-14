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
/// مولَّدة بحجم واقعي لإدارات تصل لمئات الطلبات المعلّقة.
abstract final class StaticManagerApprovals {
  static final List<PendingManagerRequest> pending = _buildDemoQueue();

  static int get approvedThisMonth => 186;
  static int get rejectedThisMonth => 24;
  static int get pendingCount =>
      pending.where((r) => r.isPending).length;

  static List<PendingManagerRequest> _buildDemoQueue() {
    const names = [
      'أحمد محمد العلي',
      'سارة خالد المنصور',
      'يوسف إبراهيم الحربي',
      'نورة فهد الشمري',
      'ماجد عبدالعزيز القحطاني',
      'هند سليمان الدوسري',
      'خالد سعد المري',
      'ريم عبدالله الشمري',
      'عمر فيصل العتيبي',
      'لينا عبدالرحمن الغامدي',
      'فهد ناصر الدوسري',
      'ميسون خالد الحربي',
      'سلمان ماجد القحطاني',
      'دانة يوسف الأنصاري',
      'طلال سعيد الزهراني',
    ];

    const permissionTypes = [
      'إذن خروج شخصي',
      'إذن مهمة عمل',
      'إذن مراجعة طبية',
      'إذن ظرف طارئ',
    ];
    const leaveTypes = [
      'إجازة اعتيادية',
      'إجازة مرضية',
      'إجازة اضطرارية',
      'إجازة دراسية',
    ];

    final list = <PendingManagerRequest>[];
    // عدد كافٍ لإحساس الإدارات الثقيلة دون إبطاء الواجهة.
    for (var i = 0; i < 48; i++) {
      final isLeave = i % 3 == 0;
      final name = names[i % names.length];
      final day = 12 - (i ~/ 6);
      list.add(
        PendingManagerRequest(
          id: 'r$i',
          employeeName: name,
          employeeNumber: 'FZ-${10021 + (i % 40)}',
          kind: isLeave
              ? ManagerRequestKind.leave
              : ManagerRequestKind.permission,
          typeLabel: isLeave
              ? leaveTypes[i % leaveTypes.length]
              : permissionTypes[i % permissionTypes.length],
          statusLabel: 'طلب من الموظف',
          submittedAt: DateTime(2026, 9, day.clamp(1, 12), 8 + (i % 8), (i * 7) % 60),
          notes: i % 4 == 0 ? 'ملاحظة مختصرة من الموظف' : null,
        ),
      );
    }
    return list;
  }
}
