import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/features/manager/remote_manager_attendance_screen.dart';
import 'package:employee_affairs/features/manager/remote_manager_requests_screen.dart';

http.Response jsonResponse(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets(
    'manager timesheet reads the chosen employee and shows four punches',
    (tester) async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            endsWith('/manager/attendance/employees/4321'),
          );
          expect(request.url.queryParameters.keys, containsAll(['from', 'to']));
          return jsonResponse({
            'status': 'ok',
            'summary': {'days': 1, 'present': 1},
            'days': [
              {
                'date': '2026-09-23',
                'weekdayName': 'الأربعاء',
                'dayTypeName': 'دوام العمل',
                'punches': {
                  'checkIn': {'time': '08:01'},
                  'breakOut': {'time': '11:02'},
                  'resume': {'time': '12:03'},
                  'checkOut': {'time': '14:04'},
                },
                'verdict': {'status': 'present', 'text': 'حاضر'},
                'note': null,
              },
            ],
          });
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerEmployeeAttendanceScreen(
            repository: ManagerRepository(client),
            employee: const {
              'id': 4321,
              'name': 'موظف الاختبار',
              'number': '50651',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final time in ['08:01', '11:02', '12:03', '14:04']) {
        expect(find.text(time), findsOneWidget);
      }
      expect(find.text('حاضر'), findsOneWidget);
    },
  );

  testWidgets(
    'unavailable attendance is not shown as an empty successful sheet',
    (tester) async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => jsonResponse({'status': 'unavailable', 'days': []}),
        ),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerEmployeeAttendanceScreen(
            repository: ManagerRepository(client),
            employee: const {'id': 4321, 'name': 'موظف'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('خدمة البصمات غير متاحة حاليًا. حاول لاحقًا.'),
        findsOneWidget,
      );
      expect(find.text('لا توجد سجلات حضور في هذه الفترة.'), findsNothing);
    },
  );

  testWidgets(
    'history filter submits the live holiday value instead of a guessed code',
    (tester) async {
      final filters = <String?>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/lookups/request-types')) {
            return jsonResponse([
              {
                'code': 'ANNUAL_LEAVE',
                'filterValue': 'اسم الإجازة من الجدول',
                'label': 'اسم الإجازة من الجدول',
                'group': 'الإجازات',
              },
            ]);
          }
          if (request.url.path.endsWith('/counts')) {
            return jsonResponse({'pending': 0, 'approved': 0, 'rejected': 0});
          }
          filters.add(request.url.queryParameters['type']);
          return jsonResponse({
            'data': [],
            'meta': {'hasNext': false, 'total': 0},
          });
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteManagerRequestsScreen(
              history: true,
              repository: ManagerRepository(client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اسم الإجازة من الجدول').last);
      await tester.pumpAndSettle();
      expect(filters.last, 'اسم الإجازة من الجدول');
    },
  );
}
