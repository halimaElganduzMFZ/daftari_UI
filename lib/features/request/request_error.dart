import '../../core/network/api_exception.dart';

/// عنوان + نص مناسبان لعرض رفض تقديم طلب (إذن أو إجازة).
///
/// الرسائل العربية تأتي من الـ API نفسه (نصوص النظام القديم)، وهنا نضيف
/// عنواناً قصيراً حسب `code` ونعالج أخطاء الشبكة/الجلسة بشكل موحّد.
class RequestErrorInfo {
  const RequestErrorInfo({
    required this.title,
    required this.message,
    this.cause,
  });

  final String title;
  final String message;

  /// السبب التقني (للتشخيص فقط).
  final String? cause;
}

RequestErrorInfo describeRequestError(Object error) {
  if (error is! ApiException) {
    return const RequestErrorInfo(
      title: 'تعذر تقديم الطلب',
      message: 'حدث خطأ غير متوقع، حاول مرة أخرى.',
    );
  }

  if (error.isNetwork) {
    return RequestErrorInfo(
      title: 'لا يوجد اتصال',
      message: 'تعذر الوصول إلى الخادم. تأكد من الشبكة ثم أعد المحاولة.',
      cause: error.cause,
    );
  }
  if (error.isUnauthorized) {
    return const RequestErrorInfo(
      title: 'انتهت الجلسة',
      message: 'يرجى تسجيل الدخول مرة أخرى.',
    );
  }
  if (error.isTooManyRequests) {
    return const RequestErrorInfo(
      title: 'محاولات كثيرة',
      message: 'انتظر قليلاً ثم أعد المحاولة.',
    );
  }

  final title = switch (error.code) {
    'MONTH_LOCKED' => 'الشهر مقفل للمرتبات',
    'DUPLICATE_REQUEST' => 'طلب مكرر',
    'SUBMISSION_IN_PROGRESS' => 'طلب قيد المعالجة',
    'QUOTA_EXHAUSTED' => 'الرصيد الشهري منتهٍ',
    'NO_ATTENDANCE_RECORD' ||
    'NO_CHECK_IN' ||
    'NO_PUNCH_IN_WINDOW' ||
    'PUNCH_WINDOW_UNDEFINED' =>
      'التحقق من البصمة',
    'ATTENDANCE_UNAVAILABLE' => 'نظام البصمة غير متاح',
    'TYPE_NOT_ALLOWED' || 'NOT_REQUIRED' || 'EXEMPT_EMPLOYEE' => 'النوع غير متاح',
    'NO_APPROVER' => 'لا يوجد مسؤول اعتماد',
    'DATE_OUT_OF_RANGE' ||
    'INVALID_DATE_RANGE' ||
    'DATE_RANGE_TOO_LONG' ||
    'START_ON_DAY_OFF' ||
    'START_ON_FRIDAY' =>
      'راجع التواريخ',
    'LEAVE_OVERLAP' ||
    'REQUEST_OVERLAP' ||
    'SAME_KIND_PENDING' ||
    'DUPLICATE_EXEMPTION' =>
      'تداخل مع طلب أو إجازة',
    'INSUFFICIENT_BALANCE' => 'الرصيد غير كافٍ',
    'EXCEPTION_NOT_ALLOWED' || 'EXCEPTION_NOT_APPLICABLE' => 'إجازة الاستثناء',
    'REASON_REQUIRED' => 'السبب مطلوب',
    'ATTACHMENT_REQUIRED' ||
    'ATTACHMENT_NOT_ALLOWED' ||
    'ATTACHMENT_INVALID' ||
    'ATTACHMENT_TOO_LARGE' ||
    'ATTACHMENT_STORE_FAILED' =>
      'المرفق',
    'NOT_ELIGIBLE' ||
    'FEMALE_ONLY' ||
    'ALREADY_GRANTED' ||
    'EMPLOYEE_NOT_FOUND' ||
    'EMPLOYEE_INACTIVE' ||
    'CONTRACT_NOT_ELIGIBLE' ||
    'MISSING_START_DATE' =>
      'غير مؤهل لهذا النوع',
    'SHIFT_UNKNOWN' || 'NO_WORK_SHIFTS_IN_RANGE' => 'نوع الدوام',
    _ => error.isServerError ? 'خطأ في الخادم' : 'تعذر تقديم الطلب',
  };

  final message = error.isServerError && error.code == null
      ? 'حدث خطأ في الخادم، حاول مرة أخرى لاحقاً.'
      : error.message;

  return RequestErrorInfo(title: title, message: message);
}
