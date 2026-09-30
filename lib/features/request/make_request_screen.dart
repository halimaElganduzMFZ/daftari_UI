import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/request_date_bounds.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/permission_request.dart';
import '../../data/models/employee.dart';
import '../../data/models/permission_type.dart';
import '../../data/repositories/permission_requests_repository.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_permission_types.dart';
import 'request_error.dart';
import 'widgets/all_regulations_sheet.dart';
import 'widgets/single_regulation_sheet.dart';

/// شاشة تقديم طلب إذن — بديل `makeRequest.php`.
///
/// الأنواع المتاحة، بيانات الدوام والبصمات، والرصيد الشهري تأتي من
/// `GET /me/requests/options?date=` وتتغير مع تغيير التاريخ؛ والإرسال عبر
/// `POST /me/requests` الذي يطبّق كل قواعد النظام القديم ويعيد رسالة عربية.
class MakeRequestScreen extends StatefulWidget {
  const MakeRequestScreen({super.key, this.repository, this.employee});

  /// Target employee for an on-behalf request; the caller's session stays intact.
  final Employee? employee;

  /// للاختبار — الافتراضي [AppServices.permissionRequests].
  final PermissionRequestsRepository? repository;

  @override
  State<MakeRequestScreen> createState() => _MakeRequestScreenState();
}

class _MakeRequestScreenState extends State<MakeRequestScreen> {
  PermissionRequestsRepository get _repo =>
      widget.repository ?? AppServices.permissionRequests;

  DateTime _requestDate = DateTime.now();
  PermissionRequestOptions? _options;
  bool _loading = true;
  Object? _loadError;
  int _loadSeq = 0;

  ApiPermissionType? _selected;
  bool _acceptedRules = false;
  bool _rulesExpanded = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final options = await _repo.options(date: _requestDate);
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _options = options;
        _loading = false;
        // ألغِ الاختيار إن لم يبقَ النوع مسموحاً في التاريخ الجديد.
        if (_selected != null &&
            !options.allowedTypes.any((t) => t.type == _selected!.type)) {
          _selected = null;
          _acceptedRules = false;
          _rulesExpanded = false;
        }
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _loading = false;
        _loadError = e;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = RequestDateBounds.monthBefore(now);
    final last = RequestDateBounds.monthAfter(now);
    final initial = RequestDateBounds.clampToWindow(_requestDate, now: now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'اختر تاريخ الطلب (شهر قبل/بعد)',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked == null || _sameDay(picked, _requestDate)) return;
    setState(() => _requestDate = picked);
    await _loadOptions();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
      ),
    );
  }

  Future<void> _chooseType() async {
    final options = _options;
    if (options == null) return;
    if (options.allowedTypes.isEmpty) {
      _toast(options.blockedReason ?? 'لا توجد أنواع متاحة لهذا التاريخ');
      return;
    }
    final picked = await showModalBottomSheet<ApiPermissionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _TypePickerSheet(options: options, selectedType: _selected?.type),
    );
    if (picked == null) return;
    final rules = regulationsFor(picked);
    setState(() {
      _selected = picked;
      _acceptedRules = rules.points.isEmpty;
      _rulesExpanded = rules.points.isNotEmpty;
    });
  }

  Future<void> _submit() async {
    final selected = _selected;
    final options = _options;
    if (selected == null) {
      _toast('فضلاً اختر نوع الإذن المطلوب');
      return;
    }
    if (options != null && !options.canSubmit) {
      _toast(options.blockedReason ?? 'لا يمكن تقديم الطلب في هذا التاريخ');
      return;
    }
    if (!_acceptedRules) {
      _toast('فضلاً أكّد اطلاعك على الضوابط قبل الإرسال');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _repo.submit(
        type: selected.type,
        date: _requestDate,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccess(result);
      if (!mounted) return;
      setState(() {
        _selected = null;
        _acceptedRules = false;
        _rulesExpanded = false;
      });
      await _loadOptions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showError(e);
      // بعض الأخطاء (مكرر / رصيد) تغيّر ما يُعرض — أعد التحميل بصمت.
      if (mounted) _loadOptions();
    }
  }

  Future<void> _showSuccess(PermissionRequestResult result) {
    final date = DateFormat('yyyy/MM/dd').format(_requestDate);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.circleCheck,
              color: AppColors.success,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(child: Text('تم استلام طلبك')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(height: 1.5, color: AppColors.charcoal),
            ),
            const SizedBox(height: 10),
            Text(
              '«${result.type.name}» بتاريخ $date\n'
              'الحالة: ${result.state} — سيظهر ضمن الطلبات المعلّقة حتى اعتماده.',
              style: const TextStyle(
                height: 1.5,
                fontSize: 12.5,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _showError(Object error) {
    final info = describeRequestError(error);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.circleExclamation,
              color: AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(info.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.message,
              style: const TextStyle(height: 1.55, color: AppColors.charcoal),
            ),
            if (info.cause != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                info.cause!,
                style: const TextStyle(fontSize: 11, color: AppColors.slate),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee ?? AppSession.currentEmployee;
    final dateLabel = DateFormat('yyyy/MM/dd').format(_requestDate);
    final options = _options;
    final selected = _selected;
    final rules = selected == null ? null : regulationsFor(selected);
    final requested = selected == null
        ? null
        : options?.requestedOf(selected.type);
    final canSubmit =
        !_submitting && !_loading && options != null && options.canSubmit;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقديم طلب إذن'),
        actions: [
          IconButton(
            tooltip: 'اللوائح والمخالفات',
            onPressed: () =>
                showAllRegulationsSheet(context, initialTabId: 'permissions'),
            icon: const FaIcon(
              FontAwesomeIcons.bookOpen,
              size: 18,
              color: AppColors.goldDeep,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'حدّد التاريخ أولاً، فالأنواع المتاحة تعتمد على دوامك في ذلك اليوم.',
            style: TextStyle(
              color: AppColors.slate,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _EmployeeStrip(
            name: employee?.fullName ?? 'الموظف',
            number: employee?.employeeNumber ?? '—',
            department: employee?.department ?? '—',
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: '1. تاريخ الطلب',
            subtitle: 'ضمن شهر قبل وشهر بعد اليوم',
          ),
          const SizedBox(height: 10),
          AppSurface(
            onTap: _loading ? null : _pickDate,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.calendarDay,
                    size: 16,
                    color: AppColors.goldDeep,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تاريخ الطلب',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: 6),
                const FaIcon(
                  FontAwesomeIcons.chevronLeft,
                  size: 12,
                  color: AppColors.slate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const _DayInfoSkeleton()
          else if (_loadError != null)
            _StatusCard(
              icon: FontAwesomeIcons.triangleExclamation,
              color: AppColors.danger,
              title: describeRequestError(_loadError!).title,
              message: describeRequestError(_loadError!).message,
              actionLabel: 'إعادة المحاولة',
              onAction: _loadOptions,
            )
          else if (options != null) ...[
            _DayInfoCard(options: options),
            if (!options.canSubmit && options.blockedReason != null) ...[
              const SizedBox(height: 10),
              _StatusCard(
                icon: FontAwesomeIcons.ban,
                color: AppColors.danger,
                title: 'لا يمكن التقديم في هذا التاريخ',
                message: options.blockedReason!,
              ),
            ],
          ],
          const SizedBox(height: 18),
          const SectionHeader(
            title: '2. نوع الإذن',
            subtitle: 'تظهر فقط الأنواع المسموحة لنوع دوامك في هذا اليوم',
          ),
          const SizedBox(height: 10),
          _TypeSelector(
            selected: selected,
            icon: rules?.icon,
            enabled:
                !_loading && options != null && options.allowedTypes.isNotEmpty,
            count: options?.allowedTypes.length,
            onTap: _chooseType,
          ),
          if (requested != null) ...[
            const SizedBox(height: 10),
            _StatusCard(
              icon: FontAwesomeIcons.clockRotateLeft,
              color: AppColors.goldDeep,
              title: 'هذا النوع مطلوب سابقاً في نفس اليوم',
              message: requested.registered
                  ? 'الإذن مسجّل فعلاً في هذا التاريخ، وسيُرفض الطلب المكرر.'
                  : 'لديك طلب من هذا النوع قيد الاعتماد لهذا التاريخ، وسيُرفض الطلب المكرر.',
            ),
          ],
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: rules == null || rules.points.isEmpty
                ? const SizedBox.shrink(key: ValueKey('no-rules'))
                : _CompactRulesCard(
                    key: ValueKey(rules.id),
                    type: rules,
                    expanded: _rulesExpanded,
                    accepted: _acceptedRules,
                    onToggleExpand: () {
                      setState(() => _rulesExpanded = !_rulesExpanded);
                    },
                    onAcceptedChanged: (value) {
                      setState(() => _acceptedRules = value);
                    },
                    onOpenFull: () {
                      showSingleRegulationSheet(context, type: rules);
                    },
                    onOpenAll: () {
                      showAllRegulationsSheet(
                        context,
                        initialTabId: 'permissions',
                      );
                    },
                  ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                      SizedBox(width: 10),
                      Text('تأكيد وإرسال الطلب'),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                showAllRegulationsSheet(context, initialTabId: 'penalties');
              },
              child: const Text(
                'استعراض اللوائح والمخالفات',
                style: TextStyle(
                  color: AppColors.goldDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// يربط نوع الإذن القادم من الـ API بضوابطه وأيقونته في اللوائح الثابتة.
///
/// الأنواع التي لا لائحة لها في التطبيق (9، 10، 16) تحصل على أيقونة عامة
/// وقائمة مواد فارغة، فلا يُطلب تأكيد الاطلاع عليها.
PermissionType regulationsFor(ApiPermissionType type) {
  for (final t in StaticPermissionTypes.all) {
    if (t.id == '${type.type}') {
      return PermissionType(
        id: t.id,
        title: type.name.isEmpty ? t.title : type.name,
        icon: t.icon,
        points: t.points,
        fullText: t.fullText,
      );
    }
  }
  return PermissionType(
    id: '${type.type}',
    title: type.name,
    icon: switch (type.type) {
      9 || 10 => FontAwesomeIcons.fingerprint,
      16 => FontAwesomeIcons.briefcase,
      _ => FontAwesomeIcons.idBadge,
    },
    points: const [],
    fullText: '',
  );
}

class _EmployeeStrip extends StatelessWidget {
  const _EmployeeStrip({
    required this.name,
    required this.number,
    required this.department,
  });

  final String name;
  final String number;
  final String department;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF7F1E6), Color(0xFFEFEFEA), Color(0xFFE8E8E4)],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.user,
              size: 16,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$number • $department',
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

/// بطاقة معلومات اليوم: الدوام، البصمات، والرصيد الشهري.
class _DayInfoCard extends StatelessWidget {
  const _DayInfoCard({required this.options});

  final PermissionRequestOptions options;

  @override
  Widget build(BuildContext context) {
    final schedule = options.schedule;
    final punches = options.punches;
    final quota = options.quota;

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.businessTime,
                size: 14,
                color: AppColors.goldDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule.status == ScheduleStatus.ok
                      ? 'دوامك: ${schedule.profileLabel}'
                            '${schedule.hoursLabel == null ? '' : ' (${schedule.hoursLabel})'}'
                      : schedule.status == ScheduleStatus.unavailable
                      ? 'نظام البصمة غير متاح حالياً'
                      : 'لا يوجد سجل دوام لهذا التاريخ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          if (schedule.scheduleName != null || schedule.fromToday) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Text(
                [
                  ?schedule.scheduleName,
                  if (schedule.fromToday)
                    'حسب جدول اليوم لعدم وجود سجل للتاريخ بعد',
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: FontAwesomeIcons.fingerprint,
                label: punches == null || punches.isEmpty
                    ? 'لا بصمات مسجّلة'
                    : punches.entries.map((e) => '${e.$1} ${e.$2}').join(' · '),
              ),
              _InfoChip(
                icon: FontAwesomeIcons.gaugeHigh,
                label:
                    'أذونات التأخير/الخروج المبكر: ${quota.used}/${quota.limit}'
                    '${quota.pending > 0 ? ' (+${quota.pending} معلّق)' : ''}',
                highlight: quota.exhausted,
              ),
              if (options.requestedTypes.isNotEmpty)
                _InfoChip(
                  icon: FontAwesomeIcons.clockRotateLeft,
                  label:
                      'مطلوب في هذا اليوم: '
                      '${options.requestedTypes.map((t) => t.name).join('، ')}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final FaIconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.danger : AppColors.slate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.danger : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayInfoSkeleton extends StatelessWidget {
  const _DayInfoSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(180),
          const SizedBox(height: 10),
          Row(children: [bar(120), const SizedBox(width: 8), bar(140)]),
          const SizedBox(height: 10),
          const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'جاري تحميل بيانات اليوم…',
                style: TextStyle(fontSize: 12, color: AppColors.slate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final FaIconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.charcoal,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
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

/// زر اختيار أنيق يعرض النوع المحدد فقط بدل شبكة طويلة.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.icon,
    required this.enabled,
    required this.count,
    required this.onTap,
  });

  final ApiPermissionType? selected;
  final FaIconData? icon;
  final bool enabled;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: hasSelection ? AppColors.goldSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasSelection ? AppColors.gold : AppColors.line,
              width: hasSelection ? 1.4 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(
                    icon ?? FontAwesomeIcons.listUl,
                    size: 17,
                    color: enabled ? AppColors.goldDeep : AppColors.slate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelection
                            ? selected!.name
                            : enabled
                            ? 'اضغط لاختيار نوع الإذن'
                            : 'بانتظار بيانات اليوم…',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: hasSelection
                              ? AppColors.goldDeep
                              : AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasSelection
                            ? 'يمكنك تغيير النوع في أي وقت'
                            : count == null
                            ? 'الأنواع تعتمد على دوامك في التاريخ المحدد'
                            : '$count ${count == 1 ? 'نوع متاح' : 'أنواع متاحة'} لهذا اليوم',
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.gold : AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    hasSelection ? 'تغيير' : 'اختيار',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ضوابط قابلة للطي — لا تسرق ارتفاع الصفحة.
class _CompactRulesCard extends StatelessWidget {
  const _CompactRulesCard({
    super.key,
    required this.type,
    required this.expanded,
    required this.accepted,
    required this.onToggleExpand,
    required this.onAcceptedChanged,
    required this.onOpenFull,
    required this.onOpenAll,
  });

  final PermissionType type;
  final bool expanded;
  final bool accepted;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onOpenFull;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'ضوابط',
                    style: TextStyle(
                      color: AppColors.goldDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    expanded
                        ? 'إخفاء الملخص'
                        : 'عرض ملخص سريع (${type.points.length} مواد)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  for (final point in type.points.take(2)) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              point.article,
                              style: const TextStyle(
                                color: AppColors.goldDeep,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              point.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.charcoal,
                                fontSize: 12.5,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      TextButton(
                        onPressed: onOpenFull,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldDeep,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'اللائحة الكاملة',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onOpenAll,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.slate,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'كل اللوائح',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => onAcceptedChanged(!accepted),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accepted ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: accepted ? AppColors.gold : AppColors.line,
                        width: 1.4,
                      ),
                    ),
                    child: accepted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'اطّلعت على الضوابط وأتعهّد بالالتزام بها',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ورقة اختيار الأنواع المسموحة في التاريخ المحدد.
class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet({required this.options, this.selectedType});

  final PermissionRequestOptions options;
  final int? selectedType;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final types = options.allowedTypes;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.listCheck,
                      size: 16,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر نوع الإذن',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                            ),
                          ),
                          Text(
                            '${options.schedule.profileLabel} · ${types.length} أنواع متاحة',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: types.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (context, index) {
                    final type = types[index];
                    final rules = regulationsFor(type);
                    final selected = type.type == selectedType;
                    final requested = options.requestedOf(type.type);
                    return Material(
                      color: selected
                          ? AppColors.goldSoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(type),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? AppColors.gold : AppColors.line,
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FaIcon(
                                    rules.icon,
                                    size: 18,
                                    color: selected
                                        ? AppColors.goldDeep
                                        : AppColors.slate,
                                  ),
                                  const Spacer(),
                                  if (requested != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        requested.statusLabel,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.goldDeep,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                type.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.2,
                                  height: 1.3,
                                  color: selected
                                      ? AppColors.goldDeep
                                      : AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
