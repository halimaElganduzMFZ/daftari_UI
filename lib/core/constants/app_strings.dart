/// نصوص الواجهة — مستخرجة من login.php والشاشات الأساسية.
abstract final class AppStrings {
  static const appName = 'شؤون الموظفين';
  static const orgName = 'المنطقة الحرة بمصراتة';
  static const permissionsAppTitle = 'تطبيق إدارة الأذونات والإجازات';
  static const welcomeEmployee = 'مرحباً عزيزي الموظف / ة';
  static const loginSubtitle = 'ادخل رقم الموظف وكلمة المرور للمتابعة';
  static const username = 'اسم المستخدم';
  static const usernameHint = 'رقم الموظف';
  static const password = 'كلمة المرور';
  static const login = 'تسجيل الدخول';
  static const loginFailedTitle = 'مع الأسف';
  static const loginFailedMessage = 'رقم الموظف أو كلمة المرور غير صحيحة';
  static const loginRateLimitedTitle = 'تنبيه';
  static const loginConnectionError =
      'تعذّر الاتصال بالخادم. تأكد أن الـ API يعمل على المنفذ 3000.';
  static const apiLoginHint = 'الدخول عبر الخادم المحلي: 127.0.0.1:3000';
  static const footerRights = 'جميع الحقوق محفوظة';
  static const footerOrg = 'إدارة تقنية المعلومات - المنطقة الحرة بمصراتة';
  static const demoHint =
      'تجريبي — موظف: FZ-10021 / 123456\nمدير: FZ-20001 / 123456';
  static const whichAppTitle = 'تحديد نوع الدخول';
  static const enterAsEmployee = 'الدخول كــــ موظف';
  static const enterAsManagerOf = 'الدخول مسؤولاً عن';
  static const managerApprovalsTitle = 'سجل الطلبات التي تنتظر الإجراء';
  static const approve = 'موافقة';
  static const reject = 'رفض';
  static const rejectReasonTitle = 'تحديد سبب الرفض';
  static const rejectReasonHint = 'اكتب سبب الرفض هنا ....';
  static const monthlyApprovalsSummary = 'ملخص الموافقات لهذا الشهر';
  static const home = 'الرئيسية';
  static const employees = 'الموظفون';
  static const attendance = 'الحضور';
  static const leaves = 'الإجازات';
  static const profile = 'حسابي';
  static const searchEmployees = 'ابحث باسم أو رقم الموظف';
  static const todayAttendance = 'حضور اليوم';
  static const pendingLeaves = 'طلبات قيد المراجعة';
  static const quickActions = 'إجراءات سريعة';
  static const viewAll = 'عرض الكل';
  static const noResults = 'لا توجد نتائج';
  static const staticModeHint = 'وضع تجريبي — بيانات ثابتة';
}
