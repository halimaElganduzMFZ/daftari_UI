import 'dart:convert';

import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/data/repositories/timesheet_repository.dart';
import 'package:employee_affairs/features/manager/manager_statistics_screen.dart';
import 'package:employee_affairs/features/timesheet/timesheet_screen.dart';
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

const _screenHeight = 780.0;
const _navigationBar = 48.0;

/// A 360 × 780 phone with 3-button navigation. Since Android 15 the app draws
/// under that bar, so the framework reports it as bottom padding.
void _phoneWithNavigationBar(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
  tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 144);
  addTearDown(tester.view.reset);
}

double _pageBottom(WidgetTester tester) =>
    tester.getRect(find.byType(Scrollable).first).bottom;

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('a plain pushed Scaffold still runs under the bar', (
    tester,
  ) async {
    _phoneWithNavigationBar(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: ListView(children: const [Text('end')]),
        ),
      ),
    );
    expect(_pageBottom(tester), _screenHeight);
  });

  testWidgets('the timesheet ends above the navigation bar', (tester) async {
    _phoneWithNavigationBar(tester);
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => _json({
          'status': 'ok',
          'range': {
            'from': '2026-09-01',
            'to': '2026-09-24',
            'minDate': '2026-08-01',
          },
          'summary': {
            'absenceDays': 0,
            'gateAbsenceDays': 0,
            'totalAbsenceDays': 0,
          },
          'days': [
            {'id': 1, 'date': '2026-09-02'},
          ],
        }),
      ),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: TimesheetScreen(repository: ApiTimesheetRepository(client)),
      ),
    );
    await tester.pumpAndSettle();
    expect(_pageBottom(tester), _screenHeight - _navigationBar);
  });

  testWidgets('a manager list page ends above the navigation bar', (
    tester,
  ) async {
    _phoneWithNavigationBar(tester);
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => _json({
          'data': [],
          'meta': {'total': 0, 'hasNext': false},
        }),
      ),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerMonthlyApprovalsScreen(
          repository: ManagerRepository(client),
          month: '2026-09',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_pageBottom(tester), _screenHeight - _navigationBar);
  });
}
