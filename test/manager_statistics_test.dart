import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/models/auth_models.dart';
import 'package:employee_affairs/data/models/timesheet.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/data/repositories/timesheet_repository.dart';
import 'package:employee_affairs/data/session/app_session.dart';
import 'package:employee_affairs/features/manager/manager_statistics_screen.dart';
import 'package:employee_affairs/features/manager/remote_manager_requests_screen.dart';
import 'package:employee_affairs/features/timesheet/timesheet_screen.dart';

http.Response reply(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);
const totals = {
  'actualAbsenceDays': 2,
  'gateAbsenceDays': 1,
  'totalAbsenceDays': 3,
};
void main() {
  setUpAll(() => initializeDateFormatting('ar'));
  testWidgets(
    'detailed panel keeps zero types and opens exact server filter on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? filter;
      final client = ApiClient(
        httpClient: MockClient((req) async {
          if (req.url.path.endsWith('/me/dashboard')) {
            return reply({
              'manager': {
                'monthlyApprovals': {
                  'total': 4,
                  'month': '2026-09',
                  'types': [
                    {'type': 'إجازة سنوية', 'count': 4},
                  ],
                },
                'absences': {'status': 'ok', 'summary': totals},
              },
            });
          }
          filter = req.url.queryParameters['type'];
          return reply({
            'data': [],
            'meta': {'total': 0, 'hasNext': false},
          });
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManagerStatisticsPanel(
                repository: ManagerRepository(client),
                requestTypes: const [
                  {'label': 'إجازة سنوية', 'category': 'leave'},
                  {'label': 'طارئة', 'category': 'leave'},
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('طارئة'), findsOneWidget);
      expect(find.text('100٪ من الإجمالي · التفاصيل'), findsOneWidget);
      expect(find.text('0٪ من الإجمالي · التفاصيل'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('إجازة سنوية'));
      await tester.tap(find.text('إجازة سنوية'));
      await tester.pumpAndSettle();
      expect(filter, 'إجازة سنوية');
    },
  );
  for (final assigner in [true, false]) {
    testWidgets(
    'monthly entry opens detail page for isAssigner=$assigner even with zero and no AWOL',
      (tester) async {
        AppSession.currentUser = AuthUser.fromJson({
          'id': 1,
          'employeeId': 7,
          'employeeNumber': '99',
          'isAssigner': assigner,
          'canManageAwol': false,
          'structures': [
            {'num': 5, 'type': 5},
          ],
        });
        addTearDown(AppSession.clear);
        var dashboardCalls = 0;
        final client = ApiClient(
          httpClient: MockClient((req) async {
            if (req.url.path.endsWith('/me/dashboard')) {
              dashboardCalls++;
              return reply({
                'manager': {
                  'monthlyApprovals': {
                    'total': 0,
                    'month': '2026-09',
                    'types': [],
                  },
                  'absences': {'status': 'ok', 'summary': totals},
                },
              });
            }
            if (req.url.path.endsWith('/request-types')) return reply([]);
            if (req.url.path.endsWith('/counts')) {
              return reply({'pending': 0, 'approved': 0, 'rejected': 0});
            }
            return reply({
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
                repository: ManagerRepository(client),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('حركة الموافقات الشهرية'),
          assigner ? findsOneWidget : findsNothing,
        );
        expect(dashboardCalls, 0);
        if (assigner) {
          await tester.tap(find.text('حركة الموافقات الشهرية'));
          await tester.pumpAndSettle();
          expect(dashboardCalls, greaterThan(0));
          expect(find.text('الموافقات الشهرية (0)'), findsOneWidget);
          expect(find.byTooltip('رجوع للرئيسية'), findsOneWidget);
        }
      },
    );
  }
  testWidgets(
    'monthly events paginate without collapsing requestId rows and open request detail',
    (tester) async {
      final paths = <String>[];
      final client = ApiClient(
        httpClient: MockClient((req) async {
          paths.add(req.url.path);
          if (req.url.path.endsWith('/requests/12')) {
            return reply({'id': 12, 'type': 'إجازة', 'state': 'معتمد'});
          }
          expect(req.url.queryParameters['month'], '2026-09');
          final page = req.url.queryParameters['page'];
          return reply({
            'data': [
              for (final id in page == '1' ? [11, 12] : [13])
                {
                  'requestId': id,
                  'employeeName': 'موظف $id',
                  'type': 'إجازة',
                  'approvalLevel': 1,
                  'approvedAt': '2026-09-24',
                  'isFinal': false,
                },
            ],
            'meta': {'total': 3, 'hasNext': page == '1'},
          });
        }),
      );
      addTearDown(client.close);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerMonthlyApprovalsScreen(
            repository: ManagerRepository(client),
            month: '2026-09',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('موظف 11'), findsOneWidget);
      expect(find.text('موظف 12'), findsOneWidget);
      await tester.tap(find.text('عرض المزيد'));
      await tester.pumpAndSettle();
      expect(find.text('موظف 13'), findsOneWidget);
      await tester.tap(find.text('تفاصيل الطلب').at(1));
      await tester.pumpAndSettle();
      expect(paths.last, endsWith('/manager/requests/12'));
      expect(find.text('اعتماد'), findsNothing);
    },
  );
  testWidgets(
    'absence details use card id and preserve range with separate facts',
    (tester) async {
      final client = ApiClient(
        httpClient: MockClient((req) async {
          expect(req.url.queryParameters['from'], '2026-09-01');
          expect(req.url.queryParameters['to'], '2026-09-24');
          if (req.url.path.endsWith('/employees/4321')) {
            return reply({
              'status': 'ok',
              'summary': totals,
              'days': [
                {
                  'date': '2026-09-02',
                  'actual': true,
                  'gate': false,
                  'counted': true,
                },
                {
                  'date': '2026-09-03',
                  'actual': false,
                  'gate': true,
                  'counted': true,
                },
              ],
            });
          }
          return reply({
            'status': 'ok',
            'summary': totals,
            'data': [
              {'id': 4321, 'number': '9000', 'name': 'أحمد', ...totals},
            ],
            'meta': {'total': 1, 'hasNext': false},
          });
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerAbsencesScreen(
            repository: ManagerRepository(client),
            from: DateTime(2026, 9, 1),
            to: DateTime(2026, 9, 24),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تفاصيل أيام الغياب'));
      await tester.tap(find.text('تفاصيل أيام الغياب'));
      await tester.pumpAndSettle();
      expect(find.text('غياب فعلي'), findsOneWidget);
      expect(find.text('غياب بسبب مخالفة البوابة'), findsOneWidget);
    },
  );
  testWidgets('archive unavailable is not an empty absence list', (
    tester,
  ) async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => reply({
          'status': 'unavailable',
          'summary': null,
          'data': [],
          'meta': {'total': 0, 'hasNext': false},
        }),
      ),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ManagerAbsencesScreen(repository: ManagerRepository(client)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذر جلب أرشيف الغياب'), findsOneWidget);
    expect(find.text('لا توجد نتائج'), findsNothing);
  });
  testWidgets(
    'employee timesheet uses authoritative absence totals and daily flags',
    (tester) async {
      final client = ApiClient(
        httpClient: MockClient((req) async {
          expect(req.url.path, endsWith('/me/timesheet'));
          return reply({
            'status': 'ok',
            'range': {
              'from': '2026-09-01',
              'to': '2026-09-24',
              'minDate': '2026-08-01',
            },
            'summary': {
              'absenceDays': 7,
              'gateAbsenceDays': 4,
              'totalAbsenceDays': 11,
            },
            'days': [
              {
                'id': 1,
                'date': '2026-09-02',
                'absence': {'actual': false, 'gate': true, 'counted': true},
              },
            ],
          });
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: TimesheetScreen(repository: ApiTimesheetRepository(client)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      final day = TimesheetDay.fromApi({
        'absence': {'actual': false, 'gate': true, 'counted': true},
      });
      expect(day.gateAbsence, true);
      expect(day.actualAbsence, false);
    },
  );
}
