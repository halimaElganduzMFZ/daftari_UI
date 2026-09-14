import '../models/request_attachment.dart';

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
    this.attachment,
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
  final RequestAttachment? attachment;

  bool get isPending => decision == ManagerDecision.pending;
}

/// بيانات ثابتة لشاشة موافقات المدير (index.php).
/// مولَّدة بحجم واقعي لإدارات تصل لمئات الطلبات المعلّقة.
abstract final class StaticManagerApprovals {
  static final List<PendingManagerRequest> pending = _buildDemoQueue();

  /// سجل قرارات سابقة — للشاشة «السابق» عبر عدة سنوات.
  static final List<PendingManagerRequest> history = _buildHistory();

  static int get approvedThisMonth => 186;
  static int get rejectedThisMonth => 24;
  static int get pendingCount =>
      pending.where((r) => r.isPending).length;

  static const _names = [
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

  static const _permissionTypes = [
    'إذن خروج شخصي',
    'إذن مهمة عمل',
    'إذن مراجعة طبية',
    'إذن ظرف طارئ',
  ];

  static const _leaveTypes = [
    'إجازة اعتيادية',
    'إجازة مرضية',
    'إجازة اضطرارية',
    'إجازة دراسية',
  ];

  static List<PendingManagerRequest> _buildDemoQueue() {
    final list = <PendingManagerRequest>[];
    for (var i = 0; i < 48; i++) {
      final isLeave = i % 3 == 0;
      final name = _names[i % _names.length];
      final day = 12 - (i ~/ 6);
      final typeLabel = isLeave
          ? _leaveTypes[i % _leaveTypes.length]
          : _permissionTypes[i % _permissionTypes.length];
      final isStudy = typeLabel == 'إجازة دراسية';
      list.add(
        PendingManagerRequest(
          id: 'r$i',
          employeeName: name,
          employeeNumber: 'FZ-${10021 + (i % 40)}',
          kind: isLeave
              ? ManagerRequestKind.leave
              : ManagerRequestKind.permission,
          typeLabel: typeLabel,
          statusLabel: 'طلب من الموظف',
          submittedAt:
              DateTime(2026, 9, day.clamp(1, 12), 8 + (i % 8), (i * 7) % 60),
          notes: isStudy
              ? 'مرفق قبول دراسي من الجهة التعليمية'
              : (i % 4 == 0 ? 'ملاحظة مختصرة من الموظف' : null),
          attachment: isStudy
              ? RequestAttachment.demoStudy(
                  fileName: 'قبول_دراسي_${name.split(' ').first}.pdf',
                  sizeBytes: 620000 + (i * 17000),
                )
              : null,
        ),
      );
    }
    return list;
  }

  static List<PendingManagerRequest> _buildHistory() {
    final list = <PendingManagerRequest>[];
    var id = 0;
    for (var year = 2026; year >= 2023; year--) {
      final count = year == 2026 ? 28 : 22;
      for (var i = 0; i < count; i++) {
        final isLeave = i % 2 == 0;
        final approved = i % 5 != 0;
        final month = 1 + ((i * 2) % 12);
        final day = 1 + ((i * 3) % 27);
        final typeLabel = isLeave
            ? _leaveTypes[i % _leaveTypes.length]
            : _permissionTypes[i % _permissionTypes.length];
        final isStudy = typeLabel == 'إجازة دراسية';
        list.add(
          PendingManagerRequest(
            id: 'h${id++}',
            employeeName: _names[(year + i) % _names.length],
            employeeNumber: 'FZ-${10021 + ((year + i) % 40)}',
            kind: isLeave
                ? ManagerRequestKind.leave
                : ManagerRequestKind.permission,
            typeLabel: typeLabel,
            statusLabel: approved ? 'معتمد' : 'مرفوض',
            submittedAt: DateTime(year, month, day, 9 + (i % 6), (i * 11) % 60),
            notes: isStudy
                ? 'مستند الإجازة الدراسية مرفق للمراجعة'
                : (i % 3 == 0 ? 'تمت المعالجة ضمن الهيكل' : null),
            decision:
                approved ? ManagerDecision.approved : ManagerDecision.rejected,
            rejectReason: approved ? null : 'نقص في المستندات',
            attachment: isStudy
                ? RequestAttachment.demoStudy(
                    fileName: 'مستند_دراسي_$year.pdf',
                    sizeBytes: 540000 + (i * 12000),
                  )
                : null,
          ),
        );
      }
    }
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return List<PendingManagerRequest>.unmodifiable(list);
  }
}
