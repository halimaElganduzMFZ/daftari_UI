import 'package:shared_preferences/shared_preferences.dart';

/// حفظ التوكنات محلياً (ويب/جوال) لاستعادة الجلسة لاحقاً.
class TokenStorage {
  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';
  static const _tokenTypeKey = 'auth.tokenType';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(_tokenTypeKey, tokenType);
  }

  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_tokenTypeKey);
  }
}
