import '../models/employee_dashboard.dart';
import '../models/request_attachment.dart';

/// بيانات ثابتة لشاشة الموظف العادي — سجل طلبات لعدة سنوات لاختبار التصفح.
abstract final class StaticEmployeeDashboard {
  static final data = EmployeeDashboardData(
    annualBalance: 18,
    emergencyBalance: 7,
    permissionBalanceRemaining: 3,
    pendingEmergencyCount: 1,
    pendingAnnualCount: 0,
    delayPermissionCount: 2,
    earlyLeaveCount: 1,
    requests: _buildHistory(),
  );

  static List<EmployeeRequest> _buildHistory() {
    const notes = [
      'ظرف عائلي',
      'مراجعة طبية صباحية',
      'إجازة سنوية مخطط لها',
      'خروج مبكر لموعد رسمي',
      'تأخير بسبب ازدحام الطريق',
      'مهمة عائلية قصيرة',
      'إجازة طارئة ليوم واحد',
      'استكمال مستندات',
    ];
    const kinds = [
      RequestKind.annualLeave,
      RequestKind.emergencyLeave,
      RequestKind.delayPermission,
      RequestKind.earlyLeavePermission,
      RequestKind.studyLeave,
      RequestKind.other,
    ];
    const statuses = [
      RequestStatus.approved,
      RequestStatus.approved,
      RequestStatus.pending,
      RequestStatus.rejected,
      RequestStatus.approved,
    ];

    final list = <EmployeeRequest>[];
    var id = 1;

    list.addAll([
      EmployeeRequest(
        id: 'r${id++}',
        kind: RequestKind.studyLeave,
        status: RequestStatus.pending,
        requestedAt: DateTime(2026, 9, 11),
        note: 'إجازة دراسية — فصل الخريف مع مرفق القبول',
        attachment: RequestAttachment.demoStudy(
          fileName: 'قبول_جامعي_خريف_2026.pdf',
          sizeBytes: 918000,
        ),
      ),
      EmployeeRequest(
        id: 'r${id++}',
        kind: RequestKind.emergencyLeave,
        status: RequestStatus.pending,
        requestedAt: DateTime(2026, 9, 10),
        note: 'ظرف عائلي طارئ — يوم واحد',
      ),
      EmployeeRequest(
        id: 'r${id++}',
        kind: RequestKind.delayPermission,
        status: RequestStatus.pending,
        requestedAt: DateTime(2026, 9, 8),
        note: 'مراجعة طبية صباحية',
      ),
      EmployeeRequest(
        id: 'r${id++}',
        kind: RequestKind.studyLeave,
        status: RequestStatus.approved,
        requestedAt: DateTime(2025, 2, 14),
        note: 'إجازة دراسية معتمدة — مرفق خطاب القبول',
        attachment: RequestAttachment.demoStudy(
          fileName: 'خطاب_قبول_2025.pdf',
          sizeBytes: 704000,
        ),
      ),
    ]);

    for (var year = 2026; year >= 2023; year--) {
      final count = year == 2026 ? 14 : 12;
      for (var i = 0; i < count; i++) {
        final month = 1 + ((i * 3) % 12);
        final day = 2 + ((i * 2) % 26);
        final kind = kinds[(year + i) % kinds.length];
        list.add(
          EmployeeRequest(
            id: 'r${id++}',
            kind: kind,
            status: year == 2026 && i < 2
                ? RequestStatus.pending
                : statuses[(year + i) % statuses.length],
            requestedAt: DateTime(year, month, day),
            note: kind == RequestKind.studyLeave
                ? 'إجازة دراسية — $year'
                : '${notes[(year + i) % notes.length]} — $year',
            attachment: kind == RequestKind.studyLeave
                ? RequestAttachment.demoStudy(
                    fileName: 'مرفق_دراسي_$year.pdf',
                    sizeBytes: 480000 + (i * 15000),
                  )
                : null,
          ),
        );
      }
    }

    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return List<EmployeeRequest>.unmodifiable(list);
  }
}
