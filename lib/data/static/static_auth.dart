import '../models/employee.dart';
import 'static_employees.dart';

/// مصادقة ثابتة حالياً — لاحقاً تُستبدل باستدعاء API.
abstract final class StaticAuth {
  static const demoPassword = '123456';

  static Employee? login({
    required String username,
    required String password,
  }) {
    final user = username.trim().toLowerCase();
    final pass = password.trim();
    if (user.isEmpty || pass.isEmpty) return null;
    if (pass != demoPassword) return null;

    for (final employee in StaticEmployees.all) {
      final number = employee.employeeNumber.toLowerCase();
      final bare = number.replaceFirst('fz-', '');
      final inputBare = user.replaceFirst('fz-', '');
      if (number == user || bare == inputBare) return employee;
    }
    return null;
  }
}
