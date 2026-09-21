import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../models/healthcare_provider.dart';

/// مظهر التصنيفات الطبية (أيقونة ولون) بترتيب صفحة
/// `Contracted_Healthcare_Providers.php` القديمة (1، 3، 4، 2، 5، 6، 8، 7)،
/// وبيانات تجريبية للوضع الثابت.
abstract final class StaticHealthcare {
  static const specialties = <HealthcareSpecialty>[
    HealthcareSpecialty(
      id: 1,
      title: 'مستشفى متكامل',
      subtitle: 'متعدد التخصصات',
      icon: FontAwesomeIcons.hospital,
      accent: AppColors.goldDeep,
    ),
    HealthcareSpecialty(
      id: 3,
      title: 'تأهيل وعلاج طبيعي',
      subtitle: 'مراكز إعادة تأهيل',
      icon: FontAwesomeIcons.handHoldingMedical,
      accent: Color(0xFF5C738A),
    ),
    HealthcareSpecialty(
      id: 4,
      title: 'طب الأسنان',
      subtitle: 'مستشفيات وعيادات',
      icon: FontAwesomeIcons.tooth,
      accent: Color(0xFF6B8F71),
    ),
    HealthcareSpecialty(
      id: 2,
      title: 'مختبرات تحاليل',
      subtitle: 'فحوصات مخبرية',
      icon: FontAwesomeIcons.flaskVial,
      accent: Color(0xFF8B6B4F),
    ),
    HealthcareSpecialty(
      id: 5,
      title: 'بصريات ونظارات',
      subtitle: 'فحص وتركيب',
      icon: FontAwesomeIcons.glasses,
      accent: Color(0xFF6A7A8C),
    ),
    HealthcareSpecialty(
      id: 6,
      title: 'جلدية وتجميل',
      subtitle: 'مراكز ومصحات',
      icon: FontAwesomeIcons.spa,
      accent: Color(0xFF9A6B5C),
    ),
    HealthcareSpecialty(
      id: 8,
      title: 'عظام وكسور',
      subtitle: 'مستشفيات متخصصة',
      icon: FontAwesomeIcons.bone,
      accent: Color(0xFF7A6B5A),
    ),
    HealthcareSpecialty(
      id: 7,
      title: 'ذوي الاحتياجات',
      subtitle: 'تأهيل وتدريب',
      icon: FontAwesomeIcons.wheelchair,
      accent: Color(0xFF5A6F7A),
    ),
  ];

  static const _fallback = HealthcareSpecialty(
    id: 0,
    title: 'تصنيف آخر',
    subtitle: 'مؤسسات متعاقدة',
    icon: FontAwesomeIcons.building,
    accent: AppColors.slate,
  );

  static HealthcareSpecialty specialtyById(int id) {
    for (final s in specialties) {
      if (s.id == id) return s;
    }
    return _fallback;
  }

  /// بيانات تجريبية بنفس شكل `hospitals` (اسم – عنوان في حقل واحد).
  static const providers = <HealthcareProvider>[
    HealthcareProvider(
      id: 1,
      category: 1,
      details: 'مستشفى النخبة التخصصي – مصراتة، حي الشهداء، مقابل ميدان الساعة',
      mapUrl: 'https://maps.google.com/?q=Misrata',
    ),
    HealthcareProvider(
      id: 2,
      category: 1,
      details: 'مجمّع الشاطئ الطبي – مصراتة، شارع طرابلس الغربي',
      mapUrl: 'https://maps.google.com/?q=Misrata+Hospital',
    ),
    HealthcareProvider(
      id: 3,
      category: 1,
      details: 'مستشفى الأمل العام – مصراتة، طريق الميناء',
    ),
    HealthcareProvider(
      id: 4,
      category: 3,
      details: 'مركز الحركة للتأهيل – مصراتة، حي الزاوية',
    ),
    HealthcareProvider(
      id: 5,
      category: 3,
      details: 'عيادة التوازن الحركي – مصراتة، شارع عمر المختار',
    ),
    HealthcareProvider(
      id: 6,
      category: 4,
      details: 'مستشفى ابتسامة لطب الأسنان – مصراتة، وسط المدينة',
      mapUrl: 'https://maps.google.com/?q=Misrata+Dental',
    ),
    HealthcareProvider(
      id: 7,
      category: 4,
      details: 'عيادات اللؤلؤة لطب الأسنان – مصراتة، حي اليرموك',
    ),
    HealthcareProvider(
      id: 8,
      category: 2,
      details: 'مختبر الدقة للتحاليل – مصراتة، شارع الجمهورية',
    ),
    HealthcareProvider(
      id: 9,
      category: 2,
      details: 'مختبر الحياة الطبي – مصراتة، قرب كلية الطب',
    ),
    HealthcareProvider(
      id: 10,
      category: 5,
      details: 'مركز الرؤية للبصريات – مصراتة، مجمع الأسواق',
    ),
    HealthcareProvider(
      id: 11,
      category: 5,
      details: 'بصريات النور – مصراتة، شارع بنغازي',
    ),
    HealthcareProvider(
      id: 12,
      category: 6,
      details: 'مصحة البشرة التخصصية – مصراتة، حي الجامعة',
    ),
    HealthcareProvider(
      id: 13,
      category: 8,
      details: 'مستشفى العظام والكسور – مصراتة، الطريق الساحلي',
      mapUrl: 'https://maps.google.com/?q=Misrata+Ortho',
    ),
    HealthcareProvider(
      id: 14,
      category: 8,
      details: 'مركز العمود الفقري – مصراتة، حي الدافنية',
    ),
    HealthcareProvider(
      id: 15,
      category: 7,
      details: 'مركز الأمل للتأهيل – مصراتة، حي السلام',
    ),
  ];
}
