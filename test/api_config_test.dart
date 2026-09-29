import 'package:employee_affairs/core/config/api_config.dart';
import 'package:employee_affairs/features/splash/insecure_build_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool insecure(String baseUrl, {bool release = true, bool remote = true}) =>
      ApiConfig.isInsecureReleaseConfig(
        releaseMode: release,
        remoteApi: remote,
        baseUrl: baseUrl,
      );

  test('release builds accept only https server addresses', () {
    expect(insecure('https://api.example.org/api/v1'), isFalse);
    expect(insecure('http://10.10.17.70:3000/api/v1'), isTrue);
    expect(insecure(''), isTrue);
    expect(insecure('https://'), isTrue);
    expect(insecure('api.example.org/api/v1'), isTrue);
  });

  test('debug builds and the offline demo mode are not restricted', () {
    expect(insecure('http://10.10.17.70:3000/api/v1', release: false), isFalse);
    expect(insecure('', remote: false), isFalse);
  });

  test('test runs use a development build, so the app starts normally', () {
    expect(ApiConfig.hasInsecureReleaseConfig, isFalse);
  });

  testWidgets('insecure build screen explains why the app stopped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InsecureBuildScreen(),
        ),
      ),
    );

    expect(find.text('لا يمكن تشغيل هذه النسخة'), findsOneWidget);
    expect(find.textContaining('HTTPS'), findsOneWidget);
  });
}
