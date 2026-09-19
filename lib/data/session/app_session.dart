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

  /// الحساب التجريبي الكامل (أدوار + هياكل) — في وضع التصميم فقط.
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

  /// هل الجلسة الحالية من الـ API (وليست تجريبية)؟
  static bool get isRemote => currentUser != null && demoAccount == null;

  static bool get isManagerMode =>
      activeRole == AppRole.structureManager && activeStructure != null;

  /// المدير يعمل حالياً داخل واجهة موظف آخر.
  static bool get isImpersonating => _managerSnapshot != null;

  static Employee? get impersonatingManager => _managerSnapshot;

  static ManagedStructure? get impersonationReturnStructure =>
      _structureSnapshot;

  /// الهياكل التي يديرها المستخدم — من الحساب التجريبي أو من أعلام `/auth/me`.
  static List<ManagedStructure> get managedStructures {
    final demo = demoAccount;
    if (demo != null) return demo.managedStructures;
    return currentUser?.managedStructures ?? const [];
  }

  /// هل يمر المستخدم على صفحة تحديد نوع الدخول؟
  static bool get canManageStructures {
    final demo = demoAccount;
    if (demo != null) return demo.canManageStructures;
    return currentUser?.canManageStructures ?? false;
  }

  /// يمكنه الدخول نيابة عن موظف (هيكل علوي، أو المدير التجريبي).
  static bool get canActOnBehalf {
    if (demoAccount != null) return canManageStructures;
    return currentUser?.canActOnBehalf ?? false;
  }

  /// بعد `/auth/login`: الدور يبقى غير محدد حتى تقرر صفحة whichApp
  /// (أو يدخل كموظف مباشرة إن لم يكن مسؤولاً).
  static void applyLogin(TokenPair pair) {
    accessToken = pair.accessToken;
    refreshToken = pair.refreshToken;
    _applyUser(pair.user);
  }

  /// استعادة جلسة محفوظة (`/auth/me` بعد إعادة تشغيل التطبيق).
  static void applyRestoredSession({
    required AuthUser user,
    required String access,
    required String? refresh,
  }) {
    accessToken = access;
    refreshToken = refresh;
    _applyUser(user);
  }

  /// تحديث التوكنات بعد `/auth/refresh` دون المساس بالدور المختار.
  static void applyRefreshedTokens(TokenPair pair) {
    accessToken = pair.accessToken;
    refreshToken = pair.refreshToken;
    currentUser = pair.user;
    if (!isImpersonating) {
      currentEmployee = Employee.fromAuthUser(pair.user);
    }
  }

  static void _applyUser(AuthUser user) {
    currentUser = user;
    currentEmployee = Employee.fromAuthUser(user);
    demoAccount = null;
    activeRole = user.canManageStructures ? null : AppRole.employee;
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
    _managerSnapshot ??= demoAccount?.employee ?? currentEmployee;
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
