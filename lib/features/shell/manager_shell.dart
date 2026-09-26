import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/session/app_session.dart';
import '../manager/manager_approvals_screen.dart';
import '../manager/manager_attendance_screen.dart';
import '../manager/manager_history_screen.dart';
import '../manager/remote_manager_requests_screen.dart';
import '../profile/profile_screen.dart';

/// هيكل تنقل المدير — موافقات / سابق / بصمات / حسابي.
class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final structureName = AppSession.activeStructure?.name ?? 'الهيكل';

    final pages = <Widget>[
      if (ApiConfig.useRemoteApi)
        RemoteManagerRequestsScreen(key: ValueKey('inbox-$_revision'))
      else
        ManagerApprovalsScreen(structureName: structureName),
      if (ApiConfig.useRemoteApi)
        RemoteManagerRequestsScreen(
          key: ValueKey('history-$_revision'),
          history: true,
        )
      else
        const ManagerHistoryScreen(),
      const ManagerAttendanceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ApiConfig.useRemoteApi
          ? pages[_index]
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Material(
        elevation: 8,
        shadowColor: const Color(0x22000000),
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.goldSoft,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() {
              if (_index != value) _revision++;
              _index = value;
            }),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check_rounded),
                label: 'الموافقات',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'السابق',
              ),
              NavigationDestination(
                icon: Icon(Icons.fingerprint_outlined),
                selectedIcon: Icon(Icons.fingerprint_rounded),
                label: 'البصمات',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
