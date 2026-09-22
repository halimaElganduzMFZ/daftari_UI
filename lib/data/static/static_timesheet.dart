import '../models/timesheet.dart';

/// بيانات تجريبية لسجل الحضور/البوابة بنفس شكل `GET /me/timesheet`،
/// تُولَّد لأي فترة مطلوبة بنمط أسبوعي ثابت (بلا عشوائية حتى تثبت الاختبارات).
abstract final class StaticTimesheet {
  static final DateTime _minDate = DateTime(2025, 8, 1);
  static final DateTime _violationCutoff = DateTime(2025, 8, 15);

  static TimesheetResult build({DateTime? from, DateTime? to}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var start = from ?? DateTime(today.year, today.month, 1);
    var clamped = false;
    if (start.isBefore(_minDate)) {
      start = _minDate;
      clamped = true;
    }
    var end = to == null || to.isBefore(_minDate) ? today : to;
    if (end.isBefore(start)) end = start;

    final days = <TimesheetDay>[];
    var cursor = start;
    var id = 1000;
    while (!cursor.isAfter(end) && !cursor.isAfter(today)) {
      days.add(_day(id++, cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    return TimesheetResult(
      available: true,
      range: TimesheetRange(
        from: start,
        to: end,
        minDate: _minDate,
        clamped: clamped,
        violationCutoffDate: _violationCutoff,
      ),
      employee: const TimesheetEmployee(
        employeeNumber: '10234',
        name: 'أحمد علي المقريف',
        workplace: 'إدارة تقنية المعلومات',
      ),
      lastSync: TimesheetLastSync(
        batchDate: _iso(today),
        targetMonth: '${today.year}-${today.month.toString().padLeft(2, '0')}',
        endSync: '${_iso(today)} 02:10:07',
      ),
      summary: _summarize(days),
      days: days,
    );
  }

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static TimesheetDay _day(int id, DateTime date) {
    // الجمعة والسبت راحة.
    if (date.weekday == DateTime.friday || date.weekday == DateTime.saturday) {
      return TimesheetDay(
        id: id,
        date: date,
        dayType: 'R',
        dayTypeName: 'راحة',
        isWorkDay: false,
        category: DayCategory.rest,
        tone: RowTone.rest,
        punches: const TimesheetPunches(),
        attendance: const TimesheetAttendance(
          state: null,
          description: 'راحة',
          badge: TimesheetBadge(tone: BadgeTone.neutral, text: 'راحة'),
        ),
        car: const TimesheetCar(
          exemption: TimesheetExemption(
            type: 'DAY_OFF',
            label: '---',
            isReal: false,
          ),
          judgment: TimesheetJudgment(
            code: 1,
            text: 'حضور مطابق',
            alertLevel: null,
            badge: TimesheetBadge(tone: BadgeTone.neutral, text: 'حضور مطابق'),
          ),
        ),
      );
    }

    // نمط متكرر حسب رقم اليوم في الشهر.
    final variant = date.day % 9;
    final inGrace = date.isBefore(_violationCutoff);

    switch (variant) {
      case 3: // تأخير بسيط
        return _work(
          id,
          date,
          punches: const TimesheetPunches(checkIn: '08:27', checkOut: '14:33'),
          state: AttendanceState.present,
          description: 'تأخير 27 د',
          stateTone: BadgeTone.neutral,
          undertime: '00:27',
          car: _car(
            number: '5-123456',
            inside: 360,
            gateIn: 1,
            gateOut: 1,
            judgment: 1,
          ),
        );
      case 4: // غياب
        return TimesheetDay(
          id: id,
          date: date,
          dayType: 'W',
          dayTypeName: 'يوم عمل',
          isWorkDay: true,
          category: DayCategory.absence,
          tone: RowTone.absence,
          workType: 'صباحي',
          workplace: 'المبنى الإداري',
          punches: const TimesheetPunches(),
          attendance: const TimesheetAttendance(
            state: AttendanceState.absent,
            description: 'غائب',
            badge: TimesheetBadge(tone: BadgeTone.red, text: 'غائب'),
          ),
          car: const TimesheetCar(
            exemption: TimesheetExemption(
              type: 'ABSENT',
              label: '---',
              isReal: false,
            ),
            judgment: TimesheetJudgment(
              code: 1,
              text: 'حضور مطابق',
              alertLevel: null,
              badge: TimesheetBadge(tone: BadgeTone.neutral, text: 'حضور مطابق'),
            ),
          ),
        );
      case 5: // إجازة
        return TimesheetDay(
          id: id,
          date: date,
          dayType: 'W',
          dayTypeName: 'يوم عمل',
          isWorkDay: true,
          category: DayCategory.leave,
          tone: RowTone.leave,
          workType: 'صباحي',
          workplace: 'المبنى الإداري',
          punches: const TimesheetPunches(),
          attendance: const TimesheetAttendance(
            state: AttendanceState.leave,
            description: 'إجازة سنوية',
            badge: TimesheetBadge(tone: BadgeTone.green, text: 'إجازة سنوية'),
          ),
          car: const TimesheetCar(
            exemption: TimesheetExemption(
              type: 'VACATION',
              label: '---',
              isReal: false,
            ),
            judgment: TimesheetJudgment(
              code: 1,
              text: 'حضور مطابق',
              alertLevel: null,
              badge: TimesheetBadge(tone: BadgeTone.neutral, text: 'حضور مطابق'),
            ),
          ),
        );
      case 6: // خروج بإذن (البصمة الثانية والثالثة)
        return _work(
          id,
          date,
          punches: const TimesheetPunches(
            checkIn: '07:58',
            breakOut: '10:05',
            resume: '12:02',
            checkOut: '14:31',
          ),
          state: AttendanceState.permitted,
          description: 'إذن خروج',
          stateTone: BadgeTone.yellow,
          car: _car(
            number: '5-123456',
            inside: 275,
            gateIn: 2,
            gateOut: 2,
            judgment: 2,
            exemption: const TimesheetExemption(
              type: 'GATE_OPEN_PERMISSION',
              label: 'إذن',
              isReal: true,
            ),
            permissionHours: 2,
            margin: 'إذن — 2.00 س',
          ),
        );
      case 7: // مخالفة بوابة
        return _work(
          id,
          date,
          punches: const TimesheetPunches(checkIn: '08:01', checkOut: '14:30'),
          state: AttendanceState.present,
          description: null,
          stateTone: BadgeTone.neutral,
          tone: inGrace ? null : RowTone.red,
          car: _car(
            number: '5-123456',
            inside: 300,
            gateIn: 2,
            gateOut: 2,
            judgment: 5,
            leak: 85,
            violation: true,
            inGrace: inGrace,
            displayText: 'خروج بالسيارة 01:25 بلا إذن',
          ),
        );
      case 8: // تنبيه
        return _work(
          id,
          date,
          punches: const TimesheetPunches(checkIn: '08:04', checkOut: '14:29'),
          state: AttendanceState.present,
          description: null,
          stateTone: BadgeTone.neutral,
          car: _car(
            number: '5-123456',
            inside: 370,
            gateIn: 1,
            gateOut: 1,
            judgment: 3,
            leak: 12,
          ),
        );
      default: // حضور عادي
        return _work(
          id,
          date,
          punches: const TimesheetPunches(checkIn: '07:55', checkOut: '14:32'),
          state: AttendanceState.present,
          description: null,
          stateTone: BadgeTone.neutral,
          car: _car(
            number: '5-123456',
            inside: 392,
            gateIn: 1,
            gateOut: 1,
            judgment: 1,
          ),
        );
    }
  }

  static TimesheetDay _work(
    int id,
    DateTime date, {
    required TimesheetPunches punches,
    required AttendanceState state,
    required String? description,
    required BadgeTone stateTone,
    required TimesheetCar car,
    RowTone? tone,
    String? undertime,
  }) {
    return TimesheetDay(
      id: id,
      date: date,
      dayType: 'W',
      dayTypeName: 'يوم عمل',
      isWorkDay: true,
      category: DayCategory.regular,
      tone: tone,
      workType: 'صباحي',
      workplace: 'المبنى الإداري',
      punches: punches,
      attendance: TimesheetAttendance(
        state: state,
        description: description,
        badge: TimesheetBadge(tone: stateTone, text: description ?? '—'),
        work: '06:30',
        undertime: undertime,
        durationMinutes: 390,
      ),
      car: car,
    );
  }

  static TimesheetCar _car({
    required String number,
    required int inside,
    required int gateIn,
    required int gateOut,
    required int judgment,
    int leak = 0,
    bool violation = false,
    bool inGrace = false,
    TimesheetExemption? exemption,
    double permissionHours = 0,
    String margin = '- -',
    String? displayText,
  }) {
    final badge = inGrace && violation
        ? const TimesheetBadge(tone: BadgeTone.neutral, text: 'ضمن فترة السماح')
        : switch (judgment) {
            1 => exemption?.isReal == true
                ? const TimesheetBadge(tone: BadgeTone.green, text: 'مطابق')
                : const TimesheetBadge(
                    tone: BadgeTone.neutral,
                    text: 'حضور مطابق',
                  ),
            2 => const TimesheetBadge(tone: BadgeTone.yellow, text: 'مجاز بإذن'),
            3 => const TimesheetBadge(tone: BadgeTone.blue, text: 'تنبيه'),
            4 => const TimesheetBadge(tone: BadgeTone.orange, text: 'مخالفة'),
            5 || 6 => const TimesheetBadge(tone: BadgeTone.red, text: 'مخالفة'),
            _ => const TimesheetBadge(tone: BadgeTone.neutral, text: 'بدون بيانات'),
          };
    return TimesheetCar(
      number: number,
      insideMinutes: inside,
      gateInCount: gateIn,
      gateOutCount: gateOut,
      totalDurationHours: inside / 60,
      timeOutsideHours: leak / 60,
      permissionHoursUsed: permissionHours,
      leakMinutes: leak,
      leak: formatMinutes(leak),
      permissionMargin: margin,
      exemption: exemption,
      isViolation: violation,
      inGracePeriod: inGrace,
      countsAsViolation: violation && !inGrace,
      judgment: TimesheetJudgment(
        code: judgment,
        text: badge.text,
        alertLevel: null,
        badge: badge,
      ),
      displayText: displayText,
    );
  }

  static TimesheetSummary _summarize(List<TimesheetDay> days) {
    var workDays = 0,
        present = 0,
        leave = 0,
        carViolations = 0,
        absence = 0,
        tsViolations = 0,
        code6 = 0,
        leakMinutes = 0;
    for (final d in days) {
      final counted = d.car.countsAsViolation;
      final st = d.attendance.state;
      if (d.isWorkDay) {
        workDays++;
        if ((st == AttendanceState.permitted || st == AttendanceState.present) &&
            !counted) {
          present++;
        }
        if (st == AttendanceState.leave) leave++;
      }
      if (counted) carViolations++;
      if (d.car.judgment.code == 6 && !d.car.inGracePeriod) code6++;
      if (st == AttendanceState.absent) {
        if (d.attendance.description == 'غائب') {
          absence++;
        } else {
          tsViolations++;
        }
      }
      leakMinutes += d.car.leakMinutes;
    }
    return TimesheetSummary(
      workDays: workDays,
      presentFullDays: present,
      leaveDays: leave,
      carViolations: carViolations,
      absenceDays: absence,
      timesheetViolationDays: tsViolations,
      violationCode6: code6,
      totalLeakMinutes: leakMinutes,
      totalLeak: formatMinutes(leakMinutes),
    );
  }
}
