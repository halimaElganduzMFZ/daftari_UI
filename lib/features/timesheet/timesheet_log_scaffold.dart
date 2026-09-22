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

typedef TimesheetHeaderBuilder = Widget Function(
  BuildContext context,
  TimesheetResult? result,
  int shownCount,
);

typedef TimesheetDayBuilder = Widget Function(
  BuildContext context,
  TimesheetDay day,
  TimesheetResult result,
);

/// الهيكل المشترك لشاشتي «حضور وانصراف» و«سجل البوابة»:
/// نفس المصدر (`GET /me/timesheet`) ونفس التحميل/التصفية/الأخطاء،
/// ويختلف الرأس وبطاقة اليوم فقط.
class TimesheetLogScaffold extends StatefulWidget {
  const TimesheetLogScaffold({
    super.key,
    required this.title,
    required this.filterHint,
    required this.emptyText,
    required this.unavailableText,
    required this.headerBuilder,
    required this.dayBuilder,
    this.repository,
    this.pageSize = 8,
  });

  final String title;
  final String filterHint;
  final String emptyText;
  final String unavailableText;
  final TimesheetHeaderBuilder headerBuilder;
  final TimesheetDayBuilder dayBuilder;

  /// للاختبارات؛ الافتراضي `AppServices.timesheet`.
  final TimesheetRepository? repository;
  final int pageSize;

  @override
  State<TimesheetLogScaffold> createState() => _TimesheetLogScaffoldState();
}

class _TimesheetLogScaffoldState extends State<TimesheetLogScaffold> {
  DateTime? _from;
  DateTime? _to;
  TimesheetResult? _result;
  bool _loading = true;
  RequestErrorInfo? _error;
  int _visible = 0;
  int _requestSeq = 0;

  TimesheetRepository get _repo => widget.repository ?? AppServices.timesheet;

  @override
  void initState() {
    super.initState();
    // الافتراضي كما في الصفحة القديمة: من أول الشهر الحالي إلى اليوم.
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year, now.month, 1);
    _visible = widget.pageSize;
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
        _visible = widget.pageSize;
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
    // العنوان الافتراضي في request_error يخص التقديم؛ نعدّله للعرض.
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
    // بلا قيم → يطبّق الخادم افتراضاته ثم نعرض الفترة الناتجة.
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            widget.headerBuilder(context, ready ? result : null, visible.length),
            const SizedBox(height: 16),
            DateRangeFilterBar(
              from: _from,
              to: _to,
              hint: widget.filterHint,
              onFromChanged: _setFrom,
              onToChanged: _setTo,
              onCleared: _clear,
            ),
            const SizedBox(height: 12),
            if (ready) ...[
              if (result.range.clamped)
                _NoteRow(
                  icon: FontAwesomeIcons.circleInfo,
                  text:
                      'الأرشيف يبدأ من ${_fmtDate(result.range.minDate)}؛ تم تعديل بداية الفترة تلقائياً.',
                ),
              if (result.lastSync case final sync? when !sync.isEmpty)
                _NoteRow(
                  icon: FontAwesomeIcons.clockRotateLeft,
                  text: 'آخر تحديث للأرشيف: ${sync.endSync ?? sync.batchDate}',
                ),
            ],
            const SizedBox(height: 4),
            if (_loading) ...[
              const _DaySkeleton(),
              const _DaySkeleton(),
              const _DaySkeleton(),
            ] else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else if (result != null && !result.available)
              _UnavailableCard(text: widget.unavailableText)
            else if (days.isEmpty)
              AppSurface(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    widget.emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.slate),
                  ),
                ),
              )
            else ...[
              Text(
                'عرض ${visible.length} من ${days.length}',
                style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              for (final day in visible) ...[
                widget.dayBuilder(context, day, result!),
                const SizedBox(height: 10),
              ],
              if (hasMore)
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _visible =
                        (_visible + widget.pageSize).clamp(0, days.length);
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
}

String _fmtDate(DateTime d) => DateFormat('yyyy/MM/dd').format(d);

/// تحويل لون الشارة من الخادم إلى لوحة الواجهة.
StatusTone statusToneOf(BadgeTone tone) => switch (tone) {
      BadgeTone.red => StatusTone.danger,
      BadgeTone.orange || BadgeTone.yellow => StatusTone.warning,
      BadgeTone.blue => StatusTone.info,
      BadgeTone.green => StatusTone.success,
      BadgeTone.neutral => StatusTone.neutral,
    };

/// لون شريط التظليل الجانبي للصف حسب تصنيفه القديم.
Color? rowAccentOf(RowTone? tone) => switch (tone) {
      RowTone.rest => AppColors.slate,
      RowTone.leave => AppColors.success,
      RowTone.absence || RowTone.red => AppColors.danger,
      RowTone.orange => AppColors.warning,
      null => null,
    };

/// بطاقة يوم بشريط جانبي ملوّن حسب [accent].
class TimesheetDayCard extends StatelessWidget {
  const TimesheetDayCard({
    super.key,
    required this.child,
    this.accent,
  });

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final card = AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: child,
    );
    if (accent == null) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          card,
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: accent),
          ),
        ],
      ),
    );
  }
}

/// إحصائية صغيرة داخل رأس الشاشة الداكن.
class TimesheetMiniStat extends StatelessWidget {
  const TimesheetMiniStat({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زوج «عنوان / قيمة» صغير داخل البطاقات.
class TimesheetMeta extends StatelessWidget {
  const TimesheetMeta({
    super.key,
    required this.label,
    required this.value,
    this.width = 96,
    this.valueColor,
  });

  final String label;
  final String value;
  final double width;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.slate),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.charcoal,
            ),
          ),
        ],
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
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 12,
                height: 1.4,
              ),
            ),
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
                child: FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 15,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      error.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (error.cause case final cause?) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        cause,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.database,
            size: 26,
            color: AppColors.slate,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
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
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bar(150),
                const Spacer(),
                bar(64, 22),
              ],
            ),
            const SizedBox(height: 10),
            bar(90, 10),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: bar(double.infinity, 44)),
                const SizedBox(width: 8),
                Expanded(child: bar(double.infinity, 44)),
                const SizedBox(width: 8),
                Expanded(child: bar(double.infinity, 44)),
                const SizedBox(width: 8),
                Expanded(child: bar(double.infinity, 44)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
