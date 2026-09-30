import 'dart:async';
import 'dart:convert';

import 'package:employee_affairs/core/constants/app_strings.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/models/auth_models.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/data/session/app_session.dart';
import 'package:employee_affairs/features/manager/remote_manager_widgets.dart';
import 'package:employee_affairs/features/shell/manager_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('a quiet refresh reloads the shown pages in place', (
    tester,
  ) async {
    final refreshes = ValueNotifier(0);
    addTearDown(refreshes.dispose);
    final loaded = <int>[];
    var version = 1;
    var offline = false;
    Completer<void>? gate;
    Future<ManagerPage> load(int page) async {
      loaded.add(page);
      await gate?.future;
      if (offline) throw Exception('offline');
      return ManagerPage(
        [
          for (var i = 0; i < 5; i++) {'id': page * 10 + i, 'version': version},
        ],
        page < 3,
        15,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManagerPagedList(
            load: load,
            quietRefresh: refreshes,
            itemBuilder: (item) => SizedBox(
              height: 100,
              child: Text('${item['id']} v${item['version']}'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('عرض المزيد'), 200);
    await tester.tap(find.text('عرض المزيد'));
    await tester.pumpAndSettle();
    expect(loaded, [1, 2]);
    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    final offset = position.position.pixels;

    version = 2;
    final hold = Completer<void>();
    gate = hold;
    refreshes.value++;
    await tester.pump();
    expect(find.textContaining(' v1'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(loaded, [1, 2, 1, 2]);
    expect(find.textContaining(' v1'), findsNothing);
    expect(find.textContaining(' v2'), findsWidgets);
    expect(position.position.pixels, offset);

    offline = true;
    gate = null;
    refreshes.value++;
    await tester.pumpAndSettle();
    expect(loaded, [1, 2, 1, 2, 1]);
    expect(find.textContaining(' v2'), findsWidgets);
    expect(find.byType(ManagerError), findsNothing);
  });

  testWidgets('manager tabs keep their search and refresh quietly on return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var version = 1;
    var typesDown = true;
    var typeLookups = 0;
    Completer<void>? gate;
    final lists = <Uri>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/lookups/request-types')) {
          typeLookups++;
          if (typesDown) return http.Response('{}', 500);
          return _json([
            {'code': 'ANNUAL_LEAVE', 'label': 'إجازة سنوية'},
          ]);
        }
        if (path.endsWith('/counts')) {
          return _json({'pending': 1, 'approved': 0, 'rejected': 0});
        }
        lists.add(request.url);
        await gate?.future;
        final inbox = request.url.queryParameters['status'] == 'pending';
        return _json({
          'data': [
            {
              'id': inbox ? 7 : 8,
              'status': inbox ? 'pending' : 'approved',
              'type': 'إجازة سنوية',
              'fromDate': '2026-10-04',
              'toDate': '2026-10-08',
              'employee': {
                'name': inbox ? 'سالم $version' : 'ليلى',
                'number': 'FZ-10021',
              },
            },
          ],
          'meta': {'hasNext': false, 'total': 1},
        });
      }),
    );
    addTearDown(client.close);
    final search = find.widgetWithText(TextField, 'اسم الموظف أو رقمه الوظيفي');

    await tester.pumpWidget(
      MaterialApp(home: ManagerShell(repository: ManagerRepository(client))),
    );
    await tester.pumpAndSettle();
    expect(typeLookups, 1);
    expect(find.byType(ManagerError), findsOneWidget);
    await tester.enterText(search, '50651');
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    expect(lists.last.queryParameters['employeeNumber'], '50651');
    expect(typeLookups, 2);

    await tester.tap(find.text('السابق'));
    await tester.pumpAndSettle();
    expect(find.text('ليلى'), findsOneWidget);
    expect(typeLookups, 3);

    version = 2;
    typesDown = false;
    final hold = Completer<void>();
    gate = hold;
    final before = lists.length;
    await tester.tap(find.text('الموافقات'));
    await tester.pump();
    expect(find.text('سالم 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(lists, hasLength(before + 1));
    expect(lists.last.queryParameters['employeeNumber'], '50651');

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.text('سالم 2'), findsOneWidget);
    expect(tester.widget<TextField>(search).controller!.text, '50651');
    expect(typeLookups, 4);
    expect(find.byType(ManagerError), findsNothing);

    // History retries its own failed lookup; the inbox's is not repeated.
    await tester.tap(find.text('السابق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الموافقات'));
    await tester.pumpAndSettle();
    expect(typeLookups, 5);
  });

  testWidgets('the profile tab shows the session as it is on return', (
    tester,
  ) async {
    void signIn(String name) => AppSession.currentUser = AuthUser.fromJson({
      'id': 1,
      'employeeId': 10,
      'employeeNumber': '123',
      'fullName': name,
      'structures': [],
    });
    signIn('منى');
    addTearDown(AppSession.clear);
    final client = ApiClient(
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/lookups/request-types')) return _json([]);
        if (path.endsWith('/counts')) {
          return _json({'pending': 0, 'approved': 0, 'rejected': 0});
        }
        return _json({
          'data': [],
          'meta': {'hasNext': false, 'total': 0},
        });
      }),
    );
    addTearDown(client.close);
    Finder tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

    await tester.pumpWidget(
      MaterialApp(home: ManagerShell(repository: ManagerRepository(client))),
    );
    await tester.pumpAndSettle();
    await tester.tap(tab(AppStrings.profile));
    await tester.pumpAndSettle();
    expect(find.text('منى'), findsOneWidget);

    signIn('منى علي');
    await tester.tap(tab('الموافقات'));
    await tester.pumpAndSettle();
    await tester.tap(tab(AppStrings.profile));
    await tester.pumpAndSettle();
    expect(find.text('منى علي'), findsOneWidget);
    expect(find.text('منى'), findsNothing);
  });
}
