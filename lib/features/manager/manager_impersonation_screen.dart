import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/models/employee.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_employees.dart';
import '../shell/main_shell.dart';

/// الدخول نيابة عن موظف — responsible_for.php + setManager/setSession.
class ManagerImpersonationScreen extends StatefulWidget {
  const ManagerImpersonationScreen({super.key});

  @override
  State<ManagerImpersonationScreen> createState() =>
      _ManagerImpersonationScreenState();
}

class _ManagerImpersonationScreenState extends State<ManagerImpersonationScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> get _results {
    final selfNumber = AppSession.demoAccount?.employee.employeeNumber;
    return [
      for (final e in StaticEmployees.search(_query))
        if (e.employeeNumber != selfNumber) e,
    ];
  }

  Future<void> _enterAs(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الدخول نيابة عن الموظف'),
        content: Text(
          'ستنتقل إلى واجهة الموظف ${employee.fullName} لتقديم طلب أو متابعة إجراءاته. يمكنك العودة لاحقاً كمسؤول عن الهيكل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    AppSession.startImpersonation(employee);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final structure = AppSession.activeStructure?.name ?? 'الهيكل';
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الدخول نيابة عن'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppSurface(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFFEFE8DC), AppColors.surface],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.switch_account_rounded,
                          color: AppColors.goldDeep,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'ابحث عن موظف تحت إشرافك',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'الهيكل الحالي: $structure',
                    style: const TextStyle(
                      color: AppColors.goldDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'بعد الدخول تظهر لك واجهة الموظف كاملة. من الحساب يمكنك إنهاء النيابة والعودة كمسؤول.',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'ابحث باسم الموظف أو الرقم الوظيفي',
              prefixIcon: const Icon(Icons.badge_outlined),
              filled: true,
              fillColor: AppColors.surface,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            results.isEmpty
                ? 'لا نتائج'
                : '${results.length} موظف ضمن نطاق البحث',
            style: const TextStyle(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          if (results.isEmpty)
            const AppSurface(
              child: Column(
                children: [
                  Icon(Icons.person_search_outlined,
                      size: 36, color: AppColors.gold),
                  SizedBox(height: 10),
                  Text(
                    'جرّب اسماً أو رقماً وظيفياً آخر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final employee in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppSurface(
                  onTap: () => _enterAs(employee),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.goldSoft,
                        child: Text(
                          employee.fullName.characters.first,
                          style: const TextStyle(
                            color: AppColors.goldDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              employee.employeeNumber,
                              style: const TextStyle(
                                color: AppColors.goldDeep,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${employee.jobTitle} · ${employee.department}',
                              style: const TextStyle(
                                color: AppColors.slate,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.login_rounded,
                        color: AppColors.goldDeep,
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
