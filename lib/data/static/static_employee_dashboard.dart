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

    final list = <EmployeeRequest>[];
    var id = 1;

    // طلبات حالية قيد المراجعة
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
    ]);

    // دفعة كبيرة من الطلبات المقبولة لاختبار pagination (صفحة طلباتي = 8).
    for (var year = 2026; year >= 2023; year--) {
      final approvedCount = year == 2026 ? 24 : 16;
      for (var i = 0; i < approvedCount; i++) {
        final month = 1 + ((i * 2) % 12);
        final day = 1 + ((i * 3) % 27);
        final kind = kinds[(year + i) % kinds.length];
        list.add(
          EmployeeRequest(
            id: 'r${id++}',
            kind: kind,
            status: RequestStatus.approved,
            requestedAt: DateTime(year, month, day, 9 + (i % 6), (i * 7) % 60),
            note: kind == RequestKind.studyLeave
                ? 'إجازة دراسية معتمدة — $year'
                : '${notes[(year + i) % notes.length]} — مقبول $year',
            attachment: kind == RequestKind.studyLeave
                ? RequestAttachment.demoStudy(
                    fileName: 'مرفق_دراسي_مقبول_$year.pdf',
                    sizeBytes: 480000 + (i * 15000),
                  )
                : null,
          ),
        );
      }

      // دفعات كافية للمعلّقة والمرفوضة ليظهر «عرض المزيد» في الرئيسية أيضاً
      final otherCount = year == 2026 ? 14 : 10;
      for (var i = 0; i < otherCount; i++) {
        final kind = kinds[(year + i + 3) % kinds.length];
        final rejected = i.isEven;
        list.add(
          EmployeeRequest(
            id: 'r${id++}',
            kind: kind,
            status: rejected ? RequestStatus.rejected : RequestStatus.pending,
            requestedAt: DateTime(year, 6 + (i % 6), 5 + (i % 20)),
            note: rejected
                ? '${notes[i % notes.length]} — مرفوض $year'
                : '${notes[(i + 2) % notes.length]} — قيد المراجعة $year',
          ),
        );
      }
    }

    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return List<EmployeeRequest>.unmodifiable(list);
  }
}
