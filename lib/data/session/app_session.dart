import '../models/app_role.dart';
import '../models/auth_models.dart';
import '../models/employee.dart';
import '../static/static_auth.dart';

/// جلسة التطبيق بعد تسجيل الدخول (تجريبي أو API).
abstract final class AppSession {
  static Employee? currentEmployee;
  static AuthUser? currentUser;
  static String? accessToken;
  static String? refreshToken;

  /// الحساب التجريبي الكامل (أدوار + هياكل).
  static DemoAccount? demoAccount;

  /// الدور المختار من صفحة whichApp.
  static AppRole? activeRole;

  /// الهيكل المختار عند الدخول كمسؤول.
  static ManagedStructure? activeStructure;

  static bool get isAuthenticated {
    if (demoAccount != null && currentEmployee != null) return true;
    return accessToken != null &&
        accessToken!.isNotEmpty &&
        currentUser != null;
  }

  static bool get isManagerMode =>
      activeRole == AppRole.structureManager && activeStructure != null;

  static void applyLogin(TokenPair pair) {
    accessToken = pair.accessToken;
    refreshToken = pair.refreshToken;
    currentUser = pair.user;
    currentEmployee = Employee.fromAuthUser(pair.user);
    demoAccount = null;
    activeRole = AppRole.employee;
    activeStructure = null;
  }

  static void applyDemoLogin(DemoAccount account) {
    demoAccount = account;
    currentEmployee = account.employee;
    currentUser = null;
    accessToken = null;
    refreshToken = null;
    activeRole = null;
    activeStructure = null;
  }

  static void enterAsEmployee() {
    activeRole = AppRole.employee;
    activeStructure = null;
  }

  static void enterAsManager(ManagedStructure structure) {
    activeRole = AppRole.structureManager;
    activeStructure = structure;
  }

  static void clear() {
    currentEmployee = null;
    currentUser = null;
    accessToken = null;
    refreshToken = null;
    demoAccount = null;
    activeRole = null;
    activeStructure = null;
  }
}
