import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/date_range_filter_bar.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/timesheet.dart';
import '../../data/repositories/timesheet_repository.dart';
import '../request/request_error.dart';

/// التايم شيت الموحّد: حضور/انصراف + حركة البوابة في صفحة واحدة
/// (بديل `time_sheet_employee.php` و`Vehicle_Employee_Log.php`) — `GET /me/timesheet`.
///
/// لكل يوم: البصمات الأربع وشارة الحالة، ثم سطر مختصر للبوابة (الحكم، فترة
/// الانقطاع، هامش السماحية) دون تفاصيل الدخول/الخروج. الإحصائيات أعلى
/// الصفحة تُحسب محلياً من أيام الفترة نفسها حتى تطابق ما يراه الموظف.
class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.timesheet`.
  final TimesheetRepository? repository;

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  static const _pageSize = 8;

  DateTime? _from;
  DateTime? _to;
  TimesheetResult? _result;
  bool _loading = true;
  RequestErrorInfo? _error;
  int _visible = _pageSize;
  int _requestSeq = 0;

  TimesheetRepository get _repo => widget.repository ?? AppServices.timesheet;

  @override
  void initState() {
    super.initState();
    // الافتراضي كما في الصفحة القديمة: من أول الشهر الحالي إلى اليوم.
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.load(from: _from, to: _to);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _result = result;
        // نعكس الفترة الفعلية التي طبّقها الخادم (بعد القصّ إلى minDate).
        _from = result.range.from;
        _to = result.range.to;
        _visible = _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _error = _describe(e);
      });
    }
  }

  RequestErrorInfo _describe(Object e) {
    final info = describeRequestError(e);
    return info.title == 'تعذر تقديم الطلب'
        ? RequestErrorInfo(
            title: 'تعذر تحميل السجل',
            message: info.message,
            cause: info.cause,
          )
        : info;
  }

  void _setFrom(DateTime d) {
    setState(() {
      _from = d;
      if (_to != null && _to!.isBefore(d)) _to = d;
    });
    _load();
  }

  void _setTo(DateTime d) {
    setState(() {
      _to = d;
      if (_from != null && _from!.isAfter(d)) _from = d;
    });
    _load();
  }

  void _clear() {
    setState(() {
      _from = null;
      _to = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final ready = !_loading && _error == null && result != null;
    final days = ready ? result.daysNewestFirst : const <TimesheetDay>[];
    final visible = days.take(_visible).toList();
    final hasMore = _visible < days.length;
    final stats = ready ? _Stats.of(result.days) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التايم شيت')),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            _Header(
              stats: stats,
              workplace: result?.employee?.workplace,
              carNumber: ready ? _carNumberOf(result.days) : null,
            ),
            const SizedBox(height: 12),
            if (ready) _LastSyncBanner(sync: result.lastSync, rangeTo: result.range.to),
            if (ready) const SizedBox(height: 12),
            DateRangeFilterBar(
              from: _from,
              to: _to,
              hint: 'حدّد الفترة لعرض أيام الحضور وحركة البوابة',
              onFromChanged: _setFrom,
              onToChanged: _setTo,
              onCleared: _clear,
            ),
            const SizedBox(height: 12),
            if (ready && result.range.clamped)
              _NoteRow(
                icon: FontAwesomeIcons.circleInfo,
                text:
                    'الأرشيف يبدأ من ${_fmtDate(result.range.minDate)}؛ تم تعديل بداية الفترة تلقائياً.',
              ),
            const SizedBox(height: 4),
            if (_loading) ...[
              const _DaySkeleton(),
              const _DaySkeleton(),
              const _DaySkeleton(),
            ] else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else if (result != null && !result.available)
              const _UnavailableCard()
            else if (days.isEmpty)
              const AppSurface(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا توجد أيام مؤرشفة ضمن الفترة المحددة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate),
                  ),
                ),
              )
            else ...[
              Text(
                'عرض ${visible.length} من ${days.length} يوماً',
                style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              for (final day in visible) ...[
                _DayCard(day: day),
                const SizedBox(height: 10),
              ],
              if (hasMore)
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _visible = (_visible + _pageSize).clamp(0, days.length);
                  }),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text('عرض المزيد (${days.length - visible.length})'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.goldDeep,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _carNumberOf(List<TimesheetDay> days) {
    for (final d in days.reversed) {
      if (d.car.number != null) return d.car.number;
    }
    return null;
  }
}

String _fmtDate(DateTime d) => DateFormat('yyyy/MM/dd').format(d);

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// إحصائيات الفترة محسوبة محلياً من الأيام المعروضة (لا تعتمد على عدّادات الخادم).
class _Stats {
  const _Stats({
    required this.workDays,
    required this.present,
    required this.leave,
    required this.absence,
    required this.gateViolations,
    required this.leakMinutes,
    required this.unknown,
  });

  /// أيام العمل الرسمية (`daytype = W`).
  final int workDays;

  /// أيام عمل حضر فيها الموظف (حاضر/مأذون، أو حضر مع خصم).
  final int present;

  /// أيام عمل في إجازة.
  final int leave;

  /// أيام الغياب الفعلي: حالة A ووصفها «غائب» تماماً (قاعدة الصفحة القديمة).
  ///
  /// الأرشيف يضع الحالة A أيضاً على أيام الخصم (مثل مخالفات البوابة
  /// «تجاوز التسرب — خصم») رغم أن الموظف حضر فيها؛ تلك تُحتسب حضوراً هنا.
  final int absence;

  /// مخالفات بوابة محسوبة (خارج فترة السماح).
  final int gateViolations;

  /// إجمالي فترات الانقطاع بلا إذن.
  final int leakMinutes;

  /// أيام عمل بلا حالة معروفة (لم تُصنَّف في الأرشيف).
  final int unknown;

  String get leak => formatMinutes(leakMinutes);

  static _Stats of(List<TimesheetDay> days) {
    var work = 0, present = 0, leave = 0, absence = 0, violations = 0, leak = 0, unknown = 0;
    for (final d in days) {
      final st = d.attendance.state;
      final realAbsence = _isRealAbsence(d);
      if (d.isWorkDay) {
        work++;
        switch (st) {
          case AttendanceState.present || AttendanceState.permitted:
            present++;
          case AttendanceState.leave:
            leave++;
          case AttendanceState.absent:
            // A بوصف «غائب» = غياب؛ A بوصف آخر = حضر مع خصم.
            if (realAbsence) {
              absence++;
            } else {
              present++;
            }
          case null:
            // حضور ببصمة دون تصنيف يُعدّ حضوراً؛ بلا بصمة يبقى مجهولاً.
            if (d.punches.checkIn != null) {
              present++;
            } else {
              unknown++;
            }
        }
      } else if (realAbsence) {
        absence++;
      }
      if (d.car.countsAsViolation) violations++;
      leak += d.car.leakMinutes;
    }
    return _Stats(
      workDays: work,
      present: present,
      leave: leave,
      absence: absence,
      gateViolations: violations,
      leakMinutes: leak,
      unknown: unknown,
    );
  }

  /// غياب فعلي وفق النظام القديم: `state_Nm = 'A'` و`DELAY_Nm = 'غائب'`.
  static bool _isRealAbsence(TimesheetDay d) =>
      d.attendance.state == AttendanceState.absent &&
      (d.attendance.description?.trim() == 'غائب');
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stats,
    required this.workplace,
    required this.carNumber,
  });

  final _Stats? stats;
  final String? workplace;
  final String? carNumber;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    String n(int? v) => v == null ? '—' : '$v';
    final meta = [?workplace, if (carNumber != null) 'لوحة $carNumber'].join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2F2F2F), Color(0xFF4A4034)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(FontAwesomeIcons.fingerprint, color: Colors.white70, size: 15),
              SizedBox(width: 6),
              FaIcon(FontAwesomeIcons.carSide, color: Colors.white70, size: 15),
              SizedBox(width: 8),
              Text(
                'البصمة + البوابة',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'سجل حضورك وحركة البوابة',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meta, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(label: 'أيام دوام', value: n(s?.workDays)),
              const SizedBox(width: 10),
              _MiniStat(label: 'حضور', value: n(s?.present), accent: AppColors.success),
              const SizedBox(width: 10),
              _MiniStat(label: 'إجازة', value: n(s?.leave)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                label: 'غياب',
                value: n(s?.absence),
                accent: (s?.absence ?? 0) > 0 ? const Color(0xFFE0A0A0) : null,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'مخالفات بوابة',
                value: n(s?.gateViolations),
                accent: (s?.gateViolations ?? 0) > 0 ? const Color(0xFFE0A0A0) : null,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'انقطاع بلا إذن',
                value: s?.leak ?? '—',
                accent: (s?.leakMinutes ?? 0) > 0 ? const Color(0xFFE8C88A) : null,
              ),
            ],
          ),
          if ((s?.unknown ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${s!.unknown} يوم دوام بلا تصنيف في الأرشيف بعد',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent ?? Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة «آخر تحديث» البارزة: خضراء عندما تكون بيانات اليوم، حمراء عندما
/// يتأخر الأرشيف عن تاريخ اليوم (out of date) مع توضيح الأيام غير المشمولة.
class _LastSyncBanner extends StatelessWidget {
  const _LastSyncBanner({required this.sync, required this.rangeTo});

  final TimesheetLastSync? sync;
  final DateTime rangeTo;

  DateTime? get _syncDate {
    final raw = sync?.endSync ?? sync?.batchDate;
    if (raw == null) return null;
    final d = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
    return d == null ? null : _dateOnly(d);
  }

  String? get _syncTime {
    final raw = sync?.endSync;
    if (raw == null || raw.length < 16) return null;
    return raw.substring(11, 16);
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final date = _syncDate;
    final staleDays = date == null ? null : today.difference(date).inDays;
    final stale = staleDays != null && staleDays > 0;
    final unknown = date == null;

    final Color color = unknown
        ? AppColors.slate
        : stale
            ? AppColors.danger
            : AppColors.success;
    final title = unknown
        ? 'تاريخ التحديث غير معروف'
        : stale
            ? 'البيانات غير محدّثة'
            : 'البيانات محدّثة حتى اليوم';
    final relative = switch (staleDays) {
      null => null,
      0 => 'اليوم',
      1 => 'منذ يوم واحد',
      2 => 'منذ يومين',
      final n when n <= 10 => 'منذ $n أيام',
      final n => 'منذ $n يوماً',
    };
    final dateLabel = date == null ? '—' : DateFormat('EEEE d MMMM yyyy', 'ar').format(date);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: stale ? 0.6 : 0.35), width: stale ? 1.4 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FaIcon(
              unknown
                  ? FontAwesomeIcons.circleQuestion
                  : stale
                      ? FontAwesomeIcons.triangleExclamation
                      : FontAwesomeIcons.circleCheck,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'آخر تحديث للبيانات',
                        style: const TextStyle(color: AppColors.slate, fontSize: 12),
                      ),
                    ),
                    if (relative != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          relative,
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [dateLabel, ?_syncTime].join(' · '),
                  style: TextStyle(
                    color: unknown ? AppColors.charcoal : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stale && date != null
                      ? '$title — الأيام بعد ${_fmtDate(date)} لم تُؤرشف بعد ولا تظهر هنا.'
                      : title,
                  style: TextStyle(
                    color: stale ? color : AppColors.charcoal,
                    fontWeight: stale ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

StatusTone _statusToneOf(BadgeTone tone) => switch (tone) {
      BadgeTone.red => StatusTone.danger,
      BadgeTone.orange || BadgeTone.yellow => StatusTone.warning,
      BadgeTone.blue => StatusTone.info,
      BadgeTone.green => StatusTone.success,
      BadgeTone.neutral => StatusTone.neutral,
    };

Color? _rowAccentOf(RowTone? tone) => switch (tone) {
      RowTone.rest => AppColors.slate,
      RowTone.leave => AppColors.success,
      RowTone.absence || RowTone.red => AppColors.danger,
      RowTone.orange => AppColors.warning,
      null => null,
    };

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final TimesheetDay day;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy/MM/dd — EEEE', 'ar');
    final att = day.attendance;
    final car = day.car;
    final subtitle = [?day.dayTypeName, ?day.workType].join(' · ');
    final showPunches = !day.isRest && (day.isWorkDay || !day.punches.isEmpty);
    // سطر البوابة يظهر فقط عندما توجد بيانات سيارة لهذا اليوم.
    final showGate = car.hasData || car.leakMinutes > 0 || car.exemption?.isReal == true;
    final accent = _rowAccentOf(day.tone);

    final card = AppSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateFmt.format(day.date),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.charcoal),
                ),
              ),
              StatusPill(label: att.badge.text, tone: _statusToneOf(att.badge.tone)),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.slate, fontSize: 12.5)),
          ],
          if (showPunches) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _Stamp(label: 'حضور', value: day.punches.checkIn ?? '—', color: AppColors.success),
                const SizedBox(width: 8),
                _Stamp(label: 'الثانية', value: day.punches.breakOut ?? '—'),
                const SizedBox(width: 8),
                _Stamp(label: 'الثالثة', value: day.punches.resume ?? '—'),
                const SizedBox(width: 8),
                _Stamp(label: 'انصراف', value: day.punches.checkOut ?? '—', color: AppColors.info),
              ],
            ),
          ],
          if (showGate) ...[
            const SizedBox(height: 10),
            _GateStrip(car: car),
          ],
        ],
      ),
    );

    if (accent == null) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          card,
          PositionedDirectional(start: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
        ],
      ),
    );
  }
}

/// سطر البوابة المختصر: الحكم + فترة الانقطاع + هامش السماحية.
class _GateStrip extends StatelessWidget {
  const _GateStrip({required this.car});

  final TimesheetCar car;

  @override
  Widget build(BuildContext context) {
    final judgment = car.judgment;
    final tone = _statusToneOf(judgment.badge.tone);
    final violation =
        tone == StatusTone.danger || (tone == StatusTone.warning && judgment.code == 4);
    final iconColor = violation
        ? AppColors.danger
        : tone == StatusTone.success
            ? AppColors.success
            : AppColors.goldDeep;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.carSide, size: 14, color: iconColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'البوابة',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.charcoal, fontSize: 12.5),
                ),
              ),
              StatusPill(label: judgment.badge.text, tone: tone),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Meta(
                  label: 'فترة الانقطاع',
                  value: car.leak,
                  valueColor: car.leakMinutes > 0 ? AppColors.danger : null,
                ),
              ),
              Expanded(
                flex: 2,
                child: _Meta(
                  label: 'هامش / إذن السماحية',
                  value: car.permissionMargin,
                  valueColor: car.exemption?.isReal == true ? AppColors.success : null,
                ),
              ),
            ],
          ),
          if (car.displayText case final text?) ...[
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: AppColors.slate, fontSize: 12, height: 1.4)),
          ],
          if (car.isViolation && car.inGracePeriod) ...[
            const SizedBox(height: 6),
            const Text(
              'ضمن فترة السماح قبل بدء احتساب المخالفات — لا يُحتسب.',
              style: TextStyle(color: AppColors.slate, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, color: valueColor ?? AppColors.charcoal),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.value, this.color = AppColors.slate});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: color)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.charcoal),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});

  final FaIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FaIcon(icon, size: 12, color: AppColors.goldDeep),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.slate, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final RequestErrorInfo error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: FaIcon(FontAwesomeIcons.triangleExclamation, size: 15, color: AppColors.danger),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.charcoal),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      error.message,
                      style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.charcoal),
                    ),
                    if (error.cause case final cause?) ...[
                      const SizedBox(height: 4),
                      SelectableText(cause, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard();

  @override
  Widget build(BuildContext context) {
    return const AppSurface(
      child: Column(
        children: [
          FaIcon(FontAwesomeIcons.database, size: 26, color: AppColors.slate),
          SizedBox(height: 12),
          Text(
            'التايم شيت غير متاح',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w700, height: 1.5),
          ),
          SizedBox(height: 4),
          Text(
            'قاعدة أرشيف الحضور غير متاحة حالياً. حاول لاحقاً.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _DaySkeleton extends StatelessWidget {
  const _DaySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, [double h = 12]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(6)),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [bar(150), const Spacer(), bar(64, 22)]),
            const SizedBox(height: 10),
            bar(90, 10),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: bar(double.infinity, 44)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            bar(double.infinity, 56),
          ],
        ),
      ),
    );
  }
}
