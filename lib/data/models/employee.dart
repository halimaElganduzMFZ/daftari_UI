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
