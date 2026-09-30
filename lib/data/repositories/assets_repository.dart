import '../../core/network/api_client.dart';
import '../models/employee_asset.dart';
import '../static/static_employee_assets.dart';

/// الأصول المسجّلة على الموظف (بديل `Employee_Assets.php`) — `GET /me/assets`.
abstract class AssetsRepository {
  Future<EmployeeAssetsResult> list();
}

class ApiAssetsRepository implements AssetsRepository {
  const ApiAssetsRepository(this._client);

  final ApiClient _client;

  @override
  Future<EmployeeAssetsResult> list() async {
    final json = await _client.getJson('/me/assets');
    return EmployeeAssetsResult.fromApi(json);
  }
}

class StaticAssetsRepository implements AssetsRepository {
  const StaticAssetsRepository({
    this.latency = const Duration(milliseconds: 350),
  });

  final Duration latency;

  @override
  Future<EmployeeAssetsResult> list() async {
    await Future<void>.delayed(latency);
    return const EmployeeAssetsResult(
      available: true,
      assets: kStaticEmployeeAssets,
    );
  }
}
