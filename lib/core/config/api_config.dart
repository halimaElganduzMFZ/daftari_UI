/// إعدادات عامة للتطبيق — غيّر القيم هنا فقط عند الانتقال للسيرفر.
abstract final class ApiConfig {
  /// عند `false`: الدخول التجريبي المحلي بدون API (للتصميم من المنزل).
  /// عند `true`: الدخول عبر Nest API.
  static const useRemoteApi = false;

  /// عنوان الـ API الأساسي.
  /// محلياً: http://127.0.0.1:3000/api/v1
  /// على السيرفر لاحقاً: مثلاً https://api.example.com/api/v1
  /// غيّر هذا المتغير فقط — لا تبحث في الشاشات.
  static const baseUrl = 'http://127.0.0.1:3000/api/v1';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
}
