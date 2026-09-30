import 'auth_models.dart';

enum EmploymentStatus { active, onLeave, suspended }

class Employee {
  const Employee({
    required this.id,
    required this.employeeNumber,
    required this.fullName,
    required this.jobTitle,
    required this.department,
    required this.phone,
    required this.email,
    required this.hireDate,
    required this.status,
  });

  final String id;
  final String employeeNumber;
  final String fullName;
  final String jobTitle;
  final String department;
  final String phone;
  final String email;
  final DateTime hireDate;
  final EmploymentStatus status;

  /// تحويل ملف المستخدم القادم من `/auth/login` أو `/auth/me`.
  factory Employee.fromAuthUser(AuthUser user) {
    return Employee(
      id: user.id.toString(),
      employeeNumber: user.employeeNumber,
      fullName: user.displayName,
      jobTitle: user.displayRole,
      department: user.workplaceName?.trim().isNotEmpty == true
          ? user.workplaceName!.trim()
          : '—',
      phone: '—',
      email: user.email?.trim().isNotEmpty == true ? user.email!.trim() : '—',
      hireDate: DateTime.now(),
      status: EmploymentStatus.active,
    );
  }

  /// بحث سريع O(1) للحقل الواحد — يُستخدم مع تصفية القائمة.
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase();
    return fullName.toLowerCase().contains(q) ||
        employeeNumber.toLowerCase().contains(q) ||
        department.toLowerCase().contains(q) ||
        jobTitle.toLowerCase().contains(q);
  }
}
