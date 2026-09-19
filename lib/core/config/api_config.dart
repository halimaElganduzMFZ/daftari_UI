/// إعدادات عامة للتطبيق — غيّر القيم هنا فقط عند الانتقال للسيرفر.
///
/// يمكن تجاوز القيم وقت التشغيل دون تعديل الكود:
/// ```
/// flutter run -d chrome --web-port=43123 \
///   --dart-define=USE_REMOTE_API=false          # وضع التصميم (بيانات ثابتة)
///   --dart-define=API_BASE_URL=http://10.10.8.3:3000/api/v1
/// ```
abstract final class ApiConfig {
  /// عند `false`: الدخول التجريبي المحلي بدون API (للتصميم من المنزل).
  /// عند `true`: الدخول والبيانات عبر Nest API (`mfz-daftari-api`).
  static const useRemoteApi = bool.fromEnvironment(
    'USE_REMOTE_API',
    defaultValue: true,
  );

  /// عنوان الـ API الأساسي.
  /// محلياً: http://127.0.0.1:3000/api/v1
  /// على السيرفر لاحقاً: مثلاً https://api.example.com/api/v1
  /// غيّر هذا المتغير فقط — لا تبحث في الشاشات.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/v1',
  );

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);

  /// عنوان مختصر للعرض في شاشة الدخول (بدون البروتوكول والمسار).
  static String get displayHost {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return baseUrl;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }
}
