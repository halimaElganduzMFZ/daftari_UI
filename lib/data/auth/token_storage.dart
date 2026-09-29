import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حفظ التوكنات محلياً لاستعادة الجلسة لاحقاً.
///
/// أندرويد / iOS: التوكنات في Keystore / Keychain عبر `flutter_secure_storage`.
/// الويب: لا يوجد مخزن آمن (والحزمة تتطلب HTTPS) فتبقى في SharedPreferences.
/// «تذكرني» يحفظ رقم الموظف فقط؛ كلمة المرور يتولاها مدير كلمات المرور في النظام.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage, bool? useSecureStorage})
      : _secure = secureStorage ?? _defaultSecureStorage,
        _useSecure = useSecureStorage ?? !kIsWeb;

  /// `this_device`: لا تنتقل عناصر Keychain إلى جهاز آخر عبر النسخ الاحتياطي.
  static const _defaultSecureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';
  static const _tokenTypeKey = 'auth.tokenType';
  static const _tokenKeys = [_accessKey, _refreshKey, _tokenTypeKey];
  static const _rememberKey = 'auth.rememberMe';
  static const _rememberedEmployeeKey = 'auth.rememberedEmployeeNumber';

  /// كانت تُحفظ بنص صريح في إصدار سابق؛ تُحذف ولا تُكتب مجدداً.
  static const _legacyPasswordKey = 'auth.rememberedPassword';

  /// يغيب بعد إعادة التثبيت (عناصر Keychain تبقى بعد حذف التطبيق على iOS)،
  /// فتُحذف توكنات التثبيت السابق بدل استعادة جلسته.
  static const _secureStorageReadyKey = 'auth.secureStorageReady';

  final FlutterSecureStorage _secure;
  final bool _useSecure;
  Future<SharedPreferences>? _prefsReady;
  Future<void>? _secureReady;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
  }) async {
    final values = {
      _accessKey: accessToken,
      _refreshKey: refreshToken,
      _tokenTypeKey: tokenType,
    };
    if (!_useSecure) {
      final prefs = await _prefs();
      for (final entry in values.entries) {
        await prefs.setString(entry.key, entry.value);
      }
      return;
    }
    await _ensureSecureStorage();
    for (final entry in values.entries) {
      await _secure.write(key: entry.key, value: entry.value);
    }
  }

  Future<String?> readAccessToken() => _readToken(_accessKey);

  Future<String?> readRefreshToken() => _readToken(_refreshKey);

  Future<void> clear() async {
    final prefs = await _prefs();
    for (final key in _tokenKeys) {
      await prefs.remove(key);
    }
    if (!_useSecure) return;
    await _ensureSecureStorage();
    for (final key in _tokenKeys) {
      await _secure.delete(key: key);
    }
  }

  /// «تذكرني»: يحفظ رقم الموظف فقط.
  Future<void> saveRememberedEmployeeNumber({
    required bool remember,
    required String employeeNumber,
  }) async {
    final prefs = await _prefs();
    final number = employeeNumber.trim();
    await prefs.setBool(_rememberKey, remember);
    if (!remember || number.isEmpty) {
      await prefs.remove(_rememberedEmployeeKey);
    } else {
      await prefs.setString(_rememberedEmployeeKey, number);
    }
  }

  Future<bool> readRememberMe() async {
    final prefs = await _prefs();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<String?> readRememberedEmployeeNumber() async {
    final prefs = await _prefs();
    if (!(prefs.getBool(_rememberKey) ?? false)) return null;
    final value = prefs.getString(_rememberedEmployeeKey)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<String?> _readToken(String key) async {
    if (!_useSecure) return (await _prefs()).getString(key);
    await _ensureSecureStorage();
    return _secure.read(key: key);
  }

  Future<SharedPreferences> _prefs() => _prefsReady ??= _openPrefs();

  Future<SharedPreferences> _openPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyPasswordKey);
      return prefs;
    } catch (_) {
      _prefsReady = null;
      rethrow;
    }
  }

  Future<void> _ensureSecureStorage() =>
      _secureReady ??= _moveTokensToSecureStorage();

  /// ينقل توكنات الإصدارات السابقة من SharedPreferences فتبقى الجلسة بعد التحديث.
  Future<void> _moveTokensToSecureStorage() async {
    try {
      final prefs = await _prefs();
      if (!(prefs.getBool(_secureStorageReadyKey) ?? false)) {
        for (final key in _tokenKeys) {
          await _secure.delete(key: key);
        }
      }
      for (final key in _tokenKeys) {
        final value = prefs.getString(key);
        if (value == null) continue;
        if (value.isNotEmpty) await _secure.write(key: key, value: value);
        await prefs.remove(key);
      }
      await prefs.setBool(_secureStorageReadyKey, true);
    } catch (_) {
      _secureReady = null;
      rethrow;
    }
  }
}
