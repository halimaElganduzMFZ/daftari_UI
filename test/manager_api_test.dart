import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/core/network/api_exception.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/data/repositories/permission_requests_repository.dart';
import 'package:employee_affairs/data/repositories/leave_requests_repository.dart';

http.Response jsonResponse(
  String body,
  int status, {
  Map<String, String>? headers,
}) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {...?headers, 'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('AWOL count uses singular route and accepts zero', () async {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/manager/awol/count');
        expect(request.url.queryParameters, isEmpty);
        return jsonResponse('{"count":0}', 200);
      }),
    );
    addTearDown(client.close);
    expect(await ManagerRepository(client).awolCount(), 0);
  });

  test('on-behalf leave options follow selected employee and date', () async {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        final firstEmployee = request.url.path.contains('/employees/4321/');
        expect(request.url.path, endsWith('/leave/requests/options'));
        expect(request.url.path, contains('/manager/on-behalf/employees/'));
        final open =
            firstEmployee &&
            request.url.queryParameters['date'] == '2026-09-23';
        return jsonResponse(
          jsonEncode({
            'shift': {'status': 'ok', 'shift': open ? 'OPEN' : 'REGULAR'},
            'exceptionAvailable': open,
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);
    final first = ApiLeaveRequestsRepository(
      client,
      basePath: '/manager/on-behalf/employees/4321/leave/requests',
    );
    final second = ApiLeaveRequestsRepository(
      client,
      basePath: '/manager/on-behalf/employees/5678/leave/requests',
    );
    final initial = await first.options(date: DateTime(2026, 9, 23));
    expect(initial.shift.shift, 'OPEN');
    expect(initial.exceptionAvailable, true);
    final changedDate = await first.options(date: DateTime(2026, 9, 24));
    expect(changedDate.shift.shift, 'REGULAR');
    expect(changedDate.exceptionAvailable, false);
    final changedEmployee = await second.options(date: DateTime(2026, 9, 23));
    expect(changedEmployee.shift.shift, 'REGULAR');
    expect(changedEmployee.exceptionAvailable, false);
  });

  test(
    'manager pagination and filters use authenticated server pages',
    () async {
      final client = ApiClient(
        getAccessToken: () async => 'manager-token',
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer manager-token');
          expect(request.url.path, endsWith('/manager/requests'));
          expect(request.url.queryParameters, {
            'page': '2',
            'limit': '20',
            'withTotal': 'true',
            'status': 'pending',
            'employeeNumber': '50651',
          });
          return jsonResponse(
            jsonEncode({
              'data': [
                {'id': 92},
              ],
              'meta': {'hasNext': true, 'total': 41},
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final page = await ManagerRepository(client).page(
        '/manager/requests',
        page: 2,
        filters: {'status': 'pending', 'employeeNumber': '50651'},
      );
      expect(page.items.single['id'], 92);
      expect(page.hasNext, isTrue);
      expect(page.total, 41);
    },
  );

  test(
    'intermediate approval remains pending and conflicts propagate',
    () async {
      var calls = 0;
      final client = ApiClient(
        getAccessToken: () async => 'manager-token',
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer manager-token');
          expect(request.method, 'POST');
          expect(request.url.path, endsWith('/manager/requests/92/approve'));
          if (calls++ == 0) {
            return jsonResponse(
              jsonEncode({
                'status': 'pending',
                'state': 'تمت موافقة مدير الوحدة',
              }),
              200,
            );
          }
          return jsonResponse(
            jsonEncode({
              'code': 'ALREADY_DECIDED',
              'message': 'تم اتخاذ القرار مسبقًا',
            }),
            409,
          );
        }),
      );
      addTearDown(client.close);
      final repo = ManagerRepository(client);
      expect((await repo.decide(92))['status'], 'pending');
      await expectLater(
        repo.decide(92),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'ALREADY_DECIDED'),
        ),
      );
    },
  );

  test('rejection and AWOL confirmation send the documented bodies', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      getAccessToken: () async => 'manager-token',
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer manager-token');
        return jsonResponse('{}', 200);
      }),
    );
    addTearDown(client.close);
    final repo = ManagerRepository(client);
    await repo.decide(92, reason: ' سبب الرفض ');
    await repo.confirmAwol(7438, ' ملاحظة المدير ');
    expect(requests[0].url.path, endsWith('/92/reject'));
    expect(jsonDecode(requests[0].body), {'reason': 'سبب الرفض'});
    expect(requests[1].url.path, endsWith('/manager/awol/7438/confirm'));
    expect(jsonDecode(requests[1].body), {'notes': 'ملاحظة المدير'});
  });

  test(
    'on-behalf permission, leave, preview and upload never use /me',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        getAccessToken: () async => 'manager-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          expect(request.headers['Authorization'], 'Bearer manager-token');
          expect(
            request.url.path,
            contains('/manager/on-behalf/employees/4321/'),
          );
          return jsonResponse('{}', 200);
        }),
      );
      addTearDown(client.close);
      const base = '/manager/on-behalf/employees/4321';
      final permissions = ApiPermissionRequestsRepository(
        client,
        basePath: '$base/requests',
      );
      final leaves = ApiLeaveRequestsRepository(
        client,
        basePath: '$base/leave/requests',
      );
      final date = DateTime(2026, 9, 23);
      await permissions.options(date: date);
      await permissions.submit(type: 1, date: date);
      await leaves.options(date: date);
      await leaves.preview(kind: 'ANNUAL_LEAVE', from: date, exception: true);
      await leaves.submit(kind: 'ANNUAL_LEAVE', from: date, exception: true);
      await leaves.submit(
        kind: 'STUDY_LEAVE',
        from: date,
        attachment: LeaveAttachmentUpload(
          fileName: 'study.pdf',
          bytes: Uint8List.fromList([37, 80, 68, 70]),
          contentType: 'application/pdf',
        ),
      );
      expect(requests, hasLength(6));
      expect(requests[3].url.queryParameters['exception'], 'true');
      expect(jsonDecode(requests[4].body)['exception'], true);
      expect(
        requests[5].headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(requests[5].body, contains('name="attachment"'));
    },
  );

  test('ordinary employee repositories retain /me routes', () async {
    final paths = <String>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        return jsonResponse('{}', 200);
      }),
    );
    addTearDown(client.close);
    await ApiPermissionRequestsRepository(client)
        .submit(type: 1, date: DateTime(2026, 9, 23));
    await ApiLeaveRequestsRepository(client)
        .submit(kind: 'ANNUAL_LEAVE', from: DateTime(2026, 9, 23));
    expect(paths[0], endsWith('/me/requests'));
    expect(paths[1], endsWith('/me/leave/requests'));
  });
}
