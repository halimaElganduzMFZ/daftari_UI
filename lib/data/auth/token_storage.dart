import 'package:shared_preferences/shared_preferences.dart';

/// حفظ التوكنات محلياً (ويب/جوال) لاستعادة الجلسة لاحقاً.
class TokenStorage {
  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';
  static const _tokenTypeKey = 'auth.tokenType';
  static const _rememberKey = 'auth.rememberMe';
  static const _rememberedEmployeeKey = 'auth.rememberedEmployeeNumber';
  static const _rememberedPasswordKey = 'auth.rememberedPassword';

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

  /// «تذكرني»: يحفظ اسم المستخدم وكلمة المرور محلياً.
  Future<void> saveRememberedCredentials({
    required bool remember,
    required String employeeNumber,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await prefs.setBool(_rememberKey, false);
      await prefs.remove(_rememberedEmployeeKey);
      await prefs.remove(_rememberedPasswordKey);
      return;
    }
    final number = employeeNumber.trim();
    await prefs.setBool(_rememberKey, true);
    if (number.isEmpty) {
      await prefs.remove(_rememberedEmployeeKey);
    } else {
      await prefs.setString(_rememberedEmployeeKey, number);
    }
    if (password.isEmpty) {
      await prefs.remove(_rememberedPasswordKey);
    } else {
      await prefs.setString(_rememberedPasswordKey, password);
    }
  }

  Future<bool> readRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<String?> readRememberedEmployeeNumber() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_rememberKey) ?? false)) return null;
    final value = prefs.getString(_rememberedEmployeeKey)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<String?> readRememberedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_rememberKey) ?? false)) return null;
    final value = prefs.getString(_rememberedPasswordKey);
    return (value == null || value.isEmpty) ? null : value;
  }
}
