import '../models/employee_dashboard.dart';

/// بيانات ثابتة لشاشة الموظف العادي — مستخرجة من أقسام index.php.
abstract final class StaticEmployeeDashboard {
  static final data = EmployeeDashboardData(
    annualBalance: 18,
    emergencyBalance: 7,
    permissionBalanceRemaining: 3,
    pendingEmergencyCount: 1,
    pendingAnnualCount: 0,
    delayPermissionCount: 2,
    earlyLeaveCount: 1,
    requests: [
      EmployeeRequest(
        id: 'r1',
        kind: RequestKind.emergencyLeave,
        status: RequestStatus.pending,
        requestedAt: DateTime(2026, 9, 10),
        note: 'ظرف عائلي طارئ — يوم واحد',
      ),
      EmployeeRequest(
        id: 'r2',
        kind: RequestKind.delayPermission,
        status: RequestStatus.pending,
        requestedAt: DateTime(2026, 9, 8),
        note: 'مراجعة طبية صباحية',
      ),
      EmployeeRequest(
        id: 'r3',
        kind: RequestKind.annualLeave,
        status: RequestStatus.approved,
        requestedAt: DateTime(2026, 8, 20),
        note: 'إجازة سنوية 3 أيام',
      ),
      EmployeeRequest(
        id: 'r4',
        kind: RequestKind.earlyLeavePermission,
        status: RequestStatus.rejected,
        requestedAt: DateTime(2026, 8, 12),
        note: 'خروج مبكر — غير مكتمل المستندات',
      ),
      EmployeeRequest(
        id: 'r5',
        kind: RequestKind.annualLeave,
        status: RequestStatus.approved,
        requestedAt: DateTime(2026, 7, 3),
        note: 'إجازة سنوية يومان',
      ),
    ],
  );
}
