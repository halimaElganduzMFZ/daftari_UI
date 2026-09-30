import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../leave/make_leave_screen.dart';
import '../leaves/leaves_screen.dart';
import '../profile/profile_screen.dart';
import '../request/make_request_screen.dart';
import '../request/request_kind_chooser.dart';
import '../request/submit_hub_screen.dart';

/// هيكل تنقل الموظف العادي (ليس المدير).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _openNewRequest() async {
    final kind = await showRequestKindChooser(context);
    if (!mounted || kind == null) return;

    if (kind == RequestKind.permission) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MakeRequestScreen(),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MakeLeaveScreen(
          onSubmitted: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onNewRequest: _openNewRequest),
      const LeavesScreen(),
      const SubmitHubScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'طلباتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'تقديم',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
