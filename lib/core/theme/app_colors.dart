import 'package:flutter/material.dart';

/// ذهب + رمادي هادئ — مريح للعين واحترافي للاستخدام اليومي.
abstract final class AppColors {
  /// خلفية عامة فاتحة مائلة للرمادي الدافئ (ليست كريمية صاخبة).
  static const background = Color(0xFFF3F3F1);

  /// سطح البطاقات والحقول.
  static const surface = Color(0xFFFAFAF9);

  /// رمادي داكن للعناوين.
  static const charcoal = Color(0xFF2F2F2F);

  /// رمادي متوسط للنصوص الثانوية (4.5:1 على الخلفيات الفاتحة).
  static const slate = Color(0xFF6A6A6A);

  /// خطوط فاصلة ناعمة.
  static const line = Color(0xFFE2E0DC);

  /// ذهب هادئ (أساسي للتفاعل والتمييز).
  static const gold = Color(0xFFB08D57);

  /// ذهب أعمق للعناوين/الحالات المحددة وخلفية الأزرار الممتلئة: 4.5:1 كنص على
  /// الخلفيات الفاتحة (ومنها [goldSoft])، وللنص الأبيض فوقه.
  static const goldDeep = Color(0xFF80643C);

  /// خلفية الشريحة المحددة: أفتح قليلاً من [gold] ليُقرأ عليها النص الداكن (4.5:1).
  static const goldChip = Color(0xFFB4925F);

  /// لمسة ذهبية خفيفة للخلفيات.
  static const goldSoft = Color(0xFFF3EADA);

  // ألوان الحالات: 4.5:1 كنص على الخلفيات الفاتحة وعلى خلفيات شارات الحالة.
  static const success = Color(0xFF4B7455);
  static const warning = Color(0xFF876208);
  static const danger = Color(0xFF975656);
  static const info = Color(0xFF566C82);
}
