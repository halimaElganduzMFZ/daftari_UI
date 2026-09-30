import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// مظهر تصنيف طبي في التطبيق (أيقونة ولون) — يُطابَق برقم `hospitals.category`.
class HealthcareSpecialty {
  const HealthcareSpecialty({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final int id;
  final String title;
  final String subtitle;
  final FaIconData icon;
  final Color accent;
}

/// تصنيف كما يعيده الـ API (`HealthcareCategoryDto`) مع عدد المؤسسات.
class HealthcareCategory {
  const HealthcareCategory({
    required this.id,
    required this.count,
    this.name,
    this.icon,
  });

  factory HealthcareCategory.fromApi(Map<String, dynamic> json) => HealthcareCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?)?.trim(),
        icon: json['icon'] as String?,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final int id;

  /// التسمية القديمة (مثل «مستشفى متكامل متعدد التخصصات»)؛ null لرقم غير معروف.
  final String? name;

  /// اسم أيقونة Font Awesome القديمة بدون `fa-`.
  final String? icon;
  final int count;
}

/// مؤسسة طبية متعاقدة (`HealthcareProviderDto` من `hospitals`).
class HealthcareProvider {
  const HealthcareProvider({
    required this.id,
    required this.category,
    required this.details,
    this.categoryName,
    this.mapUrl,
    this.imageUrl,
  });

  factory HealthcareProvider.fromApi(Map<String, dynamic> json) => HealthcareProvider(
        id: (json['id'] as num?)?.toInt() ?? 0,
        category: (json['category'] as num?)?.toInt() ?? 0,
        categoryName: (json['categoryName'] as String?)?.trim(),
        details: (json['details'] as String? ?? '').trim(),
        mapUrl: json['mapUrl'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );

  final int id;
  final int category;
  final String? categoryName;

  /// الاسم والعنوان كما هما مخزّنان في حقل واحد (`hospitals.details`).
  final String details;
  final String? mapUrl;
  final String? imageUrl;

  /// السطر الأول من التفاصيل (الاسم غالباً).
  String get title {
    final line = details.split(RegExp(r'[\n\r]|\s[–\-—]\s')).first.trim();
    return line.isEmpty ? details : line;
  }

  /// ما تبقى بعد السطر الأول (العنوان/الوصف) أو فارغ.
  String get subtitle {
    final t = title;
    if (t.length >= details.length) return '';
    return details.substring(t.length).replaceFirst(RegExp(r'^[\s–\-—:،]+'), '').trim();
  }

  bool get hasMap => mapUrl != null && mapUrl!.isNotEmpty;
}

/// صفحة من قائمة المؤسسات (`{ data, meta }`).
class HealthcareProvidersPage {
  const HealthcareProvidersPage({
    required this.items,
    required this.page,
    required this.hasNext,
    this.total,
  });

  factory HealthcareProvidersPage.fromApi(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return HealthcareProvidersPage(
      items: [
        for (final item in (json['data'] as List?) ?? const [])
          if (item is Map<String, dynamic>) HealthcareProvider.fromApi(item),
      ],
      page: (meta['page'] as num?)?.toInt() ?? 1,
      hasNext: meta['hasNext'] as bool? ?? false,
      total: (meta['total'] as num?)?.toInt(),
    );
  }

  final List<HealthcareProvider> items;
  final int page;
  final bool hasNext;
  final int? total;
}
