import 'package:flutter/foundation.dart';

import '../../data/auth/auth_repository.dart';
import '../../data/auth/token_storage.dart';
import '../../data/repositories/assets_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/documents_repository.dart';
import '../../data/repositories/healthcare_repository.dart';
import '../../data/repositories/leave_requests_repository.dart';
import '../../data/repositories/messages_repository.dart';
import '../../data/repositories/permission_requests_repository.dart';
import '../../data/session/app_session.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';

/// نقطة تجميع الخدمات (بدون حزمة DI) — نسخة واحدة من العميل والمستودعات.
///
/// يختار التنفيذ الثابت أو الـ API حسب [ApiConfig.useRemoteApi]، فتبقى
/// الشاشات كما هي ويتبدّل المصدر من مكان واحد.
abstract final class AppServices {
  static final TokenStorage tokenStorage = TokenStorage();

  static final ApiClient apiClient = ApiClient(
    getAccessToken: () async =>
        AppSession.accessToken ?? await tokenStorage.readAccessToken(),
    onUnauthorized: _handleUnauthorized,
  );

  static final AuthRepository auth = AuthRepository(apiClient, tokenStorage);

  static final DashboardRepository dashboard = ApiConfig.useRemoteApi
      ? ApiDashboardRepository(apiClient)
      : const StaticDashboardRepository();

  /// الشكاوى والمقترحات (`/me/messages`).
  static final MessagesRepository messages = ApiConfig.useRemoteApi
      ? ApiMessagesRepository(apiClient)
      : StaticMessagesRepository();

  /// الأصول المسجّلة على الموظف (`/me/assets`).
  static final AssetsRepository assets = ApiConfig.useRemoteApi
      ? ApiAssetsRepository(apiClient)
      : const StaticAssetsRepository();

  /// القصاصات والمستندات (`/me/documents`).
  static final DocumentsRepository documents = ApiConfig.useRemoteApi
      ? ApiDocumentsRepository(apiClient)
      : const StaticDocumentsRepository();

  /// المؤسسات الطبية المتعاقد معها (`/lookups/healthcare-providers`).
  static final HealthcareRepository healthcare = ApiConfig.useRemoteApi
      ? ApiHealthcareRepository(apiClient)
      : const StaticHealthcareRepository();

  /// تقديم طلب إذن (`/me/requests/options` + `POST /me/requests`).
  static final PermissionRequestsRepository permissionRequests =
      ApiConfig.useRemoteApi
          ? ApiPermissionRequestsRepository(apiClient)
          : StaticPermissionRequestsRepository();

  /// تقديم طلب إجازة (`/me/leave/requests/*`).
  static final LeaveRequestsRepository leaveRequests = ApiConfig.useRemoteApi
      ? ApiLeaveRequestsRepository(apiClient)
      : StaticLeaveRequestsRepository();

  /// يُستدعى عندما تنتهي الجلسة نهائياً (فشل تجديد التوكن بغير خطأ شبكة).
  /// يضبطه `main.dart` للعودة إلى شاشة الدخول من أي مكان.
  static VoidCallback? onSessionExpired;

  static Future<bool> _handleUnauthorized() async {
    // في الوضع التجريبي لا توجد جلسة API لتجديدها.
    if (!AppSession.isRemote && AppSession.accessToken == null) return false;
    final refreshed = await auth.tryRefresh();
    if (!refreshed && AppSession.isRemote) {
      final hadTokens = AppSession.accessToken != null;
      final stillHasRefresh =
          (await tokenStorage.readRefreshToken())?.isNotEmpty ?? false;
      // التوكنات مُسحت من tryRefresh ⇒ الجلسة انتهت فعلاً (وليس عطل شبكة).
      if (hadTokens && !stillHasRefresh) {
        AppSession.clear();
        onSessionExpired?.call();
      }
    }
    return refreshed;
  }
}
