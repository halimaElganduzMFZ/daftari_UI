import '../../core/network/api_client.dart';
import '../models/employee_dashboard.dart';
import '../static/static_employee_dashboard.dart';
import '../static/static_permission_types.dart';

/// مصدر بيانات الصفحة الرئيسية وقائمة الطلبات.
///
/// الواجهة واحدة؛ التنفيذ إما ثابت (للتصميم) أو عبر Nest API:
/// - `load()`         → `GET /me/dashboard`
/// - `requests()`     → `GET /me/requests?status=&type=&page=&limit=`
/// - `requestTypes()` → `GET /lookups/request-types` (قائمة «بحث حسب النوع»)
abstract class DashboardRepository {
  Future<EmployeeDashboardData> load();

  /// `status == null` ⇒ كل الحالات. `type` رمز كتالوج (`ANNUAL_LEAVE`)
  /// أو رقم نوع (`1`) أو التسمية الحرفية.
  Future<RequestsPage> requests({
    RequestStatus? status,
    String? type,
    int page = 1,
    int limit = 10,
    bool withTotal = false,
  });

  Future<List<RequestPanelType>> requestTypes();
}

/// تنفيذ عبر الـ API. الرقم الوظيفي يأتي من التوكن؛ لا نرسل معرّف الموظف.
class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository(this._client);

  final ApiClient _client;

  @override
  Future<EmployeeDashboardData> load() async {
    final json = await _client.getJson('/me/dashboard');
    return EmployeeDashboardData.fromApi(json);
  }

  @override
  Future<RequestsPage> requests({
    RequestStatus? status,
    String? type,
    int page = 1,
    int limit = 10,
    bool withTotal = false,
  }) async {
    final json = await _client.getJson(
      '/me/requests',
      query: {
        'status': status?.name ?? 'all',
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        'page': '$page',
        'limit': '${limit.clamp(1, 200)}',
        if (withTotal) 'withTotal': 'true',
      },
    );
    return RequestsPage.fromApi(json);
  }

  @override
  Future<List<RequestPanelType>> requestTypes() async {
    final list = await _client.getJsonList('/lookups/request-types');
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) RequestPanelType.fromApi(item),
    ];
  }
}

/// تنفيذ ثابت — نفس السلوك (تأخير بسيط + تصفح) فوق البيانات التجريبية.
class StaticDashboardRepository implements DashboardRepository {
  const StaticDashboardRepository({
    this.latency = const Duration(milliseconds: 350),
  });

  final Duration latency;

  @override
  Future<EmployeeDashboardData> load() async {
    await Future<void>.delayed(latency);
    final source = StaticEmployeeDashboard.data;
    final pending = source.byStatus(RequestStatus.pending);
    final rejected = source.byStatus(RequestStatus.rejected);
    final approved = source.byStatus(RequestStatus.approved);

    return EmployeeDashboardData(
      annualBalance: source.annualBalance,
      emergencyBalance: source.emergencyBalance,
      pendingEmergencyCount: source.pendingEmergencyCount,
      pendingAnnualCount: source.pendingAnnualCount,
      delayPermissionCount: source.delayPermissionCount,
      earlyLeaveCount: source.earlyLeaveCount,
      entryExitPermissionsTakenThisMonth:
          source.entryExitPermissionsTakenThisMonth,
      permissionBalanceRemaining: source.permissionBalanceRemaining,
      // مثل الـ API: أحدث 20 معلّقاً/مرفوضاً فقط داخل اللوحة.
      requests: [...pending.take(20), ...rejected.take(20)],
      counts: RequestCounts(
        pending: pending.length,
        approved: approved.length,
        rejected: rejected.length,
      ),
      asOf: DateTime.now(),
    );
  }

  static const _kindCodes = <RequestKind, String>{
    RequestKind.delayPermission: 'LATE_ARRIVAL',
    RequestKind.earlyLeavePermission: 'EARLY_LEAVE',
    RequestKind.emergencyLeave: 'EMERGENCY_LEAVE',
    RequestKind.annualLeave: 'ANNUAL_LEAVE',
    RequestKind.studyLeave: 'STUDY_LEAVE',
  };

  @override
  Future<RequestsPage> requests({
    RequestStatus? status,
    String? type,
    int page = 1,
    int limit = 10,
    bool withTotal = false,
  }) async {
    await Future<void>.delayed(latency);
    final source = StaticEmployeeDashboard.data;
    final all = [
      for (final r in status == null ? source.requests : source.byStatus(status))
        if (type == null ||
            type.isEmpty ||
            (r.code ?? _kindCodes[r.kind]) == type ||
            r.typeLabel == type ||
            r.displayTitle == type)
          r,
    ]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    final start = (page - 1) * limit;
    final slice = start >= all.length
        ? const <EmployeeRequest>[]
        : all.sublist(start, (start + limit).clamp(0, all.length));
    return RequestsPage(
      items: slice,
      page: page,
      hasNext: start + limit < all.length,
      total: withTotal ? all.length : null,
    );
  }

  @override
  Future<List<RequestPanelType>> requestTypes() async {
    await Future<void>.delayed(latency);
    return [
      for (final t in StaticPermissionTypes.all)
        RequestPanelType(
          label: t.title,
          code: switch (t.id) {
            '1' => 'LATE_ARRIVAL',
            '2' => 'EARLY_LEAVE',
            _ => 'PERMISSION_${t.id}',
          },
          group: 'أنواع الأذونات',
          isLeave: false,
          type: int.tryParse(t.id),
        ),
      const RequestPanelType(
        label: 'إجازة سنوية',
        code: 'ANNUAL_LEAVE',
        group: 'أنواع الإجازات',
        isLeave: true,
      ),
      const RequestPanelType(
        label: 'طارئة',
        code: 'EMERGENCY_LEAVE',
        group: 'أنواع الإجازات',
        isLeave: true,
      ),
      const RequestPanelType(
        label: 'إجازة دراسية',
        code: 'STUDY_LEAVE',
        group: 'أنواع الإجازات',
        isLeave: true,
      ),
    ];
  }
}
