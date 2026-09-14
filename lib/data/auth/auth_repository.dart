import '../../core/network/api_client.dart';
import '../models/auth_models.dart';
import 'token_storage.dart';

/// مستودع المصادقة — يربط الواجهة بـ AuthController.
class AuthRepository {
  AuthRepository({
    ApiClient? client,
    TokenStorage? tokenStorage,
  }) : _tokens = tokenStorage ?? TokenStorage() {
    _client = client ??
        ApiClient(
          getAccessToken: _tokens.readAccessToken,
        );
  }

  late final ApiClient _client;
  final TokenStorage _tokens;

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
    await _tokens.save(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
      tokenType: pair.tokenType,
    );
    return pair;
  }

  Future<TokenPair> refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token');
    }
    final json = await _client.postJson(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    final pair = TokenPair.fromJson(json);
    await _tokens.save(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
      tokenType: pair.tokenType,
    );
    return pair;
  }

  Future<AuthUser> me() async {
    final json = await _client.getJson('/auth/me', auth: true);
    return AuthUser.fromJson(json);
  }

  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
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
}
