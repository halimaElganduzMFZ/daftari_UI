import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/models/leave_request_form.dart';
import 'package:employee_affairs/data/repositories/leave_requests_repository.dart';
import 'package:employee_affairs/features/leave/make_leave_screen.dart';

Map<String, dynamic> optionsBody({
  required bool available,
  String? unavailableReason,
}) => {
  'date': '2026-09-28',
  'today': '2026-09-28',
  'dateRange': {'min': '2026-08-28', 'max': '2026-10-28'},
  'employee': {
    'eligible': true,
    'female': false,
    'fridaysOff': true,
    'topLevelAssigner': false,
  },
  'shift': {'status': 'ok', 'shift': 'REGULAR'},
  'monthLocked': false,
  'balances': {
    'asOf': '2026-09-28',
    'emergencyAllowance': 12,
    'emergencyUsed': 0,
    'emergencyRemaining': 12,
    'emergencyPending': 0,
    'annualBalance': 18,
    'annualExact': 18,
    'annualPending': 0,
  },
  'kinds': [
    {
      'code': 'ANNUAL_LEAVE',
      'label': 'إجازة سنوية',
      'holidayType': 1,
      'category': 'balance',
      'fields': {
        'reason': 'optional',
        'location': 'optional',
        'attachment': 'hidden',
        'endDate': 'editable',
      },
      'available': true,
      'pendingRequests': 0,
    },
  ],
  'gateExemption': {
    'available': available,
    'requiresApproval': false,
    'code': 'GATE_EXEMPTION',
    'label': 'إعفاء حركة البوابة',
    if (unavailableReason != null) 'unavailableReason': unavailableReason,
    'limits': {'maxDays': 366, 'notesMaxLength': 250},
  },
};

void main() {
  test('gateExemption merges into kinds for department managers', () {
    final options = LeaveRequestOptions.fromApi(
      optionsBody(available: true),
    );
    expect(options.gateExemption?.available, isTrue);
    expect(options.gateExemption?.requiresApproval, isFalse);
    expect(
      options.kinds.any((k) => k.code == 'GATE_EXEMPTION' && k.available),
      isTrue,
    );
  });

  test('gateExemption hidden for NOT_DEPARTMENT_MANAGER', () {
    final options = LeaveRequestOptions.fromApi(
      optionsBody(
        available: false,
        unavailableReason: 'NOT_DEPARTMENT_MANAGER',
      ),
    );
    expect(options.gateExemption?.offeredInPicker, isFalse);
    expect(options.kinds.any((k) => k.code == 'GATE_EXEMPTION'), isFalse);
  });

  testWidgets('leave picker shows gate exemption when API offers it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.path, endsWith('/me/leave/requests/options'));
        return http.Response(
          jsonEncode(optionsBody(available: true)),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: MakeLeaveScreen(
          repository: ApiLeaveRequestsRepository(client),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('اختر نوع الإجازة'));
    await tester.pumpAndSettle();
    expect(find.text('إعفاء حركة البوابة'), findsOneWidget);
  });

  test('submit sends notes for GATE_EXEMPTION', () async {
    Map<String, dynamic>? body;
    final client = ApiClient(
      getAccessToken: () async => 'token',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/me/leave/requests'));
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'state': 'تم',
            'submittedAt': '2026-09-28 10:00:00',
            'requests': [],
            'plan': {
              'kind': {
                'code': 'GATE_EXEMPTION',
                'label': 'إعفاء حركة البوابة',
                'holidayType': 0,
                'category': 'exemption',
              },
              'from': '2026-09-28',
              'to': '2026-09-28',
              'requestedTo': '2026-09-28',
              'days': 0,
              'blocks': [],
              'method': 'NONE',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);
    await ApiLeaveRequestsRepository(client).submit(
      kind: 'GATE_EXEMPTION',
      from: DateTime(2026, 9, 28),
      reason: 'ملاحظة المدير',
    );
    expect(body?['kind'], 'GATE_EXEMPTION');
    expect(body?['notes'], 'ملاحظة المدير');
    expect(body?.containsKey('reason'), isFalse);
  });
}
