/// نماذج تقديم طلب إذن (بديل `makeRequest.php`).
///
/// تطابق `RequestOptionsDto` و`PermissionRequestResultDto` في وحدة `requests`.
library;

int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
double? _num(Object? v) =>
    v is num ? v.toDouble() : (v == null ? null : double.tryParse('$v'));
String? _str(Object? v) => v == null ? null : '$v';

/// نوع إذن كما يعرّفه الـ API (`PermissionTypeDto`): رقم `TypeH` + رمز + اسم.
class ApiPermissionType {
  const ApiPermissionType({
    required this.type,
    required this.code,
    required this.name,
  });

  factory ApiPermissionType.fromApi(Map<String, dynamic> json) {
    return ApiPermissionType(
      type: _int(json['type']) ?? 0,
      code: _str(json['code']) ?? '',
      name: _str(json['name']) ?? '',
    );
  }

  final int type;
  final String code;
  final String name;
}

/// نوع مطلوب سابقاً في نفس اليوم (مسجّل أو معلّق).
class RequestedPermissionType extends ApiPermissionType {
  const RequestedPermissionType({
    required super.type,
    required super.code,
    required super.name,
    required this.registered,
  });

  factory RequestedPermissionType.fromApi(Map<String, dynamic> json) {
    return RequestedPermissionType(
      type: _int(json['type']) ?? 0,
      code: _str(json['code']) ?? '',
      name: _str(json['name']) ?? '',
      registered: json['status'] == 'registered',
    );
  }

  /// `registered` = مسجّل فعلاً في `permissions`؛ وإلا فهو معلّق بانتظار الاعتماد.
  final bool registered;

  String get statusLabel => registered ? 'مسجّل' : 'قيد الاعتماد';
}

/// حالة جدول الدوام للتاريخ المطلوب.
enum ScheduleStatus { ok, missing, unavailable }

ScheduleStatus _scheduleStatus(Object? v) => switch (v) {
      'ok' => ScheduleStatus.ok,
      'unavailable' => ScheduleStatus.unavailable,
      _ => ScheduleStatus.missing,
    };

/// معلومات الدوام المستخرجة من نظام البصمة (`RequestScheduleDto`).
class RequestSchedule {
  const RequestSchedule({
    required this.status,
    required this.profile,
    this.source,
    this.scheduleId,
    this.scheduleName,
    this.checkIn,
    this.checkOut,
    this.shiftHours,
    this.dayType,
  });

  factory RequestSchedule.fromApi(Map<String, dynamic> json) {
    return RequestSchedule(
      status: _scheduleStatus(json['status']),
      profile: _str(json['profile']) ?? 'UNKNOWN',
      source: _str(json['source']),
      scheduleId: _int(json['scheduleId']),
      scheduleName: _str(json['scheduleName']),
      checkIn: _str(json['checkIn']),
      checkOut: _str(json['checkOut']),
      shiftHours: _num(json['shiftHours']),
      dayType: _str(json['dayType']),
    );
  }

  final ScheduleStatus status;

  /// `SHORT | LONG | OPEN | NO_SECOND_PUNCH | EXTENDED_GRACE | EXEMPT | UNKNOWN`.
  final String profile;

  /// `date` = من التاريخ نفسه، `today` = من اليوم لعدم وجود سجل للتاريخ بعد.
  final String? source;
  final int? scheduleId;
  final String? scheduleName;
  final String? checkIn;
  final String? checkOut;
  final double? shiftHours;
  final String? dayType;

  bool get isExempt => profile == 'EXEMPT';
  bool get fromToday => source == 'today';

  String get profileLabel => switch (profile) {
        'SHORT' => 'دوام قصير',
        'LONG' => 'دوام طويل',
        'OPEN' => 'دوام مفتوح',
        'NO_SECOND_PUNCH' => 'دوام بدون بصمة ثانية',
        'EXTENDED_GRACE' => 'دوام بفترة سماح ممتدة',
        'EXEMPT' => 'معفى من البصمة',
        _ => 'غير محدد',
      };

  /// `08:00:00` → `08:00`.
  static String? hhmm(String? t) =>
      t == null || t.length < 5 ? t : t.substring(0, 5);

  String? get hoursLabel {
    final from = hhmm(checkIn);
    final to = hhmm(checkOut);
    if (from == null || to == null) return null;
    return '$from – $to';
  }
}

/// البصمات المسجّلة في اليوم (`DayPunchesDto`).
class DayPunches {
  const DayPunches({this.checkIn, this.breakOut, this.resume, this.checkOut});

  factory DayPunches.fromApi(Map<String, dynamic> json) {
    return DayPunches(
      checkIn: _str(json['checkIn']),
      breakOut: _str(json['breakOut']),
      resume: _str(json['resume']),
      checkOut: _str(json['checkOut']),
    );
  }

  final String? checkIn;
  final String? breakOut;
  final String? resume;
  final String? checkOut;

  bool get isEmpty =>
      checkIn == null && breakOut == null && resume == null && checkOut == null;

  /// أزواج (تسمية، وقت) للبصمات الموجودة فقط.
  List<(String, String)> get entries => [
        if (checkIn != null) ('دخول', RequestSchedule.hhmm(checkIn)!),
        if (breakOut != null) ('خروج استراحة', RequestSchedule.hhmm(breakOut)!),
        if (resume != null) ('عودة', RequestSchedule.hhmm(resume)!),
        if (checkOut != null) ('خروج', RequestSchedule.hhmm(checkOut)!),
      ];
}

/// رصيد أذونات التأخير/الخروج المبكر الشهري (`RequestQuotaDto`).
class RequestQuota {
  const RequestQuota({
    required this.limit,
    required this.used,
    required this.pending,
    required this.remaining,
  });

  factory RequestQuota.fromApi(Map<String, dynamic> json) {
    return RequestQuota(
      limit: _int(json['limit']) ?? 3,
      used: _int(json['used']) ?? 0,
      pending: _int(json['pending']) ?? 0,
      remaining: _int(json['remaining']) ?? 0,
    );
  }

  final int limit;
  final int used;
  final int pending;
  final int remaining;

  bool get exhausted => remaining <= 0;
}

/// كل ما تحتاجه شاشة «تقديم طلب إذن» في استدعاء واحد (`RequestOptionsDto`).
class PermissionRequestOptions {
  const PermissionRequestOptions({
    required this.date,
    required this.today,
    required this.minDate,
    required this.maxDate,
    required this.schedule,
    required this.punches,
    required this.monthLocked,
    required this.quota,
    required this.allowedTypes,
    required this.requestedTypes,
    required this.canSubmit,
  });

  factory PermissionRequestOptions.fromApi(Map<String, dynamic> json) {
    final range = (json['dateRange'] as Map?)?.cast<String, dynamic>();
    final punches = (json['punches'] as Map?)?.cast<String, dynamic>();
    return PermissionRequestOptions(
      date: _str(json['date']) ?? '',
      today: _str(json['today']) ?? '',
      minDate: _str(range?['min']) ?? '',
      maxDate: _str(range?['max']) ?? '',
      schedule: RequestSchedule.fromApi(
        (json['schedule'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      punches: punches == null ? null : DayPunches.fromApi(punches),
      monthLocked: json['monthLocked'] == true,
      quota: RequestQuota.fromApi(
        (json['quota'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      allowedTypes: [
        for (final t in (json['allowedTypes'] as List? ?? const []))
          ApiPermissionType.fromApi((t as Map).cast<String, dynamic>()),
      ],
      requestedTypes: [
        for (final t in (json['requestedTypes'] as List? ?? const []))
          RequestedPermissionType.fromApi((t as Map).cast<String, dynamic>()),
      ],
      canSubmit: json['canSubmit'] == true,
    );
  }

  final String date;
  final String today;
  final String minDate;
  final String maxDate;
  final RequestSchedule schedule;
  final DayPunches? punches;
  final bool monthLocked;
  final RequestQuota quota;
  final List<ApiPermissionType> allowedTypes;
  final List<RequestedPermissionType> requestedTypes;
  final bool canSubmit;

  /// النوع مطلوب سابقاً في هذا اليوم؟
  RequestedPermissionType? requestedOf(int type) {
    for (final r in requestedTypes) {
      if (r.type == type) return r;
    }
    return null;
  }

  /// السبب المعروض للمستخدم عندما يكون `canSubmit == false`.
  String? get blockedReason {
    if (monthLocked) {
      return 'تم البدء في احتساب مستحقات هذا الشهر، لا يمكن تقديم طلبات بتاريخه.';
    }
    if (schedule.isExempt) return 'أنت معفى من البصمة ولا تحتاج إلى طلب إذن.';
    if (schedule.status == ScheduleStatus.unavailable) {
      return 'نظام البصمة غير متاح حالياً، حاول مرة أخرى لاحقاً.';
    }
    if (schedule.status == ScheduleStatus.missing) {
      return 'لا توجد بيانات دوام مسجلة لك في جهاز البصمة لهذا التاريخ.';
    }
    if (allowedTypes.isEmpty) {
      return 'لا توجد أنواع أذونات متاحة لنوع دوامك في هذا التاريخ.';
    }
    return canSubmit ? null : 'لا يمكن تقديم طلب في هذا التاريخ.';
  }
}

/// نتيجة إرسال طلب إذن بنجاح (`PermissionRequestResultDto`).
class PermissionRequestResult {
  const PermissionRequestResult({
    required this.id,
    required this.type,
    required this.date,
    required this.state,
    required this.submittedAt,
    required this.message,
    this.punchKind,
    this.punchTime,
  });

  factory PermissionRequestResult.fromApi(Map<String, dynamic> json) {
    final punch = (json['punch'] as Map?)?.cast<String, dynamic>();
    return PermissionRequestResult(
      id: _int(json['id']) ?? 0,
      type: ApiPermissionType.fromApi(
        (json['type'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      date: _str(json['date']) ?? '',
      state: _str(json['state']) ?? 'تم الإرسال',
      submittedAt: _str(json['submittedAt']) ?? '',
      message: _str(json['message']) ?? 'تم تقديم طلبك بنجاح',
      punchKind: _str(punch?['kind']),
      punchTime: _str(punch?['time']),
    );
  }

  final int id;
  final ApiPermissionType type;
  final String date;
  final String state;
  final String submittedAt;
  final String message;

  /// البصمة التي حقّقت الشرط (للأنواع 1 و7).
  final String? punchKind;
  final String? punchTime;
}
