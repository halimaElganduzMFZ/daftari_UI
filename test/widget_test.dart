import 'package:employee_affairs/core/constants/app_strings.dart';
import 'package:employee_affairs/features/splash/splash_screen.dart';
import 'package:employee_affairs/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app opens on splash then login', (tester) async {
    await tester.pumpWidget(const DaftariApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(AppStrings.login), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
