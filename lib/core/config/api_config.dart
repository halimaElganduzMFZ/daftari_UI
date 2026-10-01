import 'package:flutter/foundation.dart';

/// إعدادات عامة للتطبيق — غيّر القيم هنا فقط عند الانتقال للسيرفر.
///
/// يمكن تجاوز القيم وقت التشغيل دون تعديل الكود:
/// ```
/// flutter run -d chrome --web-port=43123 \
///   --dart-define=USE_REMOTE_API=false          # وضع التصميم (بيانات ثابتة)
///   --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1   # API على جهازك
/// ```
///
/// نسخة الإصدار لا تتصل إلا عبر HTTPS، ويُمرَّر عنوان الخادم وقت البناء:
/// ```
/// flutter build appbundle --dart-define=API_BASE_URL=https://<الخادم>/api/v1
/// ```
abstract final class ApiConfig {
  /// عند `false`: الدخول التجريبي المحلي بدون API (للتصميم من المنزل).
  /// عند `true`: الدخول والبيانات عبر Nest API (`mfz-daftari-api`).
  static const useRemoteApi = bool.fromEnvironment(
    'USE_REMOTE_API',
    defaultValue: true,
  );

  /// عنوان الـ API الأساسي.
  /// نسخ التطوير (debug / profile) تتصل افتراضياً بخادم التجربة على شبكة المكتب
  /// http://10.10.10.97:3000/api/v1
  /// (لا تستخدم 127.0.0.1 على الجوال — يشير إلى الهاتف نفسه لا إلى الحاسوب).
  /// نسخة الإصدار بلا عنوان افتراضي: بدون `API_BASE_URL` بصيغة https تعرض
  /// شاشة خطأ ولا ترسل أي طلب ([hasInsecureReleaseConfig]).
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode ? '' : 'http://10.10.10.97:3000/api/v1',
  );

  /// `true` في نسخة إصدار تتصل بالخادم بعنوان غير https.
  static bool get hasInsecureReleaseConfig => isInsecureReleaseConfig(
        releaseMode: kReleaseMode,
        remoteApi: useRemoteApi,
        baseUrl: baseUrl,
      );

  @visibleForTesting
  static bool isInsecureReleaseConfig({
    required bool releaseMode,
    required bool remoteApi,
    required String baseUrl,
  }) {
    if (!releaseMode || !remoteApi) return false;
    final uri = Uri.tryParse(baseUrl);
    return uri == null || !uri.isScheme('https') || uri.host.isEmpty;
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);

  /// عنوان مختصر للعرض في شاشة الدخول (بدون البروتوكول والمسار).
  static String get displayHost {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return baseUrl;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }
}
