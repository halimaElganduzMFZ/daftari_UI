/// نماذج تقديم طلب إجازة (بديل `Taking_a_day_off.php`).
///
/// تطابق `LeaveRequestOptionsDto` و`LeavePlanDto` و`LeaveRequestResultDto`
/// في وحدة `leave`.
library;

int? _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
double? _num(Object? v) =>
    v is num ? v.toDouble() : (v == null ? null : double.tryParse('$v'));
String? _str(Object? v) => v == null ? null : '$v';
Map<String, dynamic>? _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : null;

/// مكان قضاء الإجازة (`place_for_off`).
enum LeaveLocation {
  inside('INSIDE', 'داخلي'),
  outside('OUTSIDE', 'خارجي');

  const LeaveLocation(this.code, this.label);
  final String code;
  final String label;
}

/// تصنيف نوع الإجازة في الـ API.
enum LeaveKindCategory {
  /// يُخصم من رصيد (سنوية / طارئة).
  balance,

  /// مدة ثابتة من تاريخ البداية (زواج / حج / وضع / عدة).
  fixed,

  /// يتطلب مستنداً (دراسية).
  attachment,

  /// إعفاء حركة البوابة.
  exemption,
}

LeaveKindCategory _category(Object? v) => switch (v) {
  'fixed' => LeaveKindCategory.fixed,
  'attachment' => LeaveKindCategory.attachment,
  'exemption' => LeaveKindCategory.exemption,
  _ => LeaveKindCategory.balance,
};

/// الحقول التي يتطلبها نوع الإجازة (`LeaveKindFieldsDto`).
class LeaveKindFields {
  const LeaveKindFields({
    required this.reasonRequired,
    required this.locationEnabled,
    required this.attachmentRequired,
    required this.endDateFixed,
  });

  factory LeaveKindFields.fromApi(Map<String, dynamic>? json) {
    return LeaveKindFields(
      reasonRequired: json?['reason'] == 'required',
      locationEnabled: json?['location'] == 'optional',
      attachmentRequired: json?['attachment'] == 'required',
      endDateFixed: json?['endDate'] == 'fixed',
    );
  }

  final bool reasonRequired;
  final bool locationEnabled;
  final bool attachmentRequired;
  final bool endDateFixed;
}

/// ملخص نوع الإجازة (`LeaveKindSummaryDto`).
class LeaveKindSummary {
  const LeaveKindSummary({
    required this.code,
    required this.label,
    required this.holidayType,
    required this.category,
    this.fixedDays,
  });

  factory LeaveKindSummary.fromApi(Map<String, dynamic> json) {
    return LeaveKindSummary(
      code: _str(json['code']) ?? '',
      label: _str(json['label']) ?? '',
      holidayType: _int(json['holidayType']) ?? 0,
      category: _category(json['category']),
      fixedDays: _int(json['fixedDays']),
    );
  }

  final String code;
  final String label;
  final int holidayType;
  final LeaveKindCategory category;
  final int? fixedDays;
}

/// نوع إجازة مع توفّره للموظف الحالي (`LeaveKindDto`).
class LeaveKindOption extends LeaveKindSummary {
  const LeaveKindOption({
    required super.code,
    required super.label,
    required super.holidayType,
    required super.category,
    super.fixedDays,
    required this.fields,
    required this.available,
    required this.pendingRequests,
    this.unavailableReason,
  });

  factory LeaveKindOption.fromApi(Map<String, dynamic> json) {
    return LeaveKindOption(
      code: _str(json['code']) ?? '',
      label: _str(json['label']) ?? '',
      holidayType: _int(json['holidayType']) ?? 0,
      category: _category(json['category']),
      fixedDays: _int(json['fixedDays']),
      fields: LeaveKindFields.fromApi(_map(json['fields'])),
      available: json['available'] == true,
      pendingRequests: _int(json['pendingRequests']) ?? 0,
      unavailableReason: _str(json['unavailableReason']),
    );
  }

  final LeaveKindFields fields;
  final bool available;
  final int pendingRequests;

  /// رمز الرفض الذي سيحصل عليه الطلب (مثل `SAME_KIND_PENDING`)؛ null عند التوفر.
  final String? unavailableReason;

  bool get isAnnual => code == 'ANNUAL_LEAVE';
  bool get isEmergency => code == 'EMERGENCY_LEAVE';
  bool get isGateExemption => category == LeaveKindCategory.exemption;

  /// شرح مختصر لسبب عدم التوفر.
  String? get unavailableLabel => switch (unavailableReason) {
    null => null,
    'SAME_KIND_PENDING' => 'لديك طلب من هذا النوع لا يزال معلقاً',
    'ALREADY_GRANTED' => 'مُنحت هذه الإجازة مسبقاً (مرة واحدة في الخدمة)',
    'FEMALE_ONLY' => 'متاحة للموظفات فقط',
    'NOT_ELIGIBLE' => 'متاحة لمسؤولي الهياكل الرئيسية فقط',
    'EMPLOYEE_INACTIVE' => 'الموظف خارج الخدمة حالياً',
    'CONTRACT_NOT_ELIGIBLE' => 'عقد التعاون لا يخوّل أخذ إجازة',
    'MISSING_START_DATE' => 'لا يوجد تاريخ بداية عمل مسجّل',
    'MONTH_LOCKED' => 'شهر التاريخ المطلوب مقفل للمرتبات',
    final other => 'غير متاح حالياً ($other)',
  };
}

/// أهلية الموظف (`LeaveEligibilityDto`).
class LeaveEligibility {
  const LeaveEligibility({
    required this.eligible,
    required this.female,
    required this.fridaysOff,
    required this.topLevelAssigner,
    this.reason,
  });

  factory LeaveEligibility.fromApi(Map<String, dynamic>? json) {
    return LeaveEligibility(
      eligible: json?['eligible'] == true,
      female: json?['female'] == true,
      fridaysOff: json?['fridaysOff'] == true,
      topLevelAssigner: json?['topLevelAssigner'] == true,
      reason: _str(json?['reason']),
    );
  }

  final bool eligible;
  final bool female;
  final bool fridaysOff;
  final bool topLevelAssigner;
  final String? reason;

  String? get reasonLabel => switch (reason) {
    null => null,
    'EMPLOYEE_NOT_FOUND' => 'لم يتم العثور على بطاقة الموظف.',
    'EMPLOYEE_INACTIVE' => 'هذا الموظف خارج الخدمة حالياً.',
    'CONTRACT_NOT_ELIGIBLE' => 'هذا الموظف عقد متعاون لا يحق له أخذ الإجازة.',
    _ => 'غير مؤهل لتقديم طلب إجازة.',
  };
}

/// دوام تاريخ البداية (`LeaveShiftDto`) — يحدد طريقة عدّ الأيام.
class LeaveShiftInfo {
  const LeaveShiftInfo({
    required this.status,
    required this.shift,
    this.source,
    this.scheduleName,
    this.checkIn,
    this.checkOut,
    this.shiftHours,
    this.dayType,
  });

  factory LeaveShiftInfo.fromApi(Map<String, dynamic>? json) {
    return LeaveShiftInfo(
      status: _str(json?['status']) ?? 'missing',
      shift: _str(json?['shift']) ?? 'UNKNOWN',
      source: _str(json?['source']),
      scheduleName: _str(json?['scheduleName']),
      checkIn: _str(json?['checkIn']),
      checkOut: _str(json?['checkOut']),
      shiftHours: _num(json?['shiftHours']),
      dayType: _str(json?['dayType']),
    );
  }

  /// `ok | missing | unavailable`.
  final String status;

  /// `REGULAR | CAMERAS | OPEN | SHIFT_17 | SHIFT_24 | UNKNOWN`.
  final String shift;
  final String? source;
  final String? scheduleName;
  final String? checkIn;
  final String? checkOut;
  final double? shiftHours;
  final String? dayType;

  bool get isOk => status == 'ok';
  bool get isUnavailable => status == 'unavailable';

  /// الدوام المفتوح تصنيف مستقل عن مناوبة SHIFT_24.
  bool get isOpen => shift == 'OPEN';

  /// تسميات `$typeOfShift` القديمة: 1 إداري · 2 كاميرات · 3 مفتوح · 6 مناوبين 17 · 7 مناوبين 24.
  String get shiftLabel => switch (shift) {
    'REGULAR' => 'دوام إداري',
    'CAMERAS' => 'ورديات كاميرات',
    'OPEN' => 'دوام مفتوح',
    'SHIFT_17' => 'مناوبين 17',
    'SHIFT_24' => 'مناوبين 24',
    _ => 'غير محدد',
  };

  /// طريقة عدّ أيام السنوية/الطارئة كما ينفّذها الـ API (`planLeave`).
  String get countingHint => switch (shift) {
    'REGULAR' =>
      'أيام تقويمية؛ الجمعة لا تُخصم من السنوية لذوي الأسبوع الإداري',
    'CAMERAS' =>
      'يومان لكل وردية عمل فعلية ضمن الفترة، وقد يُغطّى الرصيد جزءاً منها',
    'SHIFT_17' ||
    'SHIFT_24' => 'تُقرَّب المدة لأعلى إلى دورات من 3 أيام وتُمدَّد النهاية',
    'OPEN' => 'تُقرَّب المدة لأعلى إلى دورات من 4 أيام — أو يوماً بيوم عند طلب «استثناء»',
    _ => 'لا يمكن تحديد طريقة العدّ حتى يُعرف نوع الدوام',
  };
}

/// الأرصدة حتى اليوم (`LeaveBalancesDto`).
class LeaveBalances {
  const LeaveBalances({
    required this.asOf,
    required this.emergencyAllowance,
    required this.emergencyUsed,
    required this.emergencyRemaining,
    required this.emergencyPending,
    this.annualBalance,
    this.annualExact,
    this.annualPending,
    this.annualUnavailableReason,
  });

  factory LeaveBalances.fromApi(Map<String, dynamic>? json) {
    final emergency = _map(json?['emergency']);
    final annual = _map(json?['annual']);
    return LeaveBalances(
      asOf: _str(json?['asOf']) ?? '',
      emergencyAllowance: _int(emergency?['allowance']) ?? 12,
      emergencyUsed: _num(emergency?['used']) ?? 0,
      emergencyRemaining: _num(emergency?['remaining']) ?? 0,
      emergencyPending: _int(emergency?['pendingRequests']) ?? 0,
      annualBalance: _int(annual?['balance']),
      annualExact: _num(annual?['balanceExact']),
      annualPending: _int(annual?['pendingRequests']),
      annualUnavailableReason: _str(json?['annualUnavailableReason']),
    );
  }

  final String asOf;
  final int emergencyAllowance;
  final double emergencyUsed;
  final double emergencyRemaining;
  final int emergencyPending;

  /// null عندما لا يمكن حساب الرصيد السنوي (انظر `annualUnavailableReason`).
  final int? annualBalance;
  final double? annualExact;
  final int? annualPending;
  final String? annualUnavailableReason;
}

/// كل ما تحتاجه شاشة «طلب إجازة» في استدعاء واحد (`LeaveRequestOptionsDto`).
class LeaveRequestOptions {
  const LeaveRequestOptions({
    required this.date,
    required this.today,
    required this.minDate,
    required this.maxDate,
    required this.employee,
    required this.shift,
    required this.monthLocked,
    required this.balances,
    required this.kinds,
    this.exceptionAvailable = false,
  });

  factory LeaveRequestOptions.fromApi(Map<String, dynamic> json) {
    final range = _map(json['dateRange']);
    return LeaveRequestOptions(
      date: _str(json['date']) ?? '',
      today: _str(json['today']) ?? '',
      minDate: _str(range?['min']) ?? '',
      maxDate: _str(range?['max']) ?? '',
      employee: LeaveEligibility.fromApi(_map(json['employee'])),
      shift: LeaveShiftInfo.fromApi(_map(json['shift'])),
      monthLocked: json['monthLocked'] == true,
      balances: LeaveBalances.fromApi(_map(json['balances'])),
      kinds: [
        for (final k in (json['kinds'] as List? ?? const []))
          LeaveKindOption.fromApi((k as Map).cast<String, dynamic>()),
      ],
      exceptionAvailable: json['exceptionAvailable'] == true,
    );
  }

  final String date;
  final String today;
  final String minDate;
  final String maxDate;
  final LeaveEligibility employee;
  final LeaveShiftInfo shift;
  final bool monthLocked;
  final LeaveBalances balances;
  final List<LeaveKindOption> kinds;

  /// صلاحية الاستثناء كما يعيدها الخادم للموظف وتاريخ البداية المختارين.
  /// عند `true` يُرسل الطلب بـ `exception: true` فتُخصم الأيام يوماً بيوم
  /// (شاملة الجمعة) بدل دورات الأربعة أيام. لا يُحسب في الواجهة أبداً.
  final bool exceptionAvailable;

  LeaveKindOption? kindByCode(String code) {
    for (final k in kinds) {
      if (k.code == code) return k;
    }
    return null;
  }

  /// سبب يمنع التقديم كلياً (وليس لنوع واحد).
  String? get blockedReason {
    if (!employee.eligible) return employee.reasonLabel;
    if (monthLocked) {
      return 'تم البدء في احتساب مستحقات هذا الشهر، لا يمكن تقديم إجازة تبدأ فيه.';
    }
    return null;
  }
}

/// فحص الرصيد ضمن المعاينة (`LeaveBalanceCheckDto`).
class LeaveBalanceCheck {
  const LeaveBalanceCheck({
    required this.kind,
    required this.asOf,
    required this.available,
    required this.required,
    required this.remaining,
    double? charged,
  }) : charged = charged ?? required;

  factory LeaveBalanceCheck.fromApi(Map<String, dynamic> json) {
    return LeaveBalanceCheck(
      kind: _str(json['kind']) ?? 'annual',
      asOf: _str(json['asOf']) ?? '',
      available: _num(json['available']) ?? 0,
      required: _num(json['required']) ?? 0,
      remaining: _num(json['remaining']) ?? 0,
      charged: _num(json['charged']),
    );
  }

  /// `annual | emergency`.
  final String kind;
  final String asOf;
  final double available;

  /// ما يطلبه الطلب كاملاً (ورديات الكاميرات: يومان لكل وردية).
  final double required;

  /// ما يُخصم فعلاً — يساوي `required` إلا عند تغطية جزئية للكاميرات.
  final double charged;
  final double remaining;

  bool get sufficient => remaining >= 0;
}

/// مدى تغطية الرصيد للطلب (`LeaveCoverage`).
enum LeaveCoverage { full, partial, none }

LeaveCoverage _coverage(Object? v) => switch (v) {
  'partial' => LeaveCoverage.partial,
  'none' => LeaveCoverage.none,
  _ => LeaveCoverage.full,
};

/// صف واحد سيُدرج في لوحة الطلبات (`LeaveBlockDto`).
class LeaveBlock {
  const LeaveBlock({
    required this.from,
    required this.to,
    required this.days,
    this.id,
  });

  factory LeaveBlock.fromApi(Map<String, dynamic> json) {
    return LeaveBlock(
      id: _int(json['id']),
      from: _str(json['from']) ?? '',
      to: _str(json['to']) ?? '',
      days: _num(json['days']) ?? 0,
    );
  }

  final int? id;
  final String from;
  final String to;
  final double days;
}

/// نتيجة حساب الطلب دون إرساله (`LeavePlanDto`).
class LeavePlan {
  const LeavePlan({
    required this.kind,
    required this.from,
    required this.to,
    required this.requestedTo,
    required this.days,
    required this.blocks,
    required this.method,
    double? required,
    double? covered,
    this.coverage = LeaveCoverage.full,
    this.workShifts,
    this.shift,
    this.balance,
  }) : required = required ?? days,
       covered = covered ?? days;

  factory LeavePlan.fromApi(Map<String, dynamic> json) {
    final balance = _map(json['balance']);
    final shift = _map(json['shift']);
    return LeavePlan(
      kind: LeaveKindSummary.fromApi(_map(json['kind']) ?? const {}),
      from: _str(json['from']) ?? '',
      to: _str(json['to']) ?? '',
      requestedTo: _str(json['requestedTo']) ?? '',
      days: _num(json['days']) ?? 0,
      required: _num(json['required']),
      covered: _num(json['covered']),
      coverage: _coverage(json['coverage']),
      blocks: [
        for (final b in (json['blocks'] as List? ?? const []))
          LeaveBlock.fromApi((b as Map).cast<String, dynamic>()),
      ],
      method: _str(json['method']) ?? 'NONE',
      workShifts: _int(json['workShifts']),
      shift: shift == null ? null : LeaveShiftInfo.fromApi(shift),
      balance: balance == null ? null : LeaveBalanceCheck.fromApi(balance),
    );
  }

  final LeaveKindSummary kind;
  final String from;

  /// آخر يوم محسوب — قد يتجاوز `requestedTo` (دورات 3/4 أيام، ورديات الكاميرات).
  final String to;
  final String requestedTo;

  /// ما سيُخزَّن في `DAYS1` مجموعاً على السجلات (0 للإعفاء).
  final double days;

  /// ما يطلبه الطلب كاملاً؛ ورديات الكاميرات: يومان لكل وردية عمل.
  final double required;

  /// ما يدفعه الرصيد — يساوي `required` إلا عند التغطية الجزئية.
  final double covered;

  /// `partial` (كاميرات فقط): يُرسل الجزء المغطّى وتأتي رسالة اعتذار عن البقية.
  final LeaveCoverage coverage;
  final List<LeaveBlock> blocks;

  /// `FIXED | CALENDAR | FRIDAYS_EXCLUDED | ROUNDED_3 | ROUNDED_4 | CAMERA_SHIFTS | NONE`.
  final String method;
  final int? workShifts;
  final LeaveShiftInfo? shift;
  final LeaveBalanceCheck? balance;

  bool get endExtended => to != requestedTo;
  bool get isPartial => coverage == LeaveCoverage.partial;

  String get methodLabel => switch (method) {
    'FIXED' => 'مدة ثابتة حسب اللائحة',
    'CALENDAR' => 'أيام تقويمية',
    'FRIDAYS_EXCLUDED' => 'أيام تقويمية بدون الجمعة',
    'ROUNDED_3' => 'مقرّبة لدورات 3 أيام',
    'ROUNDED_4' => 'مقرّبة لدورات 4 أيام',
    'CAMERA_SHIFTS' => 'ورديات العمل الفعلية',
    _ => 'بدون خصم أيام',
  };
}

/// المرفق المخزّن (`LeaveAttachmentDto`).
class LeaveAttachmentInfo {
  const LeaveAttachmentInfo({
    required this.fileName,
    required this.extension,
    required this.size,
  });

  factory LeaveAttachmentInfo.fromApi(Map<String, dynamic> json) {
    return LeaveAttachmentInfo(
      fileName: _str(json['fileName']) ?? '',
      extension: _str(json['extension']) ?? '',
      size: _int(json['size']) ?? 0,
    );
  }

  final String fileName;
  final String extension;
  final int size;
}

/// نتيجة إرسال طلب إجازة بنجاح (`LeaveRequestResultDto`).
class LeaveRequestResult {
  const LeaveRequestResult({
    required this.requests,
    required this.plan,
    required this.state,
    required this.submittedAt,
    required this.message,
    this.attachment,
  });

  factory LeaveRequestResult.fromApi(Map<String, dynamic> json) {
    final attachment = _map(json['attachment']);
    return LeaveRequestResult(
      requests: [
        for (final r in (json['requests'] as List? ?? const []))
          LeaveBlock.fromApi((r as Map).cast<String, dynamic>()),
      ],
      plan: LeavePlan.fromApi(_map(json['plan']) ?? const {}),
      state: _str(json['state']) ?? 'تم الإرسال',
      submittedAt: _str(json['submittedAt']) ?? '',
      message: _str(json['message']) ?? 'تم تقديم طلبك بنجاح',
      attachment: attachment == null
          ? null
          : LeaveAttachmentInfo.fromApi(attachment),
    );
  }

  final List<LeaveBlock> requests;
  final LeavePlan plan;
  final String state;
  final String submittedAt;
  final String message;
  final LeaveAttachmentInfo? attachment;
}
