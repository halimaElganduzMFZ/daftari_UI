import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/manager_repository.dart';
import '../../data/session/app_session.dart';
import '../manager/manager_approvals_screen.dart';
import '../manager/manager_attendance_screen.dart';
import '../manager/manager_history_screen.dart';
import '../manager/remote_manager_requests_screen.dart';
import '../profile/profile_screen.dart';

/// هيكل تنقل المدير — موافقات / سابق / بصمات / حسابي.
class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.manager`.
  final ManagerRepository? repository;

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  /// يُبنى القسم عند أول فتح ثم يبقى، فتبقى فلاتره وموضع التمرير فيه.
  final _opened = {0};

  /// يُنبَّه القسم عند العودة إليه فيحدّث بياناته دون أن يفرغ القائمة.
  final _returnedTo = List.generate(4, (_) => ValueNotifier(0));

  @override
  void dispose() {
    for (final notifier in _returnedTo) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _opened.add(index);
    });
    _returnedTo[index].value++;
  }

  @override
  Widget build(BuildContext context) {
    final structureName = AppSession.activeStructure?.name ?? 'الهيكل';

    final pages = <Widget>[
      if (ApiConfig.useRemoteApi)
        RemoteManagerRequestsScreen(
          repository: widget.repository,
          quietRefresh: _returnedTo[0],
        )
      else
        ManagerApprovalsScreen(structureName: structureName),
      if (ApiConfig.useRemoteApi)
        RemoteManagerRequestsScreen(
          history: true,
          repository: widget.repository,
          quietRefresh: _returnedTo[1],
        )
      else
        const ManagerHistoryScreen(),
      ManagerAttendanceScreen(
        repository: widget.repository,
        quietRefresh: _returnedTo[2],
      ),
      // ليست const كي تعيد قراءة الجلسة عند العودة إليها.
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          for (final (i, page) in pages.indexed)
            _opened.contains(i) ? page : const SizedBox.shrink(),
        ],
      ),
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
            onDestinationSelected: _select,
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
