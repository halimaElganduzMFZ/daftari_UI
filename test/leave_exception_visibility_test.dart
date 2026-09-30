import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/repositories/leave_requests_repository.dart';
import 'package:employee_affairs/features/leave/make_leave_screen.dart';

void main() {
  for (final shift in ['OPEN', 'SHIFT_17', 'SHIFT_24']) {
    for (final available in [true, false]) {
      testWidgets('$shift exception visibility follows API $available', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1000, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = ApiClient(
          httpClient: MockClient((request) async {
            expect(
              request.url.path,
              endsWith(
                '/manager/on-behalf/employees/4321/leave/requests/options',
              ),
            );
            return http.Response(
              jsonEncode({
                'shift': {'status': 'ok', 'shift': shift},
                'exceptionAvailable': available,
              }),
              200,
            );
          }),
        );
        addTearDown(client.close);
        await tester.pumpWidget(
          MaterialApp(
            home: MakeLeaveScreen(
              repository: ApiLeaveRequestsRepository(
                client,
                basePath: '/manager/on-behalf/employees/4321/leave/requests',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('طلب إجازة استثناء'),
          available ? findsOneWidget : findsNothing,
        );
      });
    }
  }
}
