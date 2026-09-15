import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/session/app_session.dart';
import '../auth/login_screen.dart';
import '../auth/which_app_screen.dart';
import '../manager/manager_impersonation_screen.dart';
import '../shell/manager_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      if (ApiConfig.useRemoteApi) {
        await AuthRepository().logout();
      }
    } catch (_) {
      // نخرج محلياً حتى لو فشل طلب الخادم
    }
    AppSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _switchRole() {
    if (AppSession.demoAccount?.canManageStructures != true) return;
    if (AppSession.isImpersonating) {
      AppSession.endImpersonation();
    }
    AppSession.activeRole = null;
    AppSession.activeStructure = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WhichAppScreen()),
      (_) => false,
    );
  }

  void _endImpersonation() {
    final structure = AppSession.endImpersonation();
    if (!mounted) return;
    if (structure != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ManagerShell()),
        (_) => false,
      );
    }
  }

  void _openImpersonation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ManagerImpersonationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final user = AppSession.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            AppStrings.profile,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee?.fullName ?? user?.displayName ?? 'موظف',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  employee?.jobTitle ?? user?.displayRole ?? '—',
                  style: const TextStyle(color: AppColors.slate),
                ),
                const SizedBox(height: 4),
                Text(
                  employee?.employeeNumber ?? user?.employeeNumber ?? '—',
                  style: const TextStyle(
                    color: AppColors.goldDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  employee?.department ?? user?.workplaceName ?? '—',
                ),
                Text(employee?.email ?? user?.email ?? '—'),
                if (AppSession.isImpersonating) ...[
                  const SizedBox(height: 10),
                  const _FlagChip(
                    label: 'نيابة عن موظف — أنهِ من الزر بالأسفل',
                    color: AppColors.warning,
                  ),
                ] else if (AppSession.isManagerMode) ...[
                  const SizedBox(height: 10),
                  _FlagChip(
                    label:
                        'مسؤول: ${AppSession.activeStructure?.name ?? ''}',
                    color: AppColors.goldDeep,
                  ),
                ] else if (AppSession.activeRole != null) ...[
                  const SizedBox(height: 10),
                  const _FlagChip(
                    label: 'دخول كموظف',
                    color: AppColors.info,
                  ),
                ],
                if (user != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (user.isAdmin)
                        const _FlagChip(
                          label: 'مسؤول',
                          color: AppColors.goldDeep,
                        ),
                      if (user.isAssigner)
                        const _FlagChip(
                          label: 'مسؤول هيكل',
                          color: AppColors.slate,
                        ),
                      if (user.canChangePassword)
                        const _FlagChip(
                          label: 'يمكن تغيير كلمة المرور',
                          color: AppColors.success,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (AppSession.isImpersonating) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _endImpersonation,
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text('العودة كمسؤول عن الهيكل'),
            ),
          ],
          if (AppSession.isManagerMode) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openImpersonation,
              icon: const Icon(Icons.person_search_rounded),
              label: const Text('الدخول نيابة عن موظف'),
            ),
          ],
          if (AppSession.demoAccount?.canManageStructures == true &&
              !AppSession.isImpersonating) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _switchRole,
              child: const Text('تغيير الوحدة / الإدارة'),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _loggingOut ? null : _logout,
            child: _loggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
