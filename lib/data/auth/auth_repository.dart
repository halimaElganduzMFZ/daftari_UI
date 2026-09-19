import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/auth_models.dart';
import '../session/app_session.dart';
import 'token_storage.dart';

/// مستودع المصادقة — يربط الواجهة بـ `AuthController` في Nest.
///
/// - `login`   → `POST /auth/login`
/// - `refresh` → `POST /auth/refresh` (تدوير التوكن؛ القديم يُلغى)
/// - `me`      → `GET  /auth/me`      (الأعلام تُحسب حيّة)
/// - `logout`  → `POST /auth/logout`
class AuthRepository {
  AuthRepository(this._client, this._tokens);

  final ApiClient _client;
  final TokenStorage _tokens;

  /// يمنع تجديدين متوازيين عند فشل عدة طلبات بـ 401 في نفس اللحظة.
  Future<bool>? _refreshInFlight;

  TokenStorage get tokenStorage => _tokens;

  Future<TokenPair> login({
    required String employeeNumber,
    required String password,
  }) async {
    final json = await _client.postJson(
      '/auth/login',
      body: {
        'employeeNumber': employeeNumber.trim(),
        'password': password,
      },
    );
    final pair = TokenPair.fromJson(json);
    await _persist(pair);
    return pair;
  }

  Future<TokenPair> refresh() async {
    final refreshToken =
        AppSession.refreshToken ?? await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(message: 'لا توجد جلسة محفوظة', statusCode: 401);
    }
    final json = await _client.postJson(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    final pair = TokenPair.fromJson(json);
    await _persist(pair);
    AppSession.applyRefreshedTokens(pair);
    return pair;
  }

  /// يُستخدم من [ApiClient] عند 401: يجدد مرة واحدة ويعيد `true` عند النجاح.
  /// عند الفشل تُمسح الجلسة المحلية حتى يعود المستخدم لشاشة الدخول.
  Future<bool> tryRefresh() {
    return _refreshInFlight ??= _doTryRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doTryRefresh() async {
    try {
      await refresh();
      return true;
    } on ApiException catch (error) {
      // خطأ شبكة: لا نُنهي الجلسة، فقط نفشل هذا الطلب.
      if (error.isNetwork) return false;
      await _tokens.clear();
      return false;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

  Future<AuthUser> me() async {
    final json = await _client.getJson('/auth/me', auth: true);
    return AuthUser.fromJson(json);
  }

  /// هل يوجد توكن محفوظ محلياً؟ (قراءة محلية سريعة دون اتصال بالخادم).
  Future<bool> hasStoredSession() async {
    final access = await _tokens.readAccessToken();
    return access != null && access.isNotEmpty;
  }

  /// استعادة الجلسة عند فتح التطبيق: توكن محفوظ → `/auth/me`.
  /// يعيد `null` إن لم توجد جلسة صالحة (والتوكنات تُمسح عندها).
  Future<AuthUser?> restoreSession() async {
    final access = await _tokens.readAccessToken();
    final refresh = await _tokens.readRefreshToken();
    if (access == null || access.isEmpty) return null;

    // نضع التوكنات في الجلسة أولاً حتى يستخدمها العميل (وتجديد 401 التلقائي).
    AppSession.accessToken = access;
    AppSession.refreshToken = refresh;

    try {
      final user = await me();
      AppSession.applyRestoredSession(
        user: user,
        access: AppSession.accessToken ?? access,
        refresh: AppSession.refreshToken ?? refresh,
      );
      return user;
    } on ApiException catch (error) {
      if (error.isNetwork) {
        // الخادم غير متاح الآن: لا نمسح الجلسة، لكن لا نستطيع الدخول بها.
        AppSession.clear();
        rethrow;
      }
      await _tokens.clear();
      AppSession.clear();
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken =
        AppSession.refreshToken ?? await _tokens.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.postNoContent(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
          auth: true,
        );
      }
    } catch (_) {
      // نمسح الجلسة محلياً حتى لو فشل الطلب
    } finally {
      await _tokens.clear();
    }
  }

  Future<void> _persist(TokenPair pair) => _tokens.save(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
        tokenType: pair.tokenType,
      );
}
