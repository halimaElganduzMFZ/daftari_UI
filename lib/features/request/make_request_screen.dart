import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/permission_type.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_permission_types.dart';

/// شاشة تقديم طلب جديد — من makeRequest.php بنمط أنظف وأكثر هدوءاً.
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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestDate,
      firstDate: DateTime(now.year, now.month - 1, now.day),
      lastDate: DateTime(now.year, now.month + 1, now.day),
      helpText: 'اختر تاريخ الطلب',
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

  void _openFullRegulation(PermissionType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: FaIcon(
                          type.icon,
                          size: 18,
                          color: AppColors.goldDeep,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'اللائحة الكاملة المتعلقة بهذا النوع',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (final point in type.points) ...[
                    _RegulationPointTile(point: point),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  AppSurface(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      type.fullText,
                      style: const TextStyle(
                        height: 1.65,
                        color: AppColors.charcoal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final dateLabel = DateFormat('yyyy/MM/dd').format(_requestDate);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'اختر نوع الإذن، اطّلع على الضوابط، ثم أكّد طلبك بهدوء ووضوح.',
                    style: TextStyle(
                      color: AppColors.slate,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _EmployeeStrip(
                    name: employee?.fullName ?? 'الموظف',
                    number: employee?.employeeNumber ?? '—',
                    department: employee?.department ?? '—',
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'نوع الإذن',
                    subtitle: 'اضغط على النوع المناسب لطلبك',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: StaticPermissionTypes.all.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                    ),
                    itemBuilder: (context, index) {
                      final type = StaticPermissionTypes.all[index];
                      final selected = _selected?.id == type.id;
                      return _TypeCard(
                        type: type,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selected = type;
                            _acceptedRules = false;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _selected == null
                    ? const SizedBox.shrink(key: ValueKey('empty-rules'))
                    : _RulesPanel(
                        key: ValueKey(_selected!.id),
                        type: _selected!,
                        accepted: _acceptedRules,
                        onAcceptedChanged: (value) {
                          setState(() => _acceptedRules = value);
                        },
                        onOpenFull: () => _openFullRegulation(_selected!),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'تفاصيل الطلب',
                    subtitle: 'التاريخ وملاحظة اختيارية',
                  ),
                  const SizedBox(height: 12),
                  AppSurface(
                    onTap: _pickDate,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppSurface(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'ملاحظة قصيرة (اختياري)…',
                        hintStyle: TextStyle(color: AppColors.slate),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              child: FilledButton(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.user,
              size: 18,
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
                    fontSize: 16,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$number • $department',
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 13,
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final PermissionType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.goldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(
                  type.icon,
                  size: 18,
                  color: selected ? AppColors.goldDeep : AppColors.slate,
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
                    color: selected ? AppColors.goldDeep : AppColors.charcoal,
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

class _RulesPanel extends StatelessWidget {
  const _RulesPanel({
    super.key,
    required this.type,
    required this.accepted,
    required this.onAcceptedChanged,
    required this.onOpenFull,
  });

  final PermissionType type;
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onOpenFull;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  type.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'أهم المواد المتعلقة بهذا النوع — مختصرة وواضحة.',
            style: TextStyle(color: AppColors.slate, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          for (final point in type.points.take(3)) ...[
            _RegulationPointTile(point: point, compact: true),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: onOpenFull,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldDeep,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'عرض اللائحة كاملة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 4),
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

class _RegulationPointTile extends StatelessWidget {
  const _RegulationPointTile({required this.point, this.compact = false});

  final RegulationPoint point;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              point.article,
              style: const TextStyle(
                color: AppColors.goldDeep,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.text,
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: TextStyle(
                color: AppColors.charcoal,
                height: 1.45,
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
