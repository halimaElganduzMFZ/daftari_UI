import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_strings.dart';
import 'core/di/app_services.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';

/// مفتاح الملاحة العام — للعودة إلى شاشة الدخول عند انتهاء الجلسة من أي مكان.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // عند فشل تجديد التوكن نهائياً (انتهت الجلسة أو أُلغيت من الخادم).
  AppServices.onSessionExpired = () {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('انتهت الجلسة، يرجى تسجيل الدخول مجدداً')),
      );
    }
  };

  runApp(const DaftariApp());
}

class DaftariApp extends StatelessWidget {
  const DaftariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
