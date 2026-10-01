import 'package:flutter/material.dart';

/// لوحة ألوان كاملة لوضع واحد (فاتح أو داكن).
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.charcoal,
    required this.slate,
    required this.line,
    required this.gold,
    required this.goldDeep,
    required this.goldSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.backdropStart,
    required this.backdropMid,
    required this.backdropEnd,
    required this.headerStart,
    required this.headerMid,
    required this.headerEnd,
    required this.glowA,
    required this.glowB,
    required this.shadow,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color charcoal;
  final Color slate;
  final Color line;
  final Color gold;
  final Color goldDeep;
  final Color goldSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// تدرّج خلفيات الشاشات الكاملة (الدخول / تحديد نوع الدخول / البداية).
  final Color backdropStart;
  final Color backdropMid;
  final Color backdropEnd;

  /// تدرّج رأس الترحيب في الرئيسية.
  final Color headerStart;
  final Color headerMid;
  final Color headerEnd;

  /// هالات ذهبية ناعمة خلف شاشات الدخول.
  final Color glowA;
  final Color glowB;

  /// ظل البطاقات.
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  /// ذهب + رمادي هادئ — مريح للعين واحترافي للاستخدام اليومي.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF3F3F1),
    surface: Color(0xFFFAFAF9),
    charcoal: Color(0xFF2F2F2F),
    slate: Color(0xFF6F6F6F),
    line: Color(0xFFE2E0DC),
    gold: Color(0xFFB08D57),
    goldDeep: Color(0xFF8F7043),
    goldSoft: Color(0xFFF3EADA),
    success: Color(0xFF4F7A5A),
    warning: Color(0xFFB8860B),
    danger: Color(0xFFA15C5C),
    info: Color(0xFF5C738A),
    backdropStart: Color(0xFFE9E6DF),
    backdropMid: Color(0xFFF3F3F1),
    backdropEnd: Color(0xFFE4E1DA),
    headerStart: Color(0xFFF7F1E6),
    headerMid: Color(0xFFEFEFEA),
    headerEnd: Color(0xFFE8E8E4),
    glowA: Color(0x33B08D57),
    glowB: Color(0x22A18F6A),
    shadow: Color(0x18000000),
  );

  /// وضع داكن دافئ — فحمي مائل للبني مع ذهب أفتح للتباين.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF151413),
    surface: Color(0xFF1F1E1C),
    charcoal: Color(0xFFEDEAE4),
    slate: Color(0xFFA8A39B),
    line: Color(0xFF34322E),
    gold: Color(0xFFC9A66C),
    goldDeep: Color(0xFFE1C68F),
    goldSoft: Color(0xFF2E2922),
    success: Color(0xFF86B993),
    warning: Color(0xFFDDAE45),
    danger: Color(0xFFD48A8A),
    info: Color(0xFF93ADC6),
    backdropStart: Color(0xFF1B1A18),
    backdropMid: Color(0xFF151413),
    backdropEnd: Color(0xFF1E1C19),
    headerStart: Color(0xFF2A251E),
    headerMid: Color(0xFF232120),
    headerEnd: Color(0xFF1F1E1C),
    glowA: Color(0x2EC9A66C),
    glowB: Color(0x1FB08D57),
    shadow: Color(0x55000000),
  );
}

/// ألوان التطبيق — تُقرأ من اللوحة الحالية (فاتح/داكن) وتتبدل مع الوضع.
///
/// الأسماء ثابتة عبر الشاشات؛ التبديل يتم عبر [ThemeController] فقط.
abstract final class AppColors {
  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;

  static bool get isDark => _palette.isDark;

  /// يُستدعى من ThemeController فقط.
  static void applyPalette(AppPalette palette) {
    _palette = palette;
  }

  /// خلفية عامة.
  static Color get background => _palette.background;

  /// سطح البطاقات والحقول.
  static Color get surface => _palette.surface;

  /// لون النص الأساسي / العناوين.
  static Color get charcoal => _palette.charcoal;

  /// نص ثانوي.
  static Color get slate => _palette.slate;

  /// خطوط فاصلة ناعمة.
  static Color get line => _palette.line;

  /// ذهب هادئ (أساسي للتفاعل والتمييز).
  static Color get gold => _palette.gold;

  /// ذهب أعمق للعناوين/الحالات المحددة.
  static Color get goldDeep => _palette.goldDeep;

  /// لمسة ذهبية خفيفة للخلفيات.
  static Color get goldSoft => _palette.goldSoft;

  static Color get success => _palette.success;
  static Color get warning => _palette.warning;
  static Color get danger => _palette.danger;
  static Color get info => _palette.info;

  static Color get backdropStart => _palette.backdropStart;
  static Color get backdropMid => _palette.backdropMid;
  static Color get backdropEnd => _palette.backdropEnd;

  static Color get headerStart => _palette.headerStart;
  static Color get headerMid => _palette.headerMid;
  static Color get headerEnd => _palette.headerEnd;

  static Color get glowA => _palette.glowA;
  static Color get glowB => _palette.glowB;
  static Color get shadow => _palette.shadow;

  /// لون النص فوق الأزرار الذهبية.
  static Color get onGold =>
      _palette.isDark ? const Color(0xFF1A1813) : Colors.white;
}
