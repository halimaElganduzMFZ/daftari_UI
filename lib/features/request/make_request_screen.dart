import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/request_date_bounds.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/permission_type.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_permission_types.dart';
import 'widgets/all_regulations_sheet.dart';
import 'widgets/single_regulation_sheet.dart';

/// شاشة تقديم طلب — مدمجة وسهلة: اختيار النوع من ورقة، والضوابط قابلة للطي.
class MakeRequestScreen extends StatefulWidget {
  const MakeRequestScreen({super.key});

  @override
  State<MakeRequestScreen> createState() => _MakeRequestScreenState();
}

class _MakeRequestScreenState extends State<MakeRequestScreen> {
  PermissionType? _selected;
  DateTime _requestDate = DateTime.now();
  final _noteController = TextEditingController();
  bool _submitting = false;
  bool _acceptedRules = false;
  bool _rulesExpanded = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
    if (picked != null) setState(() => _requestDate = picked);
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
    final picked = await showModalBottomSheet<PermissionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TypePickerSheet(selectedId: _selected?.id),
    );
    if (picked == null) return;
    setState(() {
      _selected = picked;
      _acceptedRules = false;
      _rulesExpanded = true;
    });
  }

  Future<void> _submit() async {
    if (_selected == null) {
      _toast('فضلاً اختر نوع الإذن المطلوب');
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
            'تم تسجيل طلب «${_selected!.title}» بتاريخ '
            '${DateFormat('yyyy/MM/dd').format(_requestDate)}.\n'
            'سيظهر ضمن الطلبات المعلّقة بعد ربط الواجهة مع الخادم.',
            style: const TextStyle(height: 1.5, color: AppColors.slate),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selected = null;
                  _acceptedRules = false;
                  _rulesExpanded = false;
                  _noteController.clear();
                  _requestDate = DateTime.now();
                });
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
    final dateLabel = DateFormat('yyyy/MM/dd').format(_requestDate);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'تقديم طلب جديد',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ثلاث خطوات سريعة: اختر النوع، راجع الضوابط، ثم أكّد التاريخ.',
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
            title: '1. نوع الإذن',
            subtitle: 'اختيار واحد فقط — القائمة تفتح في ورقة منفصلة',
          ),
          const SizedBox(height: 10),
          _TypeSelector(
            selected: _selected,
            onTap: _chooseType,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _selected == null
                ? const SizedBox.shrink(key: ValueKey('no-rules'))
                : _CompactRulesCard(
                    key: ValueKey(_selected!.id),
                    type: _selected!,
                    expanded: _rulesExpanded,
                    accepted: _acceptedRules,
                    onToggleExpand: () {
                      setState(() => _rulesExpanded = !_rulesExpanded);
                    },
                    onAcceptedChanged: (value) {
                      setState(() => _acceptedRules = value);
                    },
                    onOpenFull: () {
                      showSingleRegulationSheet(context, type: _selected!);
                    },
                    onOpenAll: () {
                      showAllRegulationsSheet(
                        context,
                        initialTabId: 'permissions',
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: '2. تفاصيل الطلب',
            subtitle: 'التاريخ قريب وواضح بدون تمرير طويل',
          ),
          const SizedBox(height: 10),
          AppSurface(
            onTap: _pickDate,
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
          colors: [
            Color(0xFFF7F1E6),
            Color(0xFFEFEFEA),
            Color(0xFFE8E8E4),
          ],
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

/// زر اختيار أنيق يعرض النوع المحدد فقط بدل شبكة طويلة.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onTap});

  final PermissionType? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                    selected?.icon ?? FontAwesomeIcons.listUl,
                    size: 17,
                    color: AppColors.goldDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelection ? selected!.title : 'اضغط لاختيار نوع الإذن',
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
                            : 'ستظهر الأنواع في قائمة مرتبة وواضحة',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
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
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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

/// ورقة اختيار الأنواع — تحافظ على جمال البطاقات دون إطالة الصفحة الرئيسية.
class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;

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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.listCheck,
                      size: 16,
                      color: AppColors.goldDeep,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اختر نوع الإذن',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: StaticPermissionTypes.all.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (context, index) {
                    final type = StaticPermissionTypes.all[index];
                    final selected = type.id == selectedId;
                    return Material(
                      color: selected ? AppColors.goldSoft : AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(type),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  selected ? AppColors.gold : AppColors.line,
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FaIcon(
                                type.icon,
                                size: 18,
                                color: selected
                                    ? AppColors.goldDeep
                                    : AppColors.slate,
                              ),
                              const Spacer(),
                              Text(
                                type.title,
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
