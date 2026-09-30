import 'dart:async';
import 'dart:convert';

import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/dashboard_repository.dart';
import 'package:employee_affairs/data/session/app_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late int calls;
  late Completer<void> reply;
  late List<int> statuses;
  late ApiDashboardRepository repository;

  setUp(() {
    calls = 0;
    reply = Completer<void>();
    statuses = [];
    AppSession.accessToken = 'first';
    final client = ApiClient(
      getAccessToken: () async => AppSession.accessToken,
      httpClient: MockClient((request) async {
        expect(request.url.path, endsWith('/me/dashboard'));
        final status = calls < statuses.length ? statuses[calls] : 200;
        calls++;
        await reply.future;
        return http.Response(
          jsonEncode(status == 200 ? {'asOf': '2026-09-29T08:00:00Z'} : {}),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);
    addTearDown(AppSession.clear);
    repository = ApiDashboardRepository(client);
  });

  test('home and leaves loading together share one request', () async {
    final home = repository.load();
    final leaves = repository.load();
    reply.complete();
    expect(identical(await home, await leaves), isTrue);
    expect(calls, 1);
  });

  test('a load after the first one finished asks the server again', () async {
    reply.complete();
    await repository.load();
    await repository.load();
    expect(calls, 2);
  });

  test('another token never receives the running request', () async {
    final before = repository.load();
    AppSession.accessToken = 'second';
    final after = repository.load();
    reply.complete();
    await Future.wait([before, after]);
    expect(calls, 2);
  });

  test('a failure reaches every waiting screen and is not kept', () async {
    statuses = [500];
    final home = repository.load();
    final leaves = repository.load();
    reply.complete();
    await expectLater(home, throwsA(anything));
    await expectLater(leaves, throwsA(anything));
    await repository.load();
    expect(calls, 2);
  });
}
