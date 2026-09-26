import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/features/manager/remote_manager_awol_screen.dart';

http.Response response(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('confirmation keeps active HR cases in the list and count', (
    tester,
  ) async {
    var confirmed = false;
    var countCalls = 0;
    var listCalls = 0;
    var detailCalls = 0;
    Map<String, dynamic> record() => {
      'id': 7,
      'employee': {'name': 'موظف منقطع', 'number': '50651'},
      'workplace': {},
      'firstAbsentDate': '2026-09-01',
      'hrStatus': 1,
      'confirmed': confirmed,
      'managerStatus': confirmed ? 3 : 1,
    };
    final client = ApiClient(
      getAccessToken: () async => 'manager-token',
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer manager-token');
        final path = request.url.path;
        if (path.endsWith('/count')) {
          countCalls++;
          return response({'count': 1});
        }
        if (path.endsWith('/confirm')) {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {'notes': 'ملاحظة المسؤول'});
          confirmed = true;
          // Do not depend on an undocumented record inside the confirmation response.
          return response({'message': 'تم التأكيد'});
        }
        if (path.endsWith('/7')) {
          detailCalls++;
          return response(record());
        }
        listCalls++;
        expect(request.url.queryParameters, {
          'page': '1',
          'limit': '20',
          'withTotal': 'true',
        });
        return response({
          'data': [record()],
          'meta': {'hasNext': false, 'total': 1},
        });
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteManagerAwolScreen(repository: ManagerRepository(client)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('موظف منقطع'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تأكيد وإرسال'));
    await tester.tap(find.text('تأكيد وإرسال'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'ملاحظة المسؤول');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'تأكيد'));
    await tester.pumpAndSettle();
    expect(detailCalls, 2);
    expect(find.text('تأكيد وإرسال'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('موظف منقطع'), findsOneWidget);
    expect(find.text('حالات الانقطاع الفعّالة: 1'), findsOneWidget);
    expect(find.text('انقطاع فعّال — تم تأكيد المسؤول'), findsOneWidget);
    expect(listCalls, 2);
    expect(countCalls, 2);
  });

  testWidgets('excluded detail response exposes no confirmation action', (
    tester,
  ) async {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/count')) return response({'count': 1});
        if (request.url.path.endsWith('/7')) {
          return response({'message': 'السجل غير متاح'}, 404);
        }
        return response({
          'data': [
            {
              'id': 7,
              'employee': {'name': 'سجل سابق'},
            },
          ],
          'meta': {'hasNext': false, 'total': 1},
        });
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteManagerAwolScreen(repository: ManagerRepository(client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('سجل سابق'));
    await tester.pumpAndSettle();
    expect(find.text('السجل غير متاح'), findsOneWidget);
    expect(find.text('تأكيد وإرسال'), findsNothing);
  });
}
