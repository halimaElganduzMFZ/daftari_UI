import 'package:employee_affairs/core/constants/app_strings.dart';
import 'package:employee_affairs/features/auth/login_screen.dart';
import 'package:employee_affairs/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    ),
  );
}

void main() {
  testWidgets('splash shows brand mark and titles while loading', (tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));

    await tester.pump(); // first frame + schedule nav timer
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('MFZ'), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.orgName), findsOneWidget);
    expect(find.textContaining('جاري التجهيز'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(SplashScreen), findsOneWidget);

    // Dispose repeating animations so the test ends cleanly.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('splash navigates to login after dwell', (tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppStrings.login), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
