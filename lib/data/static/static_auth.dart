import '../models/app_role.dart';
import '../models/employee.dart';

/// حساب تجريبي للتصميم — بدون API.
class DemoAccount {
  const DemoAccount({
    required this.employeeNumber,
    required this.password,
    required this.employee,
    required this.roles,
    this.managedStructures = const [],
  });

  final String employeeNumber;
  final String password;
  final Employee employee;
  final List<AppRole> roles;
  final List<ManagedStructure> managedStructures;

  bool get canManageStructures =>
      roles.contains(AppRole.structureManager) &&
      managedStructures.isNotEmpty;
}

/// تسجيل دخول ثابت للتصميم.
///
/// حسابان للتجربة:
/// - موظف فقط:  FZ-10021 / 123456
/// - مدير هيكل:  FZ-20001 / 123456
abstract final class StaticAuth {
  static final List<DemoAccount> accounts = [
    DemoAccount(
      employeeNumber: 'FZ-10021',
      password: '123456',
      employee: Employee(
        id: 'e1',
        employeeNumber: 'FZ-10021',
        fullName: 'أحمد محمد العلي',
        jobTitle: 'أخصائي موارد بشرية',
        department: 'شؤون الموظفين',
        phone: '0501234567',
        email: 'ahmad.ali@freezone.local',
        hireDate: DateTime(2021, 3, 14),
        status: EmploymentStatus.active,
      ),
      roles: const [AppRole.employee],
    ),
    DemoAccount(
      employeeNumber: 'FZ-20001',
      password: '123456',
      employee: Employee(
        id: 'm1',
        employeeNumber: 'FZ-20001',
        fullName: 'خالد سعد المري',
        jobTitle: 'مدير وحدة',
        department: 'وحدة الشؤون الإدارية',
        phone: '0509988776',
        email: 'khaled.marri@freezone.local',
        hireDate: DateTime(2018, 6, 1),
        status: EmploymentStatus.active,
      ),
      roles: const [AppRole.employee, AppRole.structureManager],
      managedStructures: const [
        ManagedStructure(
          id: 's1',
          name: 'وحدة الشؤون الإدارية',
          typeLabel: 'وحدة',
        ),
        ManagedStructure(
          id: 's2',
          name: 'إدارة الموارد البشرية',
          typeLabel: 'إدارة',
        ),
      ],
    ),
  ];

  static DemoAccount? login({
    required String employeeNumber,
    required String password,
  }) {
    final number = employeeNumber.trim();
    final pass = password.trim();
    for (final account in accounts) {
      if (account.employeeNumber == number && account.password == pass) {
        return account;
      }
    }
    return null;
  }
}
