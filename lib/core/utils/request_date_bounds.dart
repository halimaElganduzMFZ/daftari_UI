/// حدود تواريخ تقديم الطلبات (إذن / إجازة): شهر قبل وشهر بعد اليوم.
abstract final class RequestDateBounds {
  /// شهر قبل التاريخ المرجعي (افتراضياً اليوم).
  static DateTime monthBefore([DateTime? from]) {
    final d = from ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    return DateTime(day.year, day.month - 1, day.day);
  }

  /// شهر بعد التاريخ المرجعي (افتراضياً اليوم).
  static DateTime monthAfter([DateTime? from]) {
    final d = from ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    return DateTime(day.year, day.month + 1, day.day);
  }

  /// يضبط التاريخ داخل النافذة إن خرج عنها.
  static DateTime clampToWindow(DateTime value, {DateTime? now}) {
    final min = monthBefore(now);
    final max = monthAfter(now);
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }
}
