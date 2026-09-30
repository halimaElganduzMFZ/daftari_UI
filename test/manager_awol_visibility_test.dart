import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:employee_affairs/core/network/api_client.dart';
import 'package:employee_affairs/data/models/auth_models.dart';
import 'package:employee_affairs/data/repositories/manager_repository.dart';
import 'package:employee_affairs/data/session/app_session.dart';
import 'package:employee_affairs/features/manager/remote_manager_requests_screen.dart';

void main() {
  for (final structureType in [1, 2, 3, 4, 5]) {
    testWidgets(
      'structure type $structureType alone never grants AWOL access',
      (tester) async {
        final json = <String, dynamic>{
          'id': 1,
          'employeeId': 10,
          'employeeNumber': '123',
          'isAssigner': true,
          'structures': [
            {'num': 40, 'type': structureType},
          ],
        };
        AppSession.currentUser = AuthUser.fromJson(json);
        addTearDown(AppSession.clear);
        final client = ApiClient(
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/awol/count')) {
              fail('Missing capability must not fetch AWOL count');
            }
            final Object body = request.url.path.endsWith('/request-types')
                ? []
                : request.url.path.endsWith('/counts')
                ? {'pending': 0, 'approved': 0, 'rejected': 0}
                : {
                    'data': [],
                    'meta': {'hasNext': false, 'total': 0},
                  };
            return http.Response(jsonEncode(body), 200);
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
        expect(find.text('المنقطعون (0)'), findsNothing);
        // Never override an explicit server denial, even for type 1.
        expect(
          AuthUser.fromJson({...json, 'canManageAwol': false}).canManageAwol,
          false,
        );
      },
    );
  }
  for (final capability in [true, false, null]) {
    testWidgets('AWOL entry follows explicit API capability $capability', (
      tester,
    ) async {
      AppSession.currentUser = AuthUser.fromJson({
        'id': 1, 'employeeId': 10, 'employeeNumber': '123', 'isAssigner': true,
        // Admin and on-behalf privileges must not independently expose AWOL.
        'isAdmin': true, 'canActOnBehalf': true, 'structures': [],
        'canManageAwol': ?capability,
      });
      addTearDown(AppSession.clear);
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/awol/count')) {
            expect(capability, true);
            return http.Response('{"count":0}', 200);
          }
          final Object body = request.url.path.endsWith('/request-types')
              ? []
              : request.url.path.endsWith('/counts')
              ? {'pending': 0, 'approved': 0, 'rejected': 0}
              : {
                  'data': [],
                  'meta': {'hasNext': false, 'total': 0},
                };
          return http.Response(jsonEncode(body), 200);
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
        find.text('المنقطعون (0)'),
        capability == true ? findsOneWidget : findsNothing,
      );
    });
  }
}
