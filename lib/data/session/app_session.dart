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

  /// لقطة المدير عند الدخول نيابة عن موظف (responsible_for.php).
  static Employee? _managerSnapshot;
  static ManagedStructure? _structureSnapshot;

  static bool get isAuthenticated {
    if (demoAccount != null && currentEmployee != null) return true;
    return accessToken != null &&
        accessToken!.isNotEmpty &&
        currentUser != null;
  }

  static bool get isManagerMode =>
      activeRole == AppRole.structureManager && activeStructure != null;

  /// المدير يعمل حالياً داخل واجهة موظف آخر.
  static bool get isImpersonating => _managerSnapshot != null;

  static Employee? get impersonatingManager => _managerSnapshot;

  static ManagedStructure? get impersonationReturnStructure =>
      _structureSnapshot;

  static void applyLogin(TokenPair pair) {
    accessToken = pair.accessToken;
    refreshToken = pair.refreshToken;
    currentUser = pair.user;
    currentEmployee = Employee.fromAuthUser(pair.user);
    demoAccount = null;
    activeRole = AppRole.employee;
    activeStructure = null;
    _clearImpersonationSnapshots();
  }

  static void applyDemoLogin(DemoAccount account) {
    demoAccount = account;
    currentEmployee = account.employee;
    currentUser = null;
    accessToken = null;
    refreshToken = null;
    activeRole = null;
    activeStructure = null;
    _clearImpersonationSnapshots();
  }

  static void enterAsEmployee() {
    activeRole = AppRole.employee;
    activeStructure = null;
  }

  static void enterAsManager(ManagedStructure structure) {
    activeRole = AppRole.structureManager;
    activeStructure = structure;
  }

  /// دخول المدير إلى تطبيق الموظف نيابة عنه — تتبدل الصفة إلى موظف.
  static void startImpersonation(Employee target) {
    if (!isManagerMode && _managerSnapshot == null) {
      // يسمح بالبدء فقط من وضع المدير.
      if (activeStructure == null) return;
    }
    _managerSnapshot ??=
        demoAccount?.employee ?? currentEmployee;
    _structureSnapshot ??= activeStructure;
    currentEmployee = target;
    activeRole = AppRole.employee;
    activeStructure = null;
  }

  /// إنهاء النيابة والعودة كمسؤول عن الهيكل السابق.
  static ManagedStructure? endImpersonation() {
    final structure = _structureSnapshot;
    final manager = _managerSnapshot;
    if (manager != null) {
      currentEmployee = manager;
    }
    if (structure != null) {
      activeRole = AppRole.structureManager;
      activeStructure = structure;
    } else {
      activeRole = AppRole.employee;
      activeStructure = null;
    }
    _clearImpersonationSnapshots();
    return structure;
  }

  static void _clearImpersonationSnapshots() {
    _managerSnapshot = null;
    _structureSnapshot = null;
  }

  static void clear() {
    currentEmployee = null;
    currentUser = null;
    accessToken = null;
    refreshToken = null;
    demoAccount = null;
    activeRole = null;
    activeStructure = null;
    _clearImpersonationSnapshots();
  }
}
