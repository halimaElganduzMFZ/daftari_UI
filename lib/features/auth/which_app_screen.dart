import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_role.dart';
import '../../data/session/app_session.dart';
import '../shell/main_shell.dart';
import '../shell/manager_shell.dart';

/// مقابلة whichApp.php — اختيار الوحدة/الإدارة للمسؤول.
/// الموظفون العاديون لا يمرّون من هنا (يدخلون مباشرة من تسجيل الدخول).
class WhichAppScreen extends StatelessWidget {
  const WhichAppScreen({super.key});

  void _enterEmployee(BuildContext context) {
    AppSession.enterAsEmployee();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  void _enterManager(BuildContext context, ManagedStructure structure) {
    AppSession.enterAsManager(structure);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ManagerShell()),
    );
  }

  IconData _iconForType(String typeLabel) {
    switch (typeLabel) {
      case 'إدارة':
        return Icons.apartment_rounded;
      case 'قسم':
        return Icons.account_tree_outlined;
      default:
        return Icons.business_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = AppSession.demoAccount;
    final employee = AppSession.currentEmployee;
    final name = employee?.fullName ?? 'موظف';
    final structures = account?.managedStructures ?? const <ManagedStructure>[];

    // لو فُتحت الشاشة بدون هياكل — ادخل كموظف مباشرة.
    if (structures.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _enterEmployee(context);
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFEAE8E3),
              AppColors.background,
              Color(0xFFE4E2DC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Text(
                      AppStrings.orgName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.slate.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.goldDeep,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تحديد نوع الدخول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً $name — ادخل كموظف أو اختر الهيكل الذي تديره',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _StructureCard(
                      name: 'الدخول كموظف',
                      typeLabel: 'موظف',
                      icon: Icons.badge_outlined,
                      subtitle: 'واجهة الموظف العادية لتقديم الطلبات ومتابعتها',
                      onTap: () => _enterEmployee(context),
                    ),
                    const SizedBox(height: 12),
                    if (structures.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'أو ادخل مسؤولاً عن',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ...structures.map(
                      (structure) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StructureCard(
                          name: structure.name,
                          typeLabel: structure.typeLabel,
                          icon: _iconForType(structure.typeLabel),
                          onTap: () => _enterManager(context, structure),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StructureCard extends StatefulWidget {
  const _StructureCard({
    required this.name,
    required this.typeLabel,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String name;
  final String typeLabel;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  State<_StructureCard> createState() => _StructureCardState();
}

class _StructureCardState extends State<_StructureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: AppColors.goldDeep),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            widget.typeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.slate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
