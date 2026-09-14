/// إعدادات الاتصال بالـ API (NestJS — mfz-daftari-api).
abstract final class ApiConfig {
  /// عنوان الخادم المحلي أثناء التطوير.
  /// المسارات مصدَّرة تحت `/api` مع إصدارة URI `v1`.
  static const baseUrl = 'http://127.0.0.1:3000/api/v1';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
}
