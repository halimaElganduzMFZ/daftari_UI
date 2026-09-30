import 'dart:convert';

import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/dashboard_repository.dart';
import 'package:employee_affairs/features/home/home_screen.dart';
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

Map<String, Object?> _dashboard({
  required int unread,
  required List<String> announcements,
}) => {
  'employee': {'fullName': 'أحمد'},
  'leave': {
    'emergency': {'remaining': 5, 'pendingRequests': 0},
    'annual': {'balance': 10, 'pendingRequests': 0},
  },
  'permissions': {
    'monthlyBalance': {'used': 1, 'remaining': 2},
    'monthlyCounts': [],
  },
  'requests': {
    'pending': [],
    'rejected': [],
    'counts': {'pending': 0, 'approved': 0, 'rejected': 0},
  },
  'notifications': {
    'portal': 'employee',
    'unread': unread,
    'employee': unread,
    'manager': 0,
  },
  'announcements': {
    'items': [
      for (final (i, title) in announcements.indexed)
        {'id': i + 1, 'title': title, 'body': 'نص'},
    ],
  },
};

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('home gets announcements and the unread count from the dashboard', (
    tester,
  ) async {
    final paths = <String>[];
    final replies = [
      _dashboard(unread: 3, announcements: ['إعلان الإدارة']),
      _dashboard(unread: 7, announcements: []),
    ];
    Finder badge(String count) =>
        find.descendant(of: find.byType(Badge), matching: find.text(count));
    final client = ApiClient(
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        return _json(replies[paths.length - 1]);
      }),
    );
    addTearDown(client.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(repository: ApiDashboardRepository(client)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(paths, [endsWith('/me/dashboard')]);
    expect(find.text('إعلان الإدارة'), findsOneWidget);
    expect(badge('3'), findsOneWidget);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(paths, [endsWith('/me/dashboard'), endsWith('/me/dashboard')]);
    expect(find.text('إعلان الإدارة'), findsNothing);
    expect(badge('7'), findsOneWidget);
  });
}
