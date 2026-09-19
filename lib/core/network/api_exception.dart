/// أخطاء موحّدة لاستدعاءات الـ API.
///
/// تطابق غلاف الخطأ في Nest (`AllExceptionsFilter`):
/// `{ statusCode, error, message, code?, details?, path, timestamp, requestId }`.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;

  /// رمز ثابت لرفض قاعدة عمل (مثل `QUOTA_EXHAUSTED`, `MONTH_LOCKED`).
  final String? code;

  /// تفاصيل إضافية مرافقة للرمز (مثل `{ limit, used, month }`).
  final Map<String, dynamic>? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isTooManyRequests => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isNetwork => statusCode == null;

  @override
  String toString() =>
      'ApiException($statusCode${code == null ? '' : ' $code'}): $message';
}
