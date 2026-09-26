/// نماذج «سجل الحضور والغياب + حركة البوابة» — مطابقة لـ `TimesheetDto`
/// في `GET /me/timesheet` (بديل `time_sheet_employee.php` و`Vehicle_Employee_Log.php`).
///
/// كل الحسابات (التصنيف، ألوان الشارات، فترة السماح، العدّادات) تأتي من الخادم؛
/// هنا نقرأ الحقول فقط ونضيف مساعدات عرض.
library;

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _double(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _bool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

/// لون الشارة كما يرسله الخادم؛ الواجهة تحوّله إلى لوحة ألوانها.
enum BadgeTone {
  red,
  orange,
  blue,
  yellow,
  green,
  neutral;

  static BadgeTone parse(dynamic raw) => switch (_str(raw)) {
    'red' => BadgeTone.red,
    'orange' => BadgeTone.orange,
    'blue' => BadgeTone.blue,
    'yellow' => BadgeTone.yellow,
    'green' => BadgeTone.green,
    _ => BadgeTone.neutral,
  };
}

class TimesheetBadge {
  const TimesheetBadge({required this.tone, required this.text});

  final BadgeTone tone;
  final String text;

  factory TimesheetBadge.fromApi(Map<String, dynamic> json) => TimesheetBadge(
    tone: BadgeTone.parse(json['tone']),
    text: _str(json['text']) ?? '—',
  );
}

/// تصنيف اليوم بالأولوية القديمة: راحة > إجازة > غياب > عادي.
enum DayCategory {
  rest,
  leave,
  absence,
  regular;

  static DayCategory parse(dynamic raw) => switch (_str(raw)) {
    'rest' => DayCategory.rest,
    'leave' => DayCategory.leave,
    'absence' => DayCategory.absence,
    _ => DayCategory.regular,
  };
}

/// تظليل الصف في الجدول القديم (`att2-row-*`).
enum RowTone {
  rest,
  leave,
  absence,
  red,
  orange;

  static RowTone? parse(dynamic raw) => switch (_str(raw)) {
    'rest' => RowTone.rest,
    'leave' => RowTone.leave,
    'absence' => RowTone.absence,
    'red' => RowTone.red,
    'orange' => RowTone.orange,
    _ => null,
  };
}

/// `state_Nm`: A غائب · P مأذون · V إجازة · Z حاضر.
enum AttendanceState {
  absent,
  permitted,
  leave,
  present;

  static AttendanceState? parse(dynamic raw) => switch (_str(raw)) {
    'A' => AttendanceState.absent,
    'P' => AttendanceState.permitted,
    'V' => AttendanceState.leave,
    'Z' => AttendanceState.present,
    _ => null,
  };
}

class TimesheetPunches {
  const TimesheetPunches({
    this.checkIn,
    this.breakOut,
    this.resume,
    this.checkOut,
  });

  final String? checkIn;

  /// البصمة الثانية (`att_break`).
  final String? breakOut;

  /// البصمة الثالثة (`att_resume`).
  final String? resume;
  final String? checkOut;

  bool get isEmpty =>
      checkIn == null && breakOut == null && resume == null && checkOut == null;

  factory TimesheetPunches.fromApi(Map<String, dynamic> json) =>
      TimesheetPunches(
        checkIn: _str(json['checkIn']),
        breakOut: _str(json['breakOut']),
        resume: _str(json['resume']),
        checkOut: _str(json['checkOut']),
      );
}

class TimesheetAttendance {
  const TimesheetAttendance({
    required this.state,
    required this.description,
    required this.badge,
    this.work,
    this.undertime,
    this.overtime,
    this.durationMinutes,
  });

  final AttendanceState? state;

  /// وصف `DELAY_Nm` (مثل «غائب»، «تأخير»...).
  final String? description;

  /// شارة «الحالة (الوصف)» القديمة.
  final TimesheetBadge badge;
  final String? work;
  final String? undertime;
  final String? overtime;
  final int? durationMinutes;

  factory TimesheetAttendance.fromApi(Map<String, dynamic> json) =>
      TimesheetAttendance(
        state: AttendanceState.parse(json['state']),
        description: _str(json['description']),
        badge: TimesheetBadge.fromApi(_map(json['badge'])),
        work: _str(json['work']),
        undertime: _str(json['undertime']),
        overtime: _str(json['overtime']),
        durationMinutes: _int(json['durationMinutes']),
      );
}

class TimesheetExemption {
  const TimesheetExemption({
    required this.type,
    required this.label,
    required this.isReal,
  });

  final String type;

  /// «إذن» للاستثناءات الحقيقية، و«---» للحالات الآلية.
  final String label;

  /// إذن فعلي وليس حالة آلية (غياب/راحة/إجازة).
  final bool isReal;

  factory TimesheetExemption.fromApi(Map<String, dynamic> json) =>
      TimesheetExemption(
        type: _str(json['type']) ?? '',
        label: _str(json['label']) ?? '---',
        isReal: _bool(json['isReal']),
      );
}

class TimesheetJudgment {
  const TimesheetJudgment({
    required this.code,
    required this.text,
    required this.alertLevel,
    required this.badge,
  });

  /// `judgment_code` من 1 إلى 6 (4–6 مخالفات).
  final int? code;
  final String? text;
  final String? alertLevel;

  /// شارة «الحالة» الخاصة بالسيارة بعد تطبيق فترة السماح.
  final TimesheetBadge badge;

  factory TimesheetJudgment.fromApi(Map<String, dynamic> json) =>
      TimesheetJudgment(
        code: _int(json['code']),
        text: _str(json['text']),
        alertLevel: _str(json['alertLevel']),
        badge: TimesheetBadge.fromApi(_map(json['badge'])),
      );
}

class TimesheetCar {
  const TimesheetCar({
    this.number,
    this.insideMinutes,
    this.gateInCount,
    this.gateOutCount,
    this.totalDurationHours,
    this.timeOutsideHours,
    this.permissionHoursUsed = 0,
    this.remainingLeakHours,
    this.leakMinutes = 0,
    this.leak = '00:00',
    this.permissionMargin = '- -',
    this.exemption,
    this.isViolation = false,
    this.inGracePeriod = false,
    this.countsAsViolation = false,
    this.violationLockedAt,
    this.movementSequence,
    required this.judgment,
    this.displayText,
  });

  final String? number;
  final int? insideMinutes;
  final int? gateInCount;
  final int? gateOutCount;
  final double? totalDurationHours;
  final double? timeOutsideHours;
  final double permissionHoursUsed;
  final double? remainingLeakHours;

  /// وقت الخروج بلا إذن بالدقائق.
  final int leakMinutes;

  /// [leakMinutes] بصيغة HH:MM.
  final String leak;

  /// نص «هامش / إذن السماحية» القديم.
  final String permissionMargin;
  final TimesheetExemption? exemption;

  /// العلم الخام كما أُرشف.
  final bool isViolation;

  /// اليوم قبل تاريخ بداية احتساب المخالفات.
  final bool inGracePeriod;

  /// ما تعتمده العدّادات: مخالفة وخارج فترة السماح.
  final bool countsAsViolation;
  final String? violationLockedAt;
  final String? movementSequence;
  final TimesheetJudgment judgment;
  final String? displayText;

  /// هل توجد أي بيانات سيارة لهذا اليوم؟
  bool get hasData =>
      number != null ||
      (gateInCount ?? 0) > 0 ||
      (gateOutCount ?? 0) > 0 ||
      insideMinutes != null;

  /// مدة البقاء داخل المنطقة بصيغة HH:MM (أو «—»).
  String get insideLabel {
    final m = insideMinutes;
    if (m == null) return '—';
    return formatMinutes(m);
  }

  factory TimesheetCar.fromApi(Map<String, dynamic> json) => TimesheetCar(
    number: _str(json['number']),
    insideMinutes: _int(json['insideMinutes']),
    gateInCount: _int(json['gateInCount']),
    gateOutCount: _int(json['gateOutCount']),
    totalDurationHours: _double(json['totalDurationHours']),
    timeOutsideHours: _double(json['timeOutsideHours']),
    permissionHoursUsed: _double(json['permissionHoursUsed']) ?? 0,
    remainingLeakHours: _double(json['remainingLeakHours']),
    leakMinutes: _int(json['leakMinutes']) ?? 0,
    leak: _str(json['leak']) ?? '00:00',
    permissionMargin: _str(json['permissionMargin']) ?? '- -',
    exemption: json['exemption'] is Map
        ? TimesheetExemption.fromApi(_map(json['exemption']))
        : null,
    isViolation: _bool(json['isViolation']),
    inGracePeriod: _bool(json['inGracePeriod']),
    countsAsViolation: _bool(json['countsAsViolation']),
    violationLockedAt: _str(json['violationLockedAt']),
    movementSequence: _str(json['movementSequence']),
    judgment: TimesheetJudgment.fromApi(_map(json['judgment'])),
    displayText: _str(json['displayText']),
  );
}

/// صف واحد لكل يوم عمل مؤرشف.
class TimesheetDay {
  const TimesheetDay({
    required this.id,
    required this.date,
    this.dayType,
    this.dayTypeName,
    required this.isWorkDay,
    required this.category,
    this.tone,
    this.workType,
    this.workplace,
    required this.punches,
    required this.attendance,
    required this.car,
    this.archivedAt,
    this.actualAbsence = false,
    this.gateAbsence = false,
    this.countedAbsence = false,
  });

  final int id;
  final bool actualAbsence;
  final bool gateAbsence;
  final bool countedAbsence;
  final DateTime date;

  /// `daytype` (W = يوم عمل).
  final String? dayType;

  /// `daytype_Nm` مثل «يوم عمل» / «راحة».
  final String? dayTypeName;
  final bool isWorkDay;
  final DayCategory category;
  final RowTone? tone;
  final String? workType;
  final String? workplace;
  final TimesheetPunches punches;
  final TimesheetAttendance attendance;
  final TimesheetCar car;
  final String? archivedAt;

  bool get isRest => category == DayCategory.rest;
  bool get isLeave => category == DayCategory.leave;
  bool get isAbsence => category == DayCategory.absence;

  factory TimesheetDay.fromApi(Map<String, dynamic> json) {
    final rawDate = _str(json['date']) ?? '';
    return TimesheetDay(
      actualAbsence: _map(json['absence'])['actual'] == true,
      gateAbsence: _map(json['absence'])['gate'] == true,
      countedAbsence: _map(json['absence'])['counted'] == true,
      id: _int(json['id']) ?? 0,
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      dayType: _str(json['dayType']),
      dayTypeName: _str(json['dayTypeName']),
      isWorkDay: _bool(json['isWorkDay']),
      category: DayCategory.parse(json['category']),
      tone: RowTone.parse(json['tone']),
      workType: _str(json['workType']),
      workplace: _str(json['workplace']),
      punches: TimesheetPunches.fromApi(_map(json['punches'])),
      attendance: TimesheetAttendance.fromApi(_map(json['attendance'])),
      car: TimesheetCar.fromApi(_map(json['car'])),
      archivedAt: _str(json['archivedAt']),
    );
  }
}

class TimesheetEmployee {
  const TimesheetEmployee({
    required this.employeeNumber,
    this.name,
    this.workplace,
  });

  final String employeeNumber;
  final String? name;
  final String? workplace;

  factory TimesheetEmployee.fromApi(Map<String, dynamic> json) =>
      TimesheetEmployee(
        employeeNumber: _str(json['employeeNumber']) ?? '',
        name: _str(json['name']),
        workplace: _str(json['workplace']),
      );
}

class TimesheetRange {
  const TimesheetRange({
    required this.from,
    required this.to,
    required this.minDate,
    required this.clamped,
    required this.violationCutoffDate,
  });

  final DateTime from;
  final DateTime to;

  /// أقدم تاريخ متاح في الأرشيف (`TIMESHEET_MIN_DATE`).
  final DateTime minDate;

  /// تم تقديم «من» إلى [minDate] لأن المطلوب أقدم منه.
  final bool clamped;

  /// بداية احتساب مخالفات البوابة؛ ما قبلها ضمن فترة السماح.
  final DateTime violationCutoffDate;

  factory TimesheetRange.fromApi(Map<String, dynamic> json) {
    DateTime parse(dynamic v, DateTime fallback) =>
        DateTime.tryParse(_str(v) ?? '') ?? fallback;
    final today = DateTime.now();
    return TimesheetRange(
      from: parse(json['from'], today),
      to: parse(json['to'], today),
      minDate: parse(json['minDate'], DateTime(2000)),
      clamped: _bool(json['clamped']),
      violationCutoffDate: parse(json['violationCutoffDate'], DateTime(2000)),
    );
  }
}

class TimesheetLastSync {
  const TimesheetLastSync({this.batchDate, this.targetMonth, this.endSync});

  final String? batchDate;
  final String? targetMonth;
  final String? endSync;

  bool get isEmpty =>
      batchDate == null && targetMonth == null && endSync == null;

  factory TimesheetLastSync.fromApi(Map<String, dynamic> json) =>
      TimesheetLastSync(
        batchDate: _str(json['batchDate']),
        targetMonth: _str(json['targetMonth']),
        endSync: _str(json['endSync']),
      );
}

/// العدّادات كما يحسبها الخادم (نفس منطق الصفحة القديمة).
class TimesheetSummary {
  const TimesheetSummary({
    this.workDays = 0,
    this.presentFullDays = 0,
    this.leaveDays = 0,
    this.carViolations = 0,
    this.absenceDays = 0,
    this.gateAbsenceDays,
    this.totalAbsenceDays,
    this.timesheetViolationDays = 0,
    this.violationCode6 = 0,
    this.totalLeakMinutes = 0,
    this.totalLeak = '00:00',
  });

  /// أيام `daytype = W`.
  final int workDays;

  /// أيام عمل بحضور كامل (P أو Z) بلا مخالفة سيارة محسوبة.
  final int presentFullDays;

  /// أيام عمل في إجازة (V).
  final int leaveDays;

  /// مخالفات سيارة محسوبة (خارج فترة السماح).
  final int carViolations;

  /// غياب وصفه «غائب» تماماً.
  final int absenceDays;
  final int? gateAbsenceDays;
  final int? totalAbsenceDays;

  /// غياب بوصف آخر — مخالفات تايم شيت.
  final int timesheetViolationDays;

  /// المخالفات ذات `judgment_code = 6`.
  final int violationCode6;
  final int totalLeakMinutes;
  final String totalLeak;

  factory TimesheetSummary.fromApi(Map<String, dynamic> json) =>
      TimesheetSummary(
        workDays: _int(json['workDays']) ?? 0,
        presentFullDays: _int(json['presentFullDays']) ?? 0,
        leaveDays: _int(json['leaveDays']) ?? 0,
        carViolations: _int(json['carViolations']) ?? 0,
        absenceDays: _int(json['absenceDays']) ?? 0,
        gateAbsenceDays: _int(json['gateAbsenceDays']),
        totalAbsenceDays: _int(json['totalAbsenceDays']),
        timesheetViolationDays: _int(json['timesheetViolationDays']) ?? 0,
        violationCode6: _int(json['violationCode6']) ?? 0,
        totalLeakMinutes: _int(json['totalLeakMinutes']) ?? 0,
        totalLeak: _str(json['totalLeak']) ?? '00:00',
      );
}

/// استجابة `GET /me/timesheet` كاملة.
class TimesheetResult {
  const TimesheetResult({
    required this.available,
    required this.range,
    this.employee,
    this.lastSync,
    required this.summary,
    required this.days,
  });

  /// `status == 'ok'`؛ `false` عندما تكون قاعدة الأرشيف غير مهيّأة أو متوقفة.
  final bool available;
  final TimesheetRange range;
  final TimesheetEmployee? employee;
  final TimesheetLastSync? lastSync;
  final TimesheetSummary summary;

  /// يوم لكل تاريخ مؤرشف، تصاعدياً كما يرسله الخادم.
  final List<TimesheetDay> days;

  /// نفس الأيام من الأحدث إلى الأقدم (الأنسب للعرض في الهاتف).
  List<TimesheetDay> get daysNewestFirst =>
      days.reversed.toList(growable: false);

  factory TimesheetResult.fromApi(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final lastSync = json['lastSync'];
    return TimesheetResult(
      available: _str(json['status']) != 'unavailable',
      range: TimesheetRange.fromApi(_map(json['range'])),
      employee: json['employee'] is Map
          ? TimesheetEmployee.fromApi(_map(json['employee']))
          : null,
      lastSync: lastSync is Map
          ? TimesheetLastSync.fromApi(_map(lastSync))
          : null,
      summary: TimesheetSummary.fromApi(_map(json['summary'])),
      days: rawDays is List
          ? [
              for (final d in rawDays)
                if (d is Map)
                  TimesheetDay.fromApi(Map<String, dynamic>.from(d)),
            ]
          : const [],
    );
  }
}

/// دقائق → `HH:MM`.
String formatMinutes(int minutes) {
  final total = minutes < 0 ? 0 : minutes;
  final h = (total ~/ 60).toString().padLeft(2, '0');
  final m = (total % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
