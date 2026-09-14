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

class EmployeeRequest {
  const EmployeeRequest({
    required this.id,
    required this.kind,
    required this.status,
    required this.requestedAt,
    required this.note,
    this.attachment,
  });

  final String id;
  final RequestKind kind;
  final RequestStatus status;
  final DateTime requestedAt;
  final String note;
  final RequestAttachment? attachment;
}

class EmployeeDashboardData {
  const EmployeeDashboardData({
    required this.annualBalance,
    required this.emergencyBalance,
    required this.pendingEmergencyCount,
    required this.pendingAnnualCount,
    required this.delayPermissionCount,
    required this.earlyLeaveCount,
    required this.requests,
    this.permissionBalanceRemaining,
  });

  final int annualBalance;
  final int emergencyBalance;
  final int pendingEmergencyCount;
  final int pendingAnnualCount;
  final int delayPermissionCount;
  final int earlyLeaveCount;
  final List<EmployeeRequest> requests;

  /// رصيد الأذونات المتبقي لهذا الشهر (من index.php).
  final int? permissionBalanceRemaining;
}
