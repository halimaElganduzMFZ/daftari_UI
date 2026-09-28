import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/dashboard_repository.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';

void main() {
  test('employee withdraw posts /me/requests/:id/withdraw', () async {
    late Uri uri;
    final client = ApiClient(
      getAccessToken: () async => 'token',
      httpClient: MockClient((request) async {
        uri = request.url;
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(
          jsonEncode({'message': 'تم التراجع عن الطلب'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);
    final result = await ApiDashboardRepository(client).withdraw('92');
    expect(uri.path, endsWith('/me/requests/92/withdraw'));
    expect(result['message'], 'تم التراجع عن الطلب');
  });

  test('on-behalf withdraw posts manager path', () async {
    late Uri uri;
    final client = ApiClient(
      getAccessToken: () async => 'token',
      httpClient: MockClient((request) async {
        uri = request.url;
        expect(request.method, 'POST');
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    await ManagerRepository(client).withdraw(
      '/manager/on-behalf/employees/4321/requests',
      88,
    );
    expect(
      uri.path,
      endsWith('/manager/on-behalf/employees/4321/requests/88/withdraw'),
    );
  });
}
