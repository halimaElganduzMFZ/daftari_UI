import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_role.dart';
import '../../data/session/app_session.dart';
import '../shell/main_shell.dart';
import '../shell/manager_shell.dart';

/// مقابلة whichApp.php — اختيار الدخول كموظف أو مسؤول هيكل.
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

  @override
  Widget build(BuildContext context) {
    final account = AppSession.demoAccount;
    final employee = AppSession.currentEmployee;
    final name = employee?.fullName ?? 'موظف';
    final structures = account?.managedStructures ?? const <ManagedStructure>[];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDEDEB),
              AppColors.background,
              Color(0xFFE8E6E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const Text(
                      AppStrings.orgName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.whichAppTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldDeep,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'مرحباً عزيزي الموظف',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDeep,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: () => _enterEmployee(context),
                              child: const Text(AppStrings.enterAsEmployee),
                            ),
                          ),
                          if (structures.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            const Text(
                              AppStrings.enterAsManagerOf,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...structures.map(
                              (structure) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _enterManager(context, structure),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.gold,
                                        width: 1.4,
                                      ),
                                      foregroundColor: AppColors.charcoal,
                                    ),
                                    child: Text(
                                      structure.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
