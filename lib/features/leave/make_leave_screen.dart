import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/document_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/request_date_bounds.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/leave_kind.dart';
import '../../data/models/leave_request_form.dart';
import '../../data/models/request_attachment.dart';
import '../../data/repositories/leave_requests_repository.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_leave_kinds.dart';
import '../request/request_error.dart';
import '../request/widgets/all_regulations_sheet.dart';
import '../request/widgets/single_regulation_sheet.dart';

/// شاشة تقديم طلب إجازة — بديل `Taking_a_day_off.php`.
///
/// - الأنواع وتوفّرها والأرصدة والأهلية من `GET /me/leave/requests/options?date=`
///   (تُعاد قراءتها عند تغيير تاريخ البداية لأن الدوام يحدد طريقة عدّ الأيام).
/// - معاينة الأيام المحسوبة والرصيد قبل الإرسال من `GET /me/leave/requests/preview`.
/// - الإرسال عبر `POST /me/leave/requests` (multipart عند وجود مستند دراسي).
class MakeLeaveScreen extends StatefulWidget {
  const MakeLeaveScreen({super.key, this.onSubmitted, this.repository});

  final VoidCallback? onSubmitted;

  /// للاختبار — الافتراضي [AppServices.leaveRequests].
  final LeaveRequestsRepository? repository;

  @override
  State<MakeLeaveScreen> createState() => _MakeLeaveScreenState();
}

class _MakeLeaveScreenState extends State<MakeLeaveScreen> {
  LeaveRequestsRepository get _repo =>
      widget.repository ?? AppServices.leaveRequests;

  LeaveRequestOptions? _options;
  bool _loading = true;
  Object? _loadError;
  int _loadSeq = 0;

  LeaveKindOption? _selected;
  DateTime? _startDate;
  DateTime? _endDate;
  LeaveLocation? _location;
  final _reasonController = TextEditingController();
  RequestAttachment? _attachment;

  LeavePlan? _plan;
  Object? _planError;
  bool _previewing = false;
  Timer? _previewDebounce;
  int _previewSeq = 0;

  bool _acceptedRules = false;
  bool _rulesExpanded = false;
  bool _submitting = false;
  bool _fileAccessHintShown = false;
  bool _pickingAttachment = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  // ─── تحميل الخيارات ─────────────────────────────────────────────────────

  Future<void> _loadOptions() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final options = await _repo.options(date: _startDate);
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _options = options;
        _loading = false;
        // حدّث النوع المختار بنسخته الجديدة (التوفّر قد يتغيّر).
        if (_selected != null) {
          _selected = options.kindByCode(_selected!.code);
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

  // ─── المعاينة ───────────────────────────────────────────────────────────

  void _schedulePreview() {
    _previewDebounce?.cancel();
    final kind = _selected;
    final from = _startDate;
    if (kind == null || from == null) {
      setState(() {
        _plan = null;
        _planError = null;
        _previewing = false;
      });
      return;
    }
    if (!kind.fields.endDateFixed && _endDate == null) {
      // ننتظر تاريخ النهاية للأنواع القابلة للتعديل.
      setState(() {
        _plan = null;
        _planError = null;
      });
      return;
    }
    setState(() => _previewing = true);
    _previewDebounce = Timer(const Duration(milliseconds: 350), _runPreview);
  }

  Future<void> _runPreview() async {
    final kind = _selected;
    final from = _startDate;
    if (kind == null || from == null) return;
    final seq = ++_previewSeq;
    try {
      final plan = await _repo.preview(
        kind: kind.code,
        from: from,
        to: kind.fields.endDateFixed ? null : _endDate,
      );
      if (!mounted || seq != _previewSeq) return;
      setState(() {
        _plan = plan;
        _planError = null;
        _previewing = false;
      });
    } catch (e) {
      if (!mounted || seq != _previewSeq) return;
      setState(() {
        _plan = null;
        _planError = e;
        _previewing = false;
      });
    }
  }

  // ─── الإدخال ────────────────────────────────────────────────────────────

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
    final picked = await showModalBottomSheet<LeaveKindOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaveTypePickerSheet(
        kinds: options.kinds,
        selectedCode: _selected?.code,
      ),
    );
    if (picked == null) return;
    final rules = leaveRegulationsFor(picked);
    setState(() {
      _selected = picked;
      _acceptedRules = rules.points.isEmpty;
      _rulesExpanded = rules.points.isNotEmpty;
      _attachment = null;
      _reasonController.clear();
      _location = picked.fields.locationEnabled && picked.isAnnual
          ? LeaveLocation.inside
          : null;
      _syncEndDate();
    });
    _schedulePreview();
    if (picked.fields.attachmentRequired) {
      await _ensureFileAccessHint();
    }
  }

  /// يضبط تاريخ النهاية للأنواع ذات المدة الثابتة.
  void _syncEndDate() {
    final kind = _selected;
    final start = _startDate;
    if (kind == null || start == null) return;
    if (kind.fields.endDateFixed && kind.fixedDays != null) {
      _endDate = start.add(Duration(days: kind.fixedDays! - 1));
    } else if (_endDate != null && _endDate!.isBefore(start)) {
      _endDate = start;
    }
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final first = RequestDateBounds.monthBefore(now);
    final last = RequestDateBounds.monthAfter(now);
    final initial = RequestDateBounds.clampToWindow(_startDate ?? now, now: now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'تاريخ بداية الإجازة (شهر قبل/بعد)',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked == null) return;
    final changed = _startDate == null || !_sameDay(picked, _startDate!);
    setState(() {
      _startDate = picked;
      if (_endDate == null && _selected != null && !_selected!.fields.endDateFixed) {
        _endDate = picked;
      }
      _syncEndDate();
    });
    _schedulePreview();
    // الدوام (وبالتالي طريقة العدّ وقفل الشهر) يعتمد على تاريخ البداية.
    if (changed) await _loadOptions();
  }

  Future<void> _pickEnd() async {
    if (_selected?.fields.endDateFixed == true) return;
    final now = DateTime.now();
    final windowFirst = RequestDateBounds.monthBefore(now);
    final first = _startDate != null && _startDate!.isAfter(windowFirst)
        ? _startDate!
        : windowFirst;
    // قيد "شهر قبل/بعد" ينطبق على البداية فقط؛ الـ API يقبل نهاية حتى سنة من البداية.
    final last = first.add(const Duration(days: 365));
    final initial = _endDate ?? _startDate ?? now;
    final safeInitial =
        initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial);
    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: first,
      lastDate: last,
      helpText: 'تاريخ نهاية الإجازة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
    _schedulePreview();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _ensureFileAccessHint() async {
    if (_fileAccessHintShown) return;
    _fileAccessHintShown = true;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('الوصول إلى ملفات الجهاز'),
          content: Text(
            kIsWeb
                ? 'لرفع مستند الإجازة الدراسية سيفتح المتصفح نافذة اختيار من ملفات جهازك.\n'
                    'اضغط «متابعة» ثم اختر الملف (PDF أو Word أو صورة).\n'
                    'ملاحظة: المتصفح لا يمنح صلاحية دائمة مسبقاً — الاختيار يتم عند كل إرفاق بموافقتك.'
                : 'يحتاج التطبيق إذن الوصول إلى الملفات لإرفاق مستند الإجازة الدراسية.\n'
                    'عند ظهور طلب الصلاحية اضغط «سماح» ثم اختر الملف.',
            style: const TextStyle(height: 1.5, color: AppColors.slate),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('متابعة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAttachment() async {
    await _ensureFileAccessHint();
    if (!mounted) return;
    setState(() => _pickingAttachment = true);
    try {
      final picked = await DocumentPicker.pickStudyDocument();
      if (!mounted) return;
      if (picked == null) {
        _toast('لم يتم اختيار ملف');
        return;
      }
      final size = picked.size ?? picked.bytes?.length ?? 0;
      if (size > LeaveRequestsRepository.attachmentMaxBytes) {
        _toast('حجم الملف كبير جداً! الحد الأقصى هو 5 ميجابايت');
        return;
      }
      if (picked.bytes == null || picked.bytes!.isEmpty) {
        _toast('تعذّر قراءة محتوى الملف، اختر ملفاً آخر');
        return;
      }
      setState(() {
        _attachment = RequestAttachment(
          fileName: picked.name,
          fileSizeBytes: size,
          extension: picked.extension,
          bytes: picked.bytes,
          title: 'مستند الإجازة الدراسية',
          uploadedAt: DateTime.now(),
        );
      });
      _toast('تم إرفاق: ${picked.name}');
    } catch (e) {
      if (!mounted) return;
      _toast('تعذّر فتح مستعرض الملفات. حاول مرة أخرى أو اسمح بالوصول من إعدادات المتصفح.');
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  // ─── الإرسال ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final kind = _selected;
    final options = _options;
    if (kind == null) {
      _toast('فضلاً اختر نوع الإجازة');
      return;
    }
    if (options?.blockedReason != null) {
      _toast(options!.blockedReason!);
      return;
    }
    if (!kind.available) {
      _toast(kind.unavailableLabel ?? 'هذا النوع غير متاح حالياً');
      return;
    }
    if (_startDate == null) {
      _toast('فضلاً حدّد تاريخ البداية');
      return;
    }
    if (!kind.fields.endDateFixed && _endDate == null) {
      _toast('فضلاً حدّد تاريخ النهاية');
      return;
    }
    final reason = _reasonController.text.trim();
    if (kind.fields.reasonRequired && reason.isEmpty) {
      _toast('فضلاً اكتب سبب الإجازة الطارئة');
      return;
    }
    if (reason.length > LeaveRequestsRepository.reasonMaxLength) {
      _toast('السبب طويل جداً (الحد ${LeaveRequestsRepository.reasonMaxLength} حرفاً)');
      return;
    }
    if (kind.fields.attachmentRequired && _attachment == null) {
      _toast('فضلاً أرفق المستند المطلوب');
      return;
    }
    if (!_acceptedRules) {
      _toast('فضلاً أكّد اطلاعك على الضوابط قبل الإرسال');
      return;
    }

    setState(() => _submitting = true);
    try {
      final attachment = _attachment;
      final result = await _repo.submit(
        kind: kind.code,
        from: _startDate!,
        to: kind.fields.endDateFixed ? null : _endDate,
        reason: reason.isEmpty ? null : reason,
        location: kind.fields.locationEnabled ? _location : null,
        attachment: attachment == null || attachment.bytes == null
            ? null
            : LeaveAttachmentUpload(
                fileName: attachment.fileName,
                bytes: attachment.bytes!,
                contentType: _contentTypeFor(attachment),
              ),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccess(result);
      if (!mounted) return;
      widget.onSubmitted?.call();
      if (widget.onSubmitted == null) {
        setState(() {
          _selected = null;
          _acceptedRules = false;
          _rulesExpanded = false;
          _startDate = null;
          _endDate = null;
          _location = null;
          _reasonController.clear();
          _attachment = null;
          _plan = null;
          _planError = null;
        });
        await _loadOptions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showError(e);
      if (mounted) {
        _loadOptions();
        _schedulePreview();
      }
    }
  }

  static String? _contentTypeFor(RequestAttachment a) => switch (a.kind) {
        AttachmentKind.pdf => 'application/pdf',
        AttachmentKind.image =>
          a.extensionLabel == 'PNG' ? 'image/png' : 'image/jpeg',
        AttachmentKind.word => a.extensionLabel == 'DOC'
            ? 'application/msword'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        AttachmentKind.other => null,
      };

  Future<void> _showSuccess(LeaveRequestResult result) {
    final plan = result.plan;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.success, size: 22),
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
              [
                if (plan.days > 0) 'الأيام المحسوبة: ${_fmtDays(plan.days)}',
                if (result.requests.length > 1)
                  'عدد السجلات: ${result.requests.length}',
                if (result.attachment != null)
                  'المرفق: ${result.attachment!.fileName}',
                'الحالة: ${result.state} — سيظهر ضمن الطلبات المعلّقة حتى اعتماده.',
              ].join('\n'),
              style: const TextStyle(
                height: 1.55,
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

  static String _fmtDays(double d) {
    final text = d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
    return '$text ${d == 1 ? 'يوم' : 'أيام'}';
  }

  // ─── العرض ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final options = _options;
    final kind = _selected;
    final rules = kind == null ? null : leaveRegulationsFor(kind);
    final blocked = options?.blockedReason;
    final canSubmit = !_submitting &&
        !_loading &&
        options != null &&
        blocked == null &&
        (kind?.available ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقديم طلب إجازة'),
        actions: [
          IconButton(
            tooltip: 'اللوائح والمخالفات',
            onPressed: () => showAllRegulationsSheet(
              context,
              initialTabId: 'leaves',
            ),
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
          Text(
            employee == null
                ? 'اختر النوع، راجع الضوابط، ثم حدّد الفترة.'
                : '${employee.fullName} — اختر النوع، راجع الضوابط، ثم حدّد الفترة.',
            style: const TextStyle(
              color: AppColors.slate,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading && options == null)
            const _LoadingCard(label: 'جاري تحميل الأنواع والأرصدة…')
          else if (_loadError != null && options == null)
            _StatusCard(
              icon: FontAwesomeIcons.triangleExclamation,
              color: AppColors.danger,
              title: describeRequestError(_loadError!).title,
              message: describeRequestError(_loadError!).message,
              actionLabel: 'إعادة المحاولة',
              onAction: _loadOptions,
            )
          else if (options != null) ...[
            _BalancesCard(balances: options.balances, loading: _loading),
            if (blocked != null) ...[
              const SizedBox(height: 10),
              _StatusCard(
                icon: FontAwesomeIcons.ban,
                color: AppColors.danger,
                title: 'لا يمكن تقديم طلب إجازة',
                message: blocked,
              ),
            ],
          ],
          const SizedBox(height: 18),
          const SectionHeader(
            title: '1. نوع الإجازة',
            subtitle: 'الأنواع غير المتاحة لك تظهر معطّلة مع السبب',
          ),
          const SizedBox(height: 10),
          _TypeSelector(
            selected: kind,
            icon: rules?.icon,
            enabled: options != null,
            onTap: _chooseType,
          ),
          if (kind != null && !kind.available) ...[
            const SizedBox(height: 10),
            _StatusCard(
              icon: FontAwesomeIcons.circleInfo,
              color: AppColors.goldDeep,
              title: 'هذا النوع غير متاح حالياً',
              message: kind.unavailableLabel ?? 'لا يمكن تقديم هذا النوع الآن.',
            ),
          ],
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: rules == null || rules.points.isEmpty
                ? const SizedBox.shrink(key: ValueKey('no-rules'))
                : _CompactRulesCard(
                    key: ValueKey(rules.id),
                    kind: rules,
                    expanded: _rulesExpanded,
                    accepted: _acceptedRules,
                    onToggleExpand: () {
                      setState(() => _rulesExpanded = !_rulesExpanded);
                    },
                    onAcceptedChanged: (value) {
                      setState(() => _acceptedRules = value);
                    },
                    onOpenFull: () {
                      showRegulationDetailSheet(
                        context,
                        title: rules.title,
                        icon: rules.icon,
                        points: rules.points,
                        fullText: rules.fullText,
                        allRegsTabId: 'leaves',
                      );
                    },
                    onOpenAll: () {
                      showAllRegulationsSheet(
                        context,
                        initialTabId: 'leaves',
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: '2. تفاصيل الطلب',
            subtitle: 'الفترة والحقول الإضافية حسب نوع الإجازة',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'من تاريخ',
                  value: _startDate,
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  label: 'إلى تاريخ',
                  value: _endDate,
                  onTap: _pickEnd,
                  locked: kind?.fields.endDateFixed == true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (options != null && _startDate != null)
            _ShiftHint(shift: options.shift, loading: _loading),
          const SizedBox(height: 8),
          _PlanCard(
            plan: _plan,
            error: _planError,
            loading: _previewing,
            fixedDays: kind?.fixedDays,
            onRetry: _schedulePreview,
          ),
          if (kind?.fields.locationEnabled == true) ...[
            const SizedBox(height: 10),
            _LocationPicker(
              value: _location,
              onChanged: (v) => setState(() => _location = v),
            ),
          ],
          if (kind != null) ...[
            const SizedBox(height: 10),
            AppSurface(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: TextField(
                controller: _reasonController,
                maxLines: 3,
                minLines: 2,
                maxLength: LeaveRequestsRepository.reasonMaxLength,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    currentLength > 1200
                        ? Text(
                            '$currentLength / $maxLength',
                            style: const TextStyle(fontSize: 11, color: AppColors.slate),
                          )
                        : null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: kind.fields.reasonRequired
                      ? 'سبب الإجازة الطارئة (مطلوب)…'
                      : 'سبب الإجازة (اختياري)…',
                  hintStyle: const TextStyle(color: AppColors.slate),
                ),
              ),
            ),
          ],
          if (kind?.fields.attachmentRequired == true) ...[
            const SizedBox(height: 10),
            _AttachmentHint(),
            const SizedBox(height: 8),
            _AttachmentTile(
              fileName: _attachment?.fileName,
              fileSize: _attachment?.fileSizeBytes,
              picking: _pickingAttachment,
              onPick: _pickingAttachment ? null : _pickAttachment,
              onOpen: _attachment == null
                  ? null
                  : () => AttachmentViewer.show(
                        context,
                        attachment: _attachment!,
                        subtitle: kind?.label,
                      ),
              onClear: () => setState(() => _attachment = null),
            ),
          ],
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

/// يربط نوع الإجازة القادم من الـ API بضوابطه وأيقونته في اللوائح الثابتة.
LeaveKind leaveRegulationsFor(LeaveKindSummary kind) {
  final staticId = switch (kind.code) {
    'ANNUAL_LEAVE' => 'annual',
    'EMERGENCY_LEAVE' => 'emergency',
    'STUDY_LEAVE' => 'study',
    'MATERNITY_LEAVE' => 'maternity',
    'IDDAH_LEAVE' => 'idda',
    'HAJJ_LEAVE' => 'hajj',
    'MARRIAGE_LEAVE' => 'marriage',
    _ => null,
  };
  for (final k in StaticLeaveKinds.all) {
    if (k.id == staticId) {
      return LeaveKind(
        id: kind.code,
        title: kind.label,
        subtitle: k.subtitle,
        icon: k.icon,
        points: k.points,
        fullText: k.fullText,
        fixedDays: kind.fixedDays,
      );
    }
  }
  return LeaveKind(
    id: kind.code,
    title: kind.label,
    subtitle: kind.category == LeaveKindCategory.exemption
        ? 'لمسؤولي الهياكل الرئيسية — بدون خصم أيام'
        : '',
    icon: kind.category == LeaveKindCategory.exemption
        ? FontAwesomeIcons.doorOpen
        : FontAwesomeIcons.umbrellaBeach,
    points: const [],
    fullText: '',
    fixedDays: kind.fixedDays,
  );
}

// ─── Type picker ─────────────────────────────────────────────────────────────

class _LeaveTypePickerSheet extends StatelessWidget {
  const _LeaveTypePickerSheet({required this.kinds, this.selectedCode});

  final List<LeaveKindOption> kinds;
  final String? selectedCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'اختر نوع الإجازة',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const FaIcon(
                    FontAwesomeIcons.xmark,
                    size: 16,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              itemCount: kinds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final k = kinds[i];
                final rules = leaveRegulationsFor(k);
                final selected = k.code == selectedCode;
                final enabled = k.available;
                final subtitle = enabled
                    ? [
                        if (k.fixedDays != null) '${k.fixedDays} يوماً — مدة ثابتة',
                        if (rules.subtitle.isNotEmpty) rules.subtitle,
                        if (k.pendingRequests > 0) '${k.pendingRequests} طلب معلّق',
                      ].join(' · ')
                    : (k.unavailableLabel ?? 'غير متاح');
                return Opacity(
                  opacity: enabled ? 1 : 0.55,
                  child: Material(
                    color: selected
                        ? AppColors.goldSoft.withValues(alpha: 0.85)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, k),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.goldSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: FaIcon(
                                  enabled ? rules.icon : FontAwesomeIcons.lock,
                                  size: 17,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    k.label,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? AppColors.goldDeep
                                          : AppColors.charcoal,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: enabled
                                            ? AppColors.slate
                                            : AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (selected)
                              const FaIcon(
                                FontAwesomeIcons.circleCheck,
                                size: 16,
                                color: AppColors.goldDeep,
                              )
                            else
                              const FaIcon(
                                FontAwesomeIcons.chevronLeft,
                                size: 12,
                                color: AppColors.slate,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info cards ──────────────────────────────────────────────────────────────

class _BalancesCard extends StatelessWidget {
  const _BalancesCard({required this.balances, required this.loading});

  final LeaveBalances balances;
  final bool loading;

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final annual = balances.annualBalance;
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _BalanceTile(
              icon: FontAwesomeIcons.calendarCheck,
              label: 'رصيد السنوية',
              value: annual == null ? '—' : '$annual يوم',
              hint: annual == null
                  ? switch (balances.annualUnavailableReason) {
                      'MISSING_START_DATE' => 'لا يوجد تاريخ بداية عمل',
                      'INACTIVE' => 'خارج الخدمة',
                      _ => 'غير متاح',
                    }
                  : (balances.annualPending ?? 0) > 0
                      ? '${balances.annualPending} طلب معلّق'
                      : 'حتى ${balances.asOf}',
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          Expanded(
            child: _BalanceTile(
              icon: FontAwesomeIcons.bolt,
              label: 'رصيد الطارئة',
              value: '${_n(balances.emergencyRemaining)} يوم',
              hint: balances.emergencyPending > 0
                  ? '${balances.emergencyPending} طلب معلّق'
                  : 'من ${balances.emergencyAllowance} سنوياً',
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 13, color: AppColors.goldDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldDeep,
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftHint extends StatelessWidget {
  const _ShiftHint({required this.shift, required this.loading});

  final LeaveShiftInfo shift;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = loading
        ? 'جاري قراءة دوام تاريخ البداية…'
        : shift.isUnavailable
            ? 'نظام البصمة غير متاح — لا يمكن تحديد طريقة عدّ الأيام الآن'
            : !shift.isOk
                ? 'لا يوجد سجل دوام لتاريخ البداية — ${shift.countingHint}'
                : '${shift.shiftLabel}'
                    '${shift.scheduleName == null ? '' : ' (${shift.scheduleName})'}'
                    ' — ${shift.countingHint}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: FaIcon(
            FontAwesomeIcons.businessTime,
            size: 12,
            color: AppColors.slate,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
        ),
      ],
    );
  }
}

/// نتيجة المعاينة: الأيام المحسوبة، طريقة العدّ، تاريخ النهاية الفعلي، والرصيد.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.error,
    required this.loading,
    required this.fixedDays,
    required this.onRetry,
  });

  final LeavePlan? plan;
  final Object? error;
  final bool loading;
  final int? fixedDays;
  final VoidCallback onRetry;

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _LoadingCard(label: 'جاري حساب الأيام والرصيد…');
    }
    final err = error;
    if (err != null) {
      final info = describeRequestError(err);
      final isNetwork = err is ApiException && err.isNetwork;
      return _StatusCard(
        icon: FontAwesomeIcons.triangleExclamation,
        color: AppColors.danger,
        title: info.title,
        message: info.message,
        actionLabel: isNetwork ? 'إعادة المحاولة' : null,
        onAction: isNetwork ? onRetry : null,
      );
    }
    final p = plan;
    if (p == null) {
      return const Text(
        'تواريخ البداية ضمن شهر قبل وشهر بعد اليوم · تُحسب الأيام والرصيد تلقائياً بعد تحديد الفترة',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.slate,
        ),
      );
    }
    final balance = p.balance;
    final fmt = DateFormat('yyyy/MM/dd');
    String d(String iso) {
      final parsed = DateTime.tryParse(iso);
      return parsed == null ? iso : fmt.format(parsed);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.goldSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.calculator,
                size: 14,
                color: AppColors.goldDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.kind.category == LeaveKindCategory.exemption
                      ? 'إعفاء من ${d(p.from)} إلى ${d(p.to)} — بدون خصم أيام'
                      : 'المدة المحسوبة: ${_n(p.days)} ${p.days == 1 ? 'يوم' : 'أيام'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: Text(
              [
                'من ${d(p.from)} إلى ${d(p.to)} · ${p.methodLabel}'
                    '${fixedDays != null ? ' ($fixedDays يوماً)' : ''}',
                if (p.workShifts != null) 'ورديات عمل ضمن الفترة: ${p.workShifts}',
                if (p.blocks.length > 1) 'سيُسجّل الطلب في ${p.blocks.length} سجلات',
              ].join('\n'),
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (p.endExtended) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 12,
                  color: AppColors.goldDeep,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'طلبت حتى ${d(p.requestedTo)} لكن نوع دوامك يمدّد النهاية إلى ${d(p.to)}.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDeep,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (balance != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                FaIcon(
                  balance.sufficient
                      ? FontAwesomeIcons.circleCheck
                      : FontAwesomeIcons.circleXmark,
                  size: 13,
                  color: balance.sufficient ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'الرصيد ${balance.kind == 'annual' ? 'السنوي' : 'الطارئ'} '
                    'بتاريخ البداية ${_n(balance.available)} − ${_n(balance.required)} '
                    '= ${_n(balance.remaining)} يوم',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: balance.sufficient ? AppColors.charcoal : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({required this.value, required this.onChanged});

  final LeaveLocation? value;
  final ValueChanged<LeaveLocation?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.locationDot,
            size: 15,
            color: AppColors.goldDeep,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'مكان الإجازة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
          ),
          SegmentedButton<LeaveLocation>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            segments: [
              for (final loc in LeaveLocation.values)
                ButtonSegment(value: loc, label: Text(loc.label)),
            ],
            selected: {?value},
            onSelectionChanged: (set) =>
                onChanged(set.isEmpty ? null : set.first),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
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

// ─── Small widgets ───────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final LeaveKindOption? selected;
  final FaIconData? icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = selected != null;
    return AppSurface(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon ?? FontAwesomeIcons.umbrellaBeach,
                size: 17,
                color: enabled ? AppColors.goldDeep : AppColors.slate,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  has ? 'نوع الإجازة' : 'اختر نوع الإجازة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  has
                      ? selected!.label
                      : enabled
                          ? 'اضغط للاختيار من القائمة'
                          : 'بانتظار تحميل الأنواع…',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: has ? AppColors.charcoal : AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.chevronDown,
            size: 13,
            color: AppColors.slate,
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'اختر'
        : DateFormat('yyyy/MM/dd').format(value!);
    return AppSurface(
      onTap: locked ? null : onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              FaIcon(
                locked ? FontAwesomeIcons.lock : FontAwesomeIcons.calendarDay,
                size: 13,
                color: AppColors.goldDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: value == null ? AppColors.slate : AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 14,
            color: AppColors.goldDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              kIsWeb
                  ? 'اضغط «اختيار من الجهاز» لفتح ملفات الكمبيوتر واختيار المستند (PDF / Word / صورة) بحد 5 م.ب.'
                  : 'سيُطلب إذن الوصول للملفات عند أول إرفاق، ثم يمكنك اختيار المستند من الجهاز (بحد 5 م.ب).',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.fileName,
    required this.onPick,
    required this.onClear,
    this.onOpen,
    this.fileSize,
    this.picking = false,
  });

  final String? fileName;
  final int? fileSize;
  final bool picking;
  final VoidCallback? onPick;
  final VoidCallback? onOpen;
  final VoidCallback onClear;

  String get _sizeLabel {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return ' • ${kb.toStringAsFixed(0)} ك.ب';
    return ' • ${(kb / 1024).toStringAsFixed(1)} م.ب';
  }

  @override
  Widget build(BuildContext context) {
    final has = fileName != null;
    return AppSurface(
      onTap: picking ? null : (has ? onOpen : onPick),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (picking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            FaIcon(
              has ? FontAwesomeIcons.filePdf : FontAwesomeIcons.folderOpen,
              size: 17,
              color: has ? const Color(0xFF9B3B3B) : AppColors.goldDeep,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  picking
                      ? 'جاري فتح مستعرض الملفات…'
                      : has
                          ? fileName!
                          : 'اختيار من الجهاز — مستند الإجازة الدراسية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: has ? AppColors.charcoal : AppColors.slate,
                  ),
                ),
                if (has)
                  Text(
                    'اضغط للمعاينة$_sizeLabel',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.goldDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (!picking)
                  const Text(
                    'الأنواع: PDF, DOC, DOCX, JPG, PNG',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate,
                    ),
                  ),
              ],
            ),
          ),
          if (has) ...[
            IconButton(
              onPressed: onOpen,
              tooltip: 'فتح المرفق',
              icon: const Icon(
                Icons.visibility_rounded,
                color: AppColors.goldDeep,
              ),
            ),
            IconButton(
              onPressed: onPick,
              tooltip: 'تغيير الملف',
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.slate,
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: 'إزالة المرفق',
              icon: const FaIcon(
                FontAwesomeIcons.trashCan,
                size: 14,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactRulesCard extends StatelessWidget {
  const _CompactRulesCard({
    super.key,
    required this.kind,
    required this.expanded,
    required this.accepted,
    required this.onToggleExpand,
    required this.onAcceptedChanged,
    required this.onOpenFull,
    required this.onOpenAll,
  });

  final LeaveKind kind;
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        : 'عرض ملخص سريع (${kind.points.length} مواد)',
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
                  for (final point in kind.points.take(2)) ...[
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
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldDeep,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              point.text,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.slate,
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
                        child: const Text('اللائحة الكاملة'),
                      ),
                      TextButton(
                        onPressed: onOpenAll,
                        child: const Text('كل اللوائح'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => onAcceptedChanged(!accepted),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Checkbox(
                  value: accepted,
                  onChanged: (v) => onAcceptedChanged(v ?? false),
                  activeColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'اطلعت على الضوابط وأوافق عليها',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
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
