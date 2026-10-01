import 'package:flutter/foundation.dart';

/// إعدادات عامة للتطبيق — غيّر القيم هنا فقط عند الانتقال للسيرفر.
///
/// يمكن تجاوز القيم وقت التشغيل دون تعديل الكود:
/// ```
/// dart run tool/web_api_proxy.dart
/// flutter run -d web-server --web-hostname 0.0.0.0 --web-port=43123
///   --dart-define=USE_REMOTE_API=false          # وضع التصميم (بيانات ثابتة)
///   --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1   # API على جهازك
/// ```
/// على الويب بلا `API_BASE_URL` تُرسل الطلبات إلى نفس عنوان الصفحة على
/// المنفذ [webProxyPort]، حتى يفتح التطبيق من أي جهاز عبر IP هذا الحاسوب.
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

  /// خادم المكتب. الجوال وسطح المكتب يتصلان به مباشرة.
  static const officeApiBaseUrl = 'http://10.10.10.97:3000/api/v1';

  /// منفذ وسيط الويب على هذا الجهاز (`tool/web_api_proxy.dart`).
  /// المتصفح يستدعي `http://<عنوان-الصفحة>:<هذا-المنفذ>/api/v1`.
  static const webProxyPort = int.fromEnvironment(
    'WEB_API_PROXY_PORT',
    defaultValue: 43124,
  );

  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// عنوان الـ API الأساسي.
  ///
  /// * الويب في التطوير: نفس مضيف الصفحة + [webProxyPort]، فيعمل الرابط
  ///   `http://<IP الجهاز>:43123` من أي جهاز على الشبكة دون حظر CORS.
  /// * الجوال وسطح المكتب: [officeApiBaseUrl].
  /// * `--dart-define=API_BASE_URL=...` يتجاوز الاثنين.
  /// * نسخة الإصدار بلا عنوان: شاشة خطأ ولا يُرسل أي طلب
  ///   ([hasInsecureReleaseConfig]).
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kReleaseMode) return '';
    if (kIsWeb) {
      return lanWebApiBase(host: Uri.base.host, port: webProxyPort);
    }
    return officeApiBaseUrl;
  }

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

  /// عنوان الـ API الذي يستدعيه متصفح الويب عبر وسيط هذا الجهاز.
  @visibleForTesting
  static String lanWebApiBase({required String host, required int port}) {
    final safeHost = host.isEmpty ? '127.0.0.1' : host;
    return 'http://$safeHost:$port/api/v1';
  }

  /// عنوان مختصر للعرض في شاشة الدخول (بدون البروتوكول والمسار).
  static String get displayHost {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return baseUrl;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }
}
