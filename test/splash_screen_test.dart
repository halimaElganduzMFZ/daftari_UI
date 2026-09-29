import 'dart:async';

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
    expect(find.byType(SplashScreen), findsOneWidget);

    // Dispose repeating animations so the test ends cleanly.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('splash navigates to login after dwell', (tester) async {
    await tester.pumpWidget(
      _wrap(SplashScreen(restoreSession: () async => false)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 100)); // 800 ms minimum
    await tester.pump(const Duration(milliseconds: 600)); // page transition

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppStrings.login), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('splash waits for a slow session restore', (tester) async {
    final restore = Completer<bool>();
    await tester.pumpWidget(
      _wrap(SplashScreen(restoreSession: () => restore.future)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    LinearProgressIndicator bar() =>
        tester.widget(find.byType(LinearProgressIndicator));
    expect(bar().value, isNotNull);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(bar().value, isNull);

    restore.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('splash falls back to login when storage does not answer',
      (tester) async {
    // The storage plugins aren't mocked and get no reply in widget tests, so
    // the splash gives up at its 2 s storage timeout.
    await tester.pumpWidget(_wrap(const SplashScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
