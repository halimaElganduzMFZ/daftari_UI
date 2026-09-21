import 'request_attachment.dart';

enum RequestKind {
  delayPermission,
  earlyLeavePermission,
  emergencyLeave,
  annualLeave,
  studyLeave,
  other,
}

enum RequestStatus { pending, approved, rejected }

/// طلب واحد من `employee_app_request_panel` (مقابل `RequestRecordDto`).
class EmployeeRequest {
  const EmployeeRequest({
    required this.id,
    required this.kind,
    required this.status,
    required this.requestedAt,
    required this.note,
    this.attachment,
    this.typeLabel,
    this.code,
    this.fromDate,
    this.toDate,
    this.days,
    this.rejectReason,
    this.canWithdraw = false,
  });

  final String id;
  final RequestKind kind;
  final RequestStatus status;

  /// تاريخ الإدخال (`EnterDate`)، أو أول يوم للطلب عند غيابه.
  final DateTime requestedAt;

  /// نص وصفي يظهر تحت النوع: السبب في الوضع التجريبي، أو الفترة من الـ API.
  final String note;
  final RequestAttachment? attachment;

  /// التسمية المخزّنة حرفياً (`permission_type`) مثل «إجازة سنوية».
  final String? typeLabel;

  /// رمز الكتالوج مثل `ANNUAL_LEAVE` أو `LATE_ARRIVAL`.
  final String? code;

  /// اليوم المطلوب / أول يوم إجازة (`dt`).
  final DateTime? fromDate;

  /// آخر يوم إجازة (`dtt`) — `null` للطلبات ذات اليوم الواحد.
  final DateTime? toDate;

  /// عدد الأيام (`DAYS1`) — `null` عند الصفر.
  final int? days;
  final String? rejectReason;
  final bool canWithdraw;

  /// الاسم المعروض: التسمية القادمة من الخادم إن وُجدت، وإلا اسم النوع.
  String get displayTitle => (typeLabel ?? '').trim().isNotEmpty
      ? typeLabel!.trim()
      : kindLabel(kind);

  static String kindLabel(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => 'إذن تأخير',
        RequestKind.earlyLeavePermission => 'إذن خروج مبكر',
        RequestKind.emergencyLeave => 'إجازة طارئة',
        RequestKind.annualLeave => 'إجازة سنوية',
        RequestKind.studyLeave => 'إجازة دراسية',
        RequestKind.other => 'طلب آخر',
      };

  /// تحويل `RequestRecordDto` القادم من `GET /me/requests` أو `/me/dashboard`.
  factory EmployeeRequest.fromApi(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final category = json['category'] as String?;
    final typeId = (json['typeId'] as num?)?.toInt();
    final fromDate = _parseDate(json['fromDate']);
    final toDate = _parseDate(json['toDate']);
    final entered = _parseDate(json['enteredAt'] ?? json['submittedAt']);
    final rejectReason = (json['rejectReason'] as String?)?.trim();
    final days = (json['days'] as num?)?.toInt();

    return EmployeeRequest(
      id: json['id'].toString(),
      kind: kindFromCode(code, category: category, typeId: typeId),
      status: statusFromApi(json['status'] as String?),
      requestedAt: entered ?? fromDate ?? DateTime.now(),
      note: _describe(
        fromDate: fromDate,
        toDate: toDate,
        days: days,
        rejectReason: rejectReason,
        state: json['state'] as String?,
      ),
      typeLabel: json['type'] as String?,
      code: code,
      fromDate: fromDate,
      toDate: toDate,
      days: days,
      rejectReason: (rejectReason ?? '').isEmpty ? null : rejectReason,
      canWithdraw: json['canWithdraw'] as bool? ?? false,
    );
  }

  static RequestStatus statusFromApi(String? status) => switch (status) {
        'approved' => RequestStatus.approved,
        'rejected' => RequestStatus.rejected,
        _ => RequestStatus.pending,
      };

  static RequestKind kindFromCode(
    String? code, {
    String? category,
    int? typeId,
  }) {
    switch (code) {
      case 'LATE_ARRIVAL':
        return RequestKind.delayPermission;
      case 'EARLY_LEAVE':
        return RequestKind.earlyLeavePermission;
      case 'EMERGENCY_LEAVE':
        return RequestKind.emergencyLeave;
      case 'ANNUAL_LEAVE':
        return RequestKind.annualLeave;
      case 'STUDY_LEAVE':
        return RequestKind.studyLeave;
    }
    if (typeId == 1) return RequestKind.delayPermission;
    if (typeId == 2) return RequestKind.earlyLeavePermission;
    return RequestKind.other;
  }

  static String _describe({
    DateTime? fromDate,
    DateTime? toDate,
    int? days,
    String? rejectReason,
    String? state,
  }) {
    final parts = <String>[];
    if (fromDate != null && toDate != null && toDate != fromDate) {
      parts.add('من ${formatDay(fromDate)} إلى ${formatDay(toDate)}');
      if (days != null && days > 0) parts.add('$days ${days == 1 ? 'يوم' : 'أيام'}');
    } else if (fromDate != null) {
      parts.add('ليوم ${formatDay(fromDate)}');
    }
    if (rejectReason != null && rejectReason.isNotEmpty) {
      parts.add('سبب الرفض: $rejectReason');
    }
    if (parts.isEmpty && state != null && state.trim().isNotEmpty) {
      parts.add(state.trim());
    }
    return parts.join(' · ');
  }

  static String formatDay(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final text = raw.trim();
    if (text.startsWith('0000') || text.startsWith('1899')) return null;
    return DateTime.tryParse(text);
  }
}

/// عدّادات الطلبات حسب الحالة (`RequestCountsDto`).
class RequestCounts {
  const RequestCounts({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int pending;
  final int approved;
  final int rejected;

  int of(RequestStatus status) => switch (status) {
        RequestStatus.pending => pending,
        RequestStatus.approved => approved,
        RequestStatus.rejected => rejected,
      };

  factory RequestCounts.fromApi(Map<String, dynamic> json) => RequestCounts(
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        approved: (json['approved'] as num?)?.toInt() ?? 0,
        rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      );
}

/// بيانات الصفحة الرئيسية للموظف (مقابل `DashboardDto` من `GET /me/dashboard`).
class EmployeeDashboardData {
  const EmployeeDashboardData({
    required this.annualBalance,
    required this.emergencyBalance,
    required this.pendingEmergencyCount,
    required this.pendingAnnualCount,
    required this.delayPermissionCount,
    required this.earlyLeaveCount,
    required this.entryExitPermissionsTakenThisMonth,
    required this.requests,
    this.permissionBalanceRemaining,
    this.annualBalanceAvailable = true,
    this.permissionsAvailable = true,
    this.employeeName,
    this.workplaceName,
    this.counts,
    this.unreadNotifications = 0,
    this.warnings = const [],
    this.asOf,
  });

  /// رصيد السنوية حتى اليوم (أيام كاملة). انظر [annualBalanceAvailable].
  final int annualBalance;

  /// رصيد الطارئة المتبقي هذه السنة (12 − المستخدم).
  final int emergencyBalance;
  final int pendingEmergencyCount;
  final int pendingAnnualCount;

  /// أذونات التأخير هذا الشهر (نوع 1).
  final int delayPermissionCount;

  /// أذونات الخروج المبكر هذا الشهر (نوع 2).
  final int earlyLeaveCount;

  /// عدد أذونات الدخول والخروج المأخوذة خلال هذا الشهر (نوع 1 + 2).
  final int entryExitPermissionsTakenThisMonth;

  /// الطلبات المضمّنة في الاستجابة (المعلّقة والمرفوضة الأخيرة؛ حتى 20 لكل حالة).
  /// المقبولة تُجلب بالتصفح عبر `GET /me/requests?status=approved`.
  final List<EmployeeRequest> requests;

  /// رصيد الأذونات المتبقي لهذا الشهر (الحد 3 − المستخدم).
  final int? permissionBalanceRemaining;

  /// `false` عندما يعيد الخادم `annual: null` (موظف غير نشط / بلا تاريخ بداية).
  final bool annualBalanceAvailable;

  /// `false` عندما يفشل قسم الأذونات (قاعدة البصمة غير متاحة مثلاً).
  final bool permissionsAvailable;

  /// اسم الموظف ومكان عمله كما في `employee_card` / `taksem`.
  final String? employeeName;
  final String? workplaceName;
  final RequestCounts? counts;
  final int unreadNotifications;

  /// أقسام لم تُحمّل (`warnings[].section`).
  final List<String> warnings;
  final DateTime? asOf;

  bool get hasWarnings => warnings.isNotEmpty;

  List<EmployeeRequest> byStatus(RequestStatus status) => [
        for (final r in requests)
          if (r.status == status) r,
      ];

  /// تحويل `DashboardDto`. كل قسم قد يكون `null` مع تحذير — نعرض «—» بدل الصفر.
  factory EmployeeDashboardData.fromApi(Map<String, dynamic> json) {
    final employee = _map(json['employee']);
    final permissions = _map(json['permissions']);
    final leave = _map(json['leave']);
    final requests = _map(json['requests']);
    final notifications = _map(json['notifications']);

    final emergency = _map(leave?['emergency']);
    final annual = _map(leave?['annual']);
    final monthlyBalance = _map(permissions?['monthlyBalance']);
    final monthlyCounts = (permissions?['monthlyCounts'] as List?) ?? const [];

    int countForType(int type) {
      for (final item in monthlyCounts) {
        if (item is Map && (item['type'] as num?)?.toInt() == type) {
          return (item['count'] as num?)?.toInt() ?? 0;
        }
      }
      return 0;
    }

    final list = <EmployeeRequest>[
      for (final item in (requests?['pending'] as List?) ?? const [])
        if (item is Map<String, dynamic>) EmployeeRequest.fromApi(item),
      for (final item in (requests?['rejected'] as List?) ?? const [])
        if (item is Map<String, dynamic>) EmployeeRequest.fromApi(item),
    ];

    final warnings = <String>[
      for (final w in (json['warnings'] as List?) ?? const [])
        if (w is Map && w['section'] is String) w['section'] as String,
    ];

    return EmployeeDashboardData(
      annualBalance: (annual?['balance'] as num?)?.toInt() ?? 0,
      annualBalanceAvailable: annual != null,
      emergencyBalance: (emergency?['remaining'] as num?)?.toInt() ?? 0,
      pendingEmergencyCount:
          (emergency?['pendingRequests'] as num?)?.toInt() ?? 0,
      pendingAnnualCount: (annual?['pendingRequests'] as num?)?.toInt() ?? 0,
      delayPermissionCount: countForType(1),
      earlyLeaveCount: countForType(2),
      entryExitPermissionsTakenThisMonth:
          (monthlyBalance?['used'] as num?)?.toInt() ?? 0,
      permissionBalanceRemaining:
          (monthlyBalance?['remaining'] as num?)?.toInt(),
      permissionsAvailable: permissions != null,
      requests: list,
      employeeName: (employee?['fullName'] as String?)?.trim(),
      workplaceName: (employee?['workplaceName'] as String?)?.trim(),
      counts: requests?['counts'] is Map<String, dynamic>
          ? RequestCounts.fromApi(requests!['counts'] as Map<String, dynamic>)
          : null,
      unreadNotifications: (notifications?['unread'] as num?)?.toInt() ?? 0,
      warnings: warnings,
      asOf: json['asOf'] is String ? DateTime.tryParse(json['asOf']) : null,
    );
  }

  static Map<String, dynamic>? _map(Object? value) =>
      value is Map<String, dynamic> ? value : null;
}

/// نوع مخزّن في `employee_app_request_panel.permission_type`
/// (`RequestPanelTypeDto` من `GET /lookups/request-types`) — قائمة «بحث حسب النوع».
class RequestPanelType {
  const RequestPanelType({
    required this.label,
    required this.code,
    required this.group,
    required this.isLeave,
    this.type,
  });

  factory RequestPanelType.fromApi(Map<String, dynamic> json) => RequestPanelType(
        label: (json['label'] as String? ?? '').trim(),
        code: json['code'] as String? ?? '',
        group: json['group'] as String? ?? '',
        isLeave: json['category'] == 'leave',
        type: (json['type'] as num?)?.toInt(),
      );

  /// التسمية كما تُخزَّن حرفياً (مثل «إجازة سنوية»).
  final String label;

  /// رمز الكتالوج الثابت (مثل `ANNUAL_LEAVE`) — يُرسل كـ `type=` للفلترة.
  final String code;

  /// عنوان المجموعة القديم («أنواع الأذونات» / «أنواع الإجازات»).
  final String group;
  final bool isLeave;

  /// الرقم (`permissions.TypeH`) للأذونات؛ null للإجازات.
  final int? type;
}

/// صفحة من قائمة الطلبات (`{ data, meta }` من `GET /me/requests`).
class RequestsPage {
  const RequestsPage({
    required this.items,
    required this.page,
    required this.hasNext,
    this.total,
  });

  final List<EmployeeRequest> items;
  final int page;
  final bool hasNext;

  /// يظهر فقط عند طلب `withTotal=true`.
  final int? total;

  static const empty = RequestsPage(items: [], page: 1, hasNext: false);

  factory RequestsPage.fromApi(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return RequestsPage(
      items: [
        for (final item in (json['data'] as List?) ?? const [])
          if (item is Map<String, dynamic>) EmployeeRequest.fromApi(item),
      ],
      page: (meta['page'] as num?)?.toInt() ?? 1,
      hasNext: meta['hasNext'] as bool? ?? false,
      total: (meta['total'] as num?)?.toInt(),
    );
  }
}
