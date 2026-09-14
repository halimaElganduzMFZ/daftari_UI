import '../models/auth_models.dart';
import '../models/employee.dart';

/// جلسة التطبيق بعد تسجيل الدخول عبر الـ API.
abstract final class AppSession {
  static Employee? currentEmployee;
  static AuthUser? currentUser;
  static String? accessToken;
  static String? refreshToken;

  static bool get isAuthenticated =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      currentUser != null;

  static void applyLogin(TokenPair pair) {
    accessToken = pair.accessToken;
    refreshToken = pair.refreshToken;
    currentUser = pair.user;
    currentEmployee = Employee.fromAuthUser(pair.user);
  }

  static void clear() {
    currentEmployee = null;
    currentUser = null;
    accessToken = null;
    refreshToken = null;
  }
}
