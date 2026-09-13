import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../leaves/leaves_screen.dart';
import '../profile/profile_screen.dart';

/// هيكل تنقل الموظف العادي (ليس المدير).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openNewRequest() => setState(() => _index = 2);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onNewRequest: _openNewRequest),
      const LeavesScreen(),
      const _NewRequestPlaceholder(),
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

class _NewRequestPlaceholder extends StatelessWidget {
  const _NewRequestPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.post_add_outlined, size: 48, color: AppColors.goldDeep),
              SizedBox(height: 16),
              Text(
                'تقديم الطلب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'سنصمّم شاشة makeRequest.php في الخطوة التالية.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
