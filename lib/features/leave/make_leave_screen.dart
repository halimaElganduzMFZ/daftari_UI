import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/services/document_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/leave_kind.dart';
import '../../data/models/request_attachment.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_employee_dashboard.dart';
import '../../data/static/static_leave_kinds.dart';
import '../request/widgets/all_regulations_sheet.dart';
import '../request/widgets/single_regulation_sheet.dart';

/// شاشة تقديم طلب إجازة — من Taking_a_day_off.php
/// بنفس أسلوب شاشة الأذونات المبسّطة.
class MakeLeaveScreen extends StatefulWidget {
  const MakeLeaveScreen({super.key, this.onSubmitted});

  final VoidCallback? onSubmitted;

  @override
  State<MakeLeaveScreen> createState() => _MakeLeaveScreenState();
}

class _MakeLeaveScreenState extends State<MakeLeaveScreen> {
  LeaveKind? _selected;
  DateTime? _startDate;
  DateTime? _endDate;
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();
  final _emergencyController = TextEditingController();
  bool _acceptedRules = false;
  bool _rulesExpanded = false;
  bool _submitting = false;
  RequestAttachment? _attachment;
  bool _fileAccessHintShown = false;
  bool _pickingAttachment = false;

  @override
  void dispose() {
    _noteController.dispose();
    _locationController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

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
    final picked = await showModalBottomSheet<LeaveKind>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaveTypePickerSheet(selectedId: _selected?.id),
    );
    if (picked == null) return;
    setState(() {
      _selected = picked;
      _acceptedRules = false;
      _rulesExpanded = true;
      _attachment = null;
      _emergencyController.clear();
      _locationController.clear();
      if (_startDate != null && picked.fixedDays != null) {
        _endDate = _startDate!.add(Duration(days: picked.fixedDays! - 1));
      }
    });
    if (picked.needsStudyAttachment) {
      await _ensureFileAccessHint();
    }
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'تاريخ بداية الإجازة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
      if (_selected?.fixedDays != null) {
        _endDate = picked.add(Duration(days: _selected!.fixedDays! - 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    if (_selected?.fixedDays != null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now.add(const Duration(days: 1)),
      firstDate: _startDate ?? now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'تاريخ نهاية الإجازة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  int? get _dayCount {
    if (_startDate == null || _endDate == null) return null;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

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
      setState(() {
        _attachment = RequestAttachment(
          fileName: picked.name,
          fileSizeBytes: picked.size,
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


  Future<void> _submit() async {
    if (_selected == null) {
      _toast('فضلاً اختر نوع الإجازة');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _toast('فضلاً حدّد تاريخ البداية والنهاية');
      return;
    }
    if (_selected!.needsLocation && _locationController.text.trim().isEmpty) {
      _toast('فضلاً حدّد مكان قضاء الإجازة');
      return;
    }
    if (_selected!.needsEmergencyReason &&
        _emergencyController.text.trim().isEmpty) {
      _toast('فضلاً اكتب سبب الإجازة الطارئة');
      return;
    }
    if (_selected!.needsStudyAttachment && _attachment == null) {
      _toast('فضلاً أرفق المستند المطلوب');
      return;
    }
    if (!_acceptedRules) {
      _toast('فضلاً أكّد اطلاعك على الضوابط قبل الإرسال');
      return;
    }

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
          content: Text(
            'تم تسجيل طلب «${_selected!.title}» من '
            '${DateFormat('yyyy/MM/dd').format(_startDate!)} إلى '
            '${DateFormat('yyyy/MM/dd').format(_endDate!)}'
            '${_dayCount != null ? ' ($_dayCount أيام)' : ''}.\n'
            'سيظهر ضمن الطلبات المعلّقة بعد ربط الواجهة مع الخادم.',
            style: const TextStyle(height: 1.5, color: AppColors.slate),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSubmitted?.call();
                if (widget.onSubmitted == null) {
                  setState(() {
                    _selected = null;
                    _acceptedRules = false;
                    _rulesExpanded = false;
                    _startDate = null;
                    _endDate = null;
                    _noteController.clear();
                    _locationController.clear();
                    _emergencyController.clear();
                    _attachment = null;
                  });
                }
              },
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final kind = _selected;

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
          const SizedBox(height: 18),
          const SectionHeader(
            title: '1. نوع الإجازة',
            subtitle: 'اختيار واحد فقط — القائمة تفتح في ورقة منفصلة',
          ),
          const SizedBox(height: 10),
          _TypeSelector(selected: kind, onTap: _chooseType),
          if (kind != null &&
              (kind.id == 'annual' || kind.id == 'emergency')) ...[
            const SizedBox(height: 10),
            _BalanceHint(kindId: kind.id),
          ],
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: kind == null
                ? const SizedBox.shrink(key: ValueKey('no-rules'))
                : _CompactRulesCard(
                    key: ValueKey(kind.id),
                    kind: kind,
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
                        title: kind.title,
                        icon: kind.icon,
                        points: kind.points,
                        fullText: kind.fullText,
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
                  locked: kind?.fixedDays != null,
                ),
              ),
            ],
          ),
          if (_dayCount != null) ...[
            const SizedBox(height: 8),
            Text(
              'المدة: $_dayCount ${_dayCount == 1 ? 'يوم' : 'أيام'}'
              '${kind?.fixedDays != null ? ' (مدة ثابتة حسب اللائحة)' : ''}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.goldDeep,
              ),
            ),
          ],
          if (kind?.needsLocation == true) ...[
            const SizedBox(height: 10),
            AppSurface(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: TextField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'مكان قضاء الإجازة (داخل / خارج ليبيا)…',
                  hintStyle: TextStyle(color: AppColors.slate),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 4, right: 10),
                    child: FaIcon(
                      FontAwesomeIcons.locationDot,
                      size: 15,
                      color: AppColors.goldDeep,
                    ),
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 36, minHeight: 24),
                ),
              ),
            ),
          ],
          if (kind?.needsEmergencyReason == true) ...[
            const SizedBox(height: 10),
            AppSurface(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: TextField(
                controller: _emergencyController,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'سبب الإجازة الطارئة…',
                  hintStyle: TextStyle(color: AppColors.slate),
                ),
              ),
            ),
          ],
          if (kind?.needsStudyAttachment == true) ...[
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
                        subtitle: _selected?.title,
                      ),
              onClear: () => setState(() => _attachment = null),
            ),
          ],
          const SizedBox(height: 10),
          AppSurface(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: TextField(
              controller: _noteController,
              maxLines: 2,
              minLines: 2,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'ملاحظة قصيرة (اختياري)…',
                hintStyle: TextStyle(color: AppColors.slate),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _submitting ? null : _submit,
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

// ─── Type picker ─────────────────────────────────────────────────────────────

class _LeaveTypePickerSheet extends StatelessWidget {
  const _LeaveTypePickerSheet({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final kinds = StaticLeaveKinds.all;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
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
                final selected = k.id == selectedId;
                return Material(
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
                                k.icon,
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
                                  k.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? AppColors.goldDeep
                                        : AppColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  k.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.slate,
                                  ),
                                ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small widgets ───────────────────────────────────────────────────────────


class _BalanceHint extends StatelessWidget {
  const _BalanceHint({required this.kindId});

  final String kindId;

  @override
  Widget build(BuildContext context) {
    final data = StaticEmployeeDashboard.data;
    final isAnnual = kindId == 'annual';
    final value = isAnnual ? data.annualBalance : data.emergencyBalance;
    final label = isAnnual ? 'رصيد الإجازة السنوية المتاح' : 'رصيد الإجازة الطارئة المتاح';

    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FaIcon(
              isAnnual
                  ? FontAwesomeIcons.calendarCheck
                  : FontAwesomeIcons.bolt,
              size: 14,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
          ),
          Text(
            '$value يوم',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.goldDeep,
            ),
          ),
        ],
      ),
    );
  }
}


class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onTap});

  final LeaveKind? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = selected != null;
    return AppSurface(
      onTap: onTap,
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
                has ? selected!.icon : FontAwesomeIcons.umbrellaBeach,
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
                  has ? 'نوع الإجازة' : 'اختر نوع الإجازة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  has ? selected!.title : 'اضغط للاختيار من القائمة',
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
                  ? 'اضغط «اختيار من الجهاز» لفتح ملفات الكمبيوتر واختيار المستند (PDF / Word / صورة).'
                  : 'سيُطلب إذن الوصول للملفات عند أول إرفاق، ثم يمكنك اختيار المستند من الجهاز.',
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
                    'اضغط للمعاينة الاحترافية$_sizeLabel',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
