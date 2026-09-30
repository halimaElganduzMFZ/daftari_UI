import 'package:employee_affairs/data/auth/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const secure = FlutterSecureStorage();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('remember me keeps only the employee number and purges an old password',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth.rememberMe': true,
      'auth.rememberedEmployeeNumber': '1001',
      'auth.rememberedPassword': 'old-secret',
    });
    final storage = TokenStorage();

    expect(await storage.readRememberedEmployeeNumber(), '1001');
    await storage.saveRememberedEmployeeNumber(
      remember: true,
      employeeNumber: ' 2002 ',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth.rememberedEmployeeNumber'), '2002');
    expect(
      prefs.getKeys().where((key) => key.toLowerCase().contains('password')),
      isEmpty,
    );
  });

  test('turning remember me off forgets the employee number', () async {
    SharedPreferences.setMockInitialValues({
      'auth.rememberMe': true,
      'auth.rememberedEmployeeNumber': '1001',
    });
    final storage = TokenStorage();

    await storage.saveRememberedEmployeeNumber(
      remember: false,
      employeeNumber: '1001',
    );

    expect(await storage.readRememberMe(), isFalse);
    expect(await storage.readRememberedEmployeeNumber(), isNull);
  });

  test('an app update moves stored tokens into secure storage', () async {
    SharedPreferences.setMockInitialValues({
      'auth.accessToken': 'access-1',
      'auth.refreshToken': 'refresh-1',
      'auth.tokenType': 'Bearer',
    });
    final storage = TokenStorage();

    expect(await storage.readAccessToken(), 'access-1');
    expect(await storage.readRefreshToken(), 'refresh-1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth.accessToken'), isNull);
    expect(prefs.getString('auth.refreshToken'), isNull);
    expect(prefs.getString('auth.tokenType'), isNull);
    expect(await secure.read(key: 'auth.accessToken'), 'access-1');
    expect(await secure.read(key: 'auth.tokenType'), 'Bearer');
  });

  test('tokens are saved and cleared only in secure storage', () async {
    final storage = TokenStorage();
    await storage.save(
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
      tokenType: 'Bearer',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth.accessToken'), isNull);
    expect(await storage.readAccessToken(), 'access-2');

    await storage.clear();
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await secure.read(key: 'auth.tokenType'), isNull);
  });

  test('a fresh install ignores keychain tokens left by a previous install',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth.accessToken': 'stale-access',
      'auth.refreshToken': 'stale-refresh',
    });

    expect(await TokenStorage().readAccessToken(), isNull);
    expect(await secure.read(key: 'auth.refreshToken'), isNull);
  });

  test('a stored session survives later launches', () async {
    SharedPreferences.setMockInitialValues({'auth.secureStorageReady': true});
    FlutterSecureStorage.setMockInitialValues({'auth.accessToken': 'live'});

    expect(await TokenStorage().readAccessToken(), 'live');
  });

  test('web keeps tokens in shared preferences', () async {
    final storage = TokenStorage(useSecureStorage: false);
    await storage.save(
      accessToken: 'access-3',
      refreshToken: 'refresh-3',
      tokenType: 'Bearer',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth.accessToken'), 'access-3');
    expect(await secure.read(key: 'auth.accessToken'), isNull);
  });
}
