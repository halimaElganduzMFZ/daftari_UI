import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// يدير وضع المظهر (فاتح/داكن) ويحفظه محلياً ليُستعاد عند فتح التطبيق.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'appearance.themeMode';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  /// يُستدعى مرة قبل `runApp` حتى تُرسم أول شاشة بالوضع الصحيح.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _mode = raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      _mode = ThemeMode.light;
    }
    AppColors.applyPalette(isDark ? AppPalette.dark : AppPalette.light);
  }

  Future<void> setDark(bool dark) =>
      setMode(dark ? ThemeMode.dark : ThemeMode.light);

  Future<void> toggle() => setDark(!isDark);

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    AppColors.applyPalette(isDark ? AppPalette.dark : AppPalette.light);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
    } catch (_) {
      // فشل الحفظ لا يمنع تطبيق الوضع في الجلسة الحالية.
    }
  }
}
