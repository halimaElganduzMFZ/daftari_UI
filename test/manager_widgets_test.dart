import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/features/manager/remote_manager_requests_screen.dart';
import 'package:employee_affairs/features/manager/remote_manager_widgets.dart';

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
  testWidgets('refresh ignores a stale response from the old query', (
    tester,
  ) async {
    final first = Completer<ManagerPage>();
    final second = Completer<ManagerPage>();
    final key = GlobalKey<ManagerPagedListState>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagerPagedList(
            key: key,
            load: (_) => calls++ == 0 ? first.future : second.future,
            itemBuilder: (item) => Text('${item['name']}'),
          ),
        ),
      ),
    );
    final refresh = key.currentState!.refresh();
    second.complete(
      const ManagerPage(
        [
          {'id': 2, 'name': 'new result'},
        ],
        false,
        1,
      ),
    );
    await refresh;
    await tester.pump();
    first.complete(
      const ManagerPage(
        [
          {'id': 1, 'name': 'stale result'},
        ],
        false,
        1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('new result'), findsOneWidget);
    expect(find.text('stale result'), findsNothing);
  });

  testWidgets('failed next page preserves existing records and can retry', (
    tester,
  ) async {
    var secondCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagerPagedList(
            load: (page) async {
              if (page == 1) {
                return const ManagerPage(
                  [
                    {'id': 1, 'name': 'first record'},
                  ],
                  true,
                  2,
                );
              }
              if (secondCalls++ == 0) throw Exception('offline');
              return const ManagerPage(
                [
                  {'id': 2, 'name': 'second record'},
                ],
                false,
                2,
              );
            },
            itemBuilder: (item) => Text('${item['name']}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض المزيد'));
    await tester.pumpAndSettle();
    expect(find.text('first record'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('first record'), findsOneWidget);
    expect(find.text('second record'), findsOneWidget);
  });

  testWidgets('server decision permissions control approval buttons', (
    tester,
  ) async {
    final client = ApiClient(
      httpClient: MockClient(
        (request) async => jsonResponse(
          jsonEncode({
            'id': 92,
            'type': 'إجازة سنوية',
            'state': 'طلب من الموظف',
            'decision': {'canDecide': false, 'blockedBy': 'NOT_FINAL_APPROVER'},
          }),
          200,
        ),
      ),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerRequestDetailScreen(
          repository: ManagerRepository(client),
          path: '/manager/requests',
          item: const {'id': 92},
          canDecide: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('موافقة'), findsNothing);
    expect(find.text('رفض مع ذكر السبب'), findsNothing);
  });

  testWidgets('failed approval shows server error and no fabricated success', (
    tester,
  ) async {
    var posts = 0;
    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          posts++;
          return jsonResponse(
            jsonEncode({
              'code': 'ALREADY_DECIDED',
              'message': 'اتخذ القرار مستخدم آخر',
            }),
            409,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return jsonResponse(
          jsonEncode({
            'id': 92,
            'type': 'إجازة سنوية',
            'state': 'قيد المراجعة',
            'decision': {'canDecide': true},
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerRequestDetailScreen(
          repository: ManagerRepository(client),
          path: '/manager/requests',
          item: const {'id': 92},
          canDecide: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('موافقة'));
    await tester.tap(find.text('موافقة'));
    // The underlying screen shows a busy indicator while confirmation is open.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'موافقة').last);
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('اتخذ القرار مستخدم آخر'), findsOneWidget);
    expect(find.textContaining('تمت الموافقة'), findsNothing);
  });
}
