import '../../core/network/api_client.dart';
import '../models/employee_dashboard.dart';
import '../static/static_employee_dashboard.dart';

/// مصدر بيانات الصفحة الرئيسية وقائمة الطلبات.
///
/// الواجهة واحدة؛ التنفيذ إما ثابت (للتصميم) أو عبر Nest API:
/// - `load()`     → `GET /me/dashboard`
/// - `requests()` → `GET /me/requests?status=&page=&limit=`
abstract class DashboardRepository {
  Future<EmployeeDashboardData> load();

  Future<RequestsPage> requests({
    required RequestStatus status,
    int page = 1,
    int limit = 10,
    bool withTotal = false,
  });
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
    required RequestStatus status,
    int page = 1,
    int limit = 10,
    bool withTotal = false,
  }) async {
    final json = await _client.getJson(
      '/me/requests',
      query: {
        'status': status.name,
        'page': '$page',
        'limit': '${limit.clamp(1, 200)}',
        if (withTotal) 'withTotal': 'true',
      },
    );
    return RequestsPage.fromApi(json);
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

  @override
  Future<RequestsPage> requests({
    required RequestStatus status,
    int page = 1,
    int limit = 10,
    bool withTotal = false,
  }) async {
    await Future<void>.delayed(latency);
    final all = StaticEmployeeDashboard.data.byStatus(status)
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
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
}
