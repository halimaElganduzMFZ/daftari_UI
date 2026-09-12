import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee.dart';
import '../../data/repositories/repositories.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  static const _repo = StaticEmployeeRepository();
  final _controller = TextEditingController();
  late List<Employee> _items = _repo.getEmployees();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _items = _repo.search(value));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.employees,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: AppStrings.searchEmployees,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text(AppStrings.noResults))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = _items[index];
                      return AppSurface(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.goldSoft,
                              foregroundColor: AppColors.goldDeep,
                              child: Text(e.fullName.characters.first),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.jobTitle} • ${e.department}',
                                    style: const TextStyle(
                                      color: AppColors.slate,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Text(
                                    e.employeeNumber,
                                    style: const TextStyle(
                                      color: AppColors.goldDeep,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(
                              label: _statusLabel(e.status),
                              tone: _statusTone(e.status),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(EmploymentStatus status) => switch (status) {
        EmploymentStatus.active => 'نشط',
        EmploymentStatus.onLeave => 'إجازة',
        EmploymentStatus.suspended => 'موقوف',
      };

  static StatusTone _statusTone(EmploymentStatus status) => switch (status) {
        EmploymentStatus.active => StatusTone.success,
        EmploymentStatus.onLeave => StatusTone.warning,
        EmploymentStatus.suspended => StatusTone.danger,
      };
}
