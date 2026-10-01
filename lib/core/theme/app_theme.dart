import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light);

  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    const family = 'Cairo';
    final isDark = p.isDark;
    final onGold = isDark ? const Color(0xFF1A1813) : Colors.white;

    final scheme = isDark
        ? ColorScheme.dark(
            primary: p.gold,
            onPrimary: onGold,
            secondary: p.goldDeep,
            onSecondary: onGold,
            surface: p.surface,
            onSurface: p.charcoal,
            outline: p.line,
            error: p.danger,
          )
        : ColorScheme.light(
            primary: p.gold,
            onPrimary: onGold,
            secondary: p.charcoal,
            onSecondary: Colors.white,
            surface: p.surface,
            onSurface: p.charcoal,
            outline: p.line,
            error: p.danger,
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: family,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: family,
        bodyColor: p.charcoal,
        displayColor: p.charcoal,
      ),
      iconTheme: IconThemeData(color: p.charcoal),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: p.background,
        foregroundColor: p.charcoal,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.charcoal,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        indicatorColor: p.goldSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: family,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.goldDeep : p.slate,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? p.goldDeep : p.slate,
            size: 22,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.gold,
          foregroundColor: onGold,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.goldDeep,
          side: BorderSide(color: p.line),
          textStyle: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.goldDeep),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.slate),
        labelStyle: TextStyle(color: p.slate),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.gold, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? p.goldSoft : p.charcoal,
        contentTextStyle: TextStyle(
          fontFamily: family,
          color: isDark ? p.charcoal : Colors.white,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.goldSoft,
        selectedColor: p.gold,
        labelStyle: TextStyle(
          fontFamily: family,
          color: p.charcoal,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.goldDeep : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.gold.withValues(alpha: .45)
              : null,
        ),
      ),
    );
  }
}
