import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/healthcare_provider.dart';
import '../../core/theme/app_colors.dart';

/// تخصصات ومؤسسات طبية متعاقدة مع المنطقة الحرة بمصراتة.
abstract final class StaticHealthcare {
  static final specialties = <HealthcareSpecialty>[
    HealthcareSpecialty(
      id: '1',
      title: 'مستشفى متكامل',
      subtitle: 'متعدد التخصصات',
      icon: FontAwesomeIcons.building,
      accent: AppColors.goldDeep,
    ),
    HealthcareSpecialty(
      id: '3',
      title: 'تأهيل وعلاج طبيعي',
      subtitle: 'مراكز إعادة تأهيل',
      icon: FontAwesomeIcons.heartPulse,
      accent: Color(0xFF5C738A),
    ),
    HealthcareSpecialty(
      id: '4',
      title: 'طب الأسنان',
      subtitle: 'مستشفيات وعيادات',
      icon: FontAwesomeIcons.tooth,
      accent: Color(0xFF6B8F71),
    ),
    HealthcareSpecialty(
      id: '2',
      title: 'مختبرات تحاليل',
      subtitle: 'فحوصات مخبرية',
      icon: FontAwesomeIcons.flaskVial,
      accent: Color(0xFF8B6B4F),
    ),
    HealthcareSpecialty(
      id: '5',
      title: 'بصريات ونظارات',
      subtitle: 'فحص وتركيب',
      icon: FontAwesomeIcons.eye,
      accent: Color(0xFF6A7A8C),
    ),
    HealthcareSpecialty(
      id: '6',
      title: 'جلدية وتجميل',
      subtitle: 'مراكز ومصحات',
      icon: FontAwesomeIcons.spa,
      accent: Color(0xFF9A6B5C),
    ),
    HealthcareSpecialty(
      id: '8',
      title: 'عظام وكسور',
      subtitle: 'مستشفيات متخصصة',
      icon: FontAwesomeIcons.crutch,
      accent: Color(0xFF7A6B5A),
    ),
    HealthcareSpecialty(
      id: '7',
      title: 'ذوي الاحتياجات',
      subtitle: 'تأهيل وتدريب',
      icon: FontAwesomeIcons.wheelchair,
      accent: Color(0xFF5A6F7A),
    ),
  ];

  static final providers = <HealthcareProvider>[
    // متكامل
    HealthcareProvider(
      id: 'h1',
      specialtyId: '1',
      name: 'مستشفى النخبة التخصصي',
      summary:
          'مستشفى متكامل يقدّم خدمات الطوارئ والعيادات الخارجية والجراحة العامة لموظفي المنطقة الحرة.',
      address: 'مصراتة — حي الشهداء، مقابل ميدان الساعة',
      phone: '051-262-1100',
      hours: 'الطوارئ 24 ساعة · العيادات 08:00–20:00',
      mapUrl: 'https://maps.google.com/?q=Misrata',
      services: ['طوارئ', 'مختبر', 'أشعة', 'جراحة', 'باطنة'],
    ),
    HealthcareProvider(
      id: 'h2',
      specialtyId: '1',
      name: 'مجمّع الشاطئ الطبي',
      summary:
          'مجمّع طبي متعدد التخصصات بخدمات حجز ميسّرة لمنتسبي المنطقة الحرة بمصراتة.',
      address: 'مصراتة — شارع طرابلس الغربي',
      phone: '051-263-2200',
      hours: '08:00–22:00 يومياً',
      mapUrl: 'https://maps.google.com/?q=Misrata+Hospital',
      services: ['أطفال', 'نساء وولادة', 'قلب', 'صيدلية'],
    ),
    HealthcareProvider(
      id: 'h3',
      specialtyId: '1',
      name: 'مستشفى الأمل العام',
      summary: 'رعاية شاملة مع أقسام تنويم وعيادات تخصصية واتفاقيات تأمين موظفين.',
      address: 'مصراتة — طريق الميناء',
      phone: '051-261-4500',
      hours: 'الطوارئ 24 ساعة',
      services: ['تنويم', 'عناية مركزة', 'غسيل كلى'],
    ),
    // علاج طبيعي
    HealthcareProvider(
      id: 'h4',
      specialtyId: '3',
      name: 'مركز الحركة للتأهيل',
      summary: 'جلسات علاج طبيعي وإعادة تأهيل بعد الإصابات والعمليات.',
      address: 'مصراتة — حي الزاوية',
      phone: '091-700-1122',
      hours: '09:00–18:00 · الجمعة عطلة',
      services: ['علاج طبيعي', 'تمارين علاجية', 'مساج طبي'],
    ),
    HealthcareProvider(
      id: 'h5',
      specialtyId: '3',
      name: 'عيادة التوازن الحركي',
      summary: 'تخصص في إصابات المفاصل والعمود الفقري وبرامج تقوية عضلية.',
      address: 'مصراتة — شارع عمر المختار',
      phone: '092-555-3344',
      hours: '10:00–19:00',
      services: ['تأهيل رياضي', 'ليزر علاجي'],
    ),
    // أسنان
    HealthcareProvider(
      id: 'h6',
      specialtyId: '4',
      name: 'مستشفى ابتسامة لطب الأسنان',
      summary: 'زراعة وتقويم وتجميل أسنان بتقنيات حديثة ضمن التعاقد.',
      address: 'مصراتة — وسط المدينة',
      phone: '051-262-7788',
      hours: '09:00–21:00',
      mapUrl: 'https://maps.google.com/?q=Misrata+Dental',
      services: ['زراعة', 'تقويم', 'تبييض', 'جراحة فم'],
    ),
    HealthcareProvider(
      id: 'h7',
      specialtyId: '4',
      name: 'عيادات اللؤلؤة لطب الأسنان',
      summary: 'عيادات أسنان عائلية مع أولوية مواعيد لموظفي المنطقة الحرة.',
      address: 'مصراتة — حي اليرموك',
      phone: '091-222-9090',
      hours: '10:00–20:00',
      services: ['حشوات', 'تركيبات', 'أطفال'],
    ),
    // مختبرات
    HealthcareProvider(
      id: 'h8',
      specialtyId: '2',
      name: 'مختبر الدقة للتحاليل',
      summary: 'تحاليل دم وهرمونات ومزارع بتقارير رقمية سريعة.',
      address: 'مصراتة — شارع الجمهورية',
      phone: '051-260-1010',
      hours: '07:30–18:00',
      services: ['دم شامل', 'هرمونات', 'PCR'],
    ),
    HealthcareProvider(
      id: 'h9',
      specialtyId: '2',
      name: 'مختبر الحياة الطبي',
      summary: 'شبكة فروع مع خدمة سحب منزلي عند الطلب.',
      address: 'مصراتة — قرب كلية الطب',
      phone: '092-111-7070',
      hours: '08:00–20:00',
      services: ['كيمياء حيوية', 'مناعة'],
    ),
    // بصريات
    HealthcareProvider(
      id: 'h10',
      specialtyId: '5',
      name: 'مركز الرؤية للبصريات',
      summary: 'فحص نظر وتركيب عدسات ونظارات طبية ضمن التعاقد.',
      address: 'مصراتة — مجمع الأسواق',
      phone: '091-333-5566',
      hours: '10:00–22:00',
      services: ['فحص نظر', 'عدسات', 'إطارات'],
    ),
    HealthcareProvider(
      id: 'h11',
      specialtyId: '5',
      name: 'بصريات النور',
      summary: 'عدسات طبية وتجميليات مع ضمان على التركيب.',
      address: 'مصراتة — شارع بنغازي',
      phone: '092-444-1212',
      hours: '11:00–21:00',
      services: ['نظارات طبية', 'عدسات لاصقة'],
    ),
    // جلدية
    HealthcareProvider(
      id: 'h12',
      specialtyId: '6',
      name: 'مصحة البشرة التخصصية',
      summary: 'علاج جلدي وليزر وتجميل غير جراحي.',
      address: 'مصراتة — حي الجامعة',
      phone: '051-265-9090',
      hours: '12:00–21:00',
      services: ['جلدية', 'ليزر', 'عناية بشرة'],
    ),
    // عظام
    HealthcareProvider(
      id: 'h13',
      specialtyId: '8',
      name: 'مستشفى العظام والكسور',
      summary: 'كسور ومفاصل وتنظير مع تأهيل ما بعد الجراحة.',
      address: 'مصراتة — الطريق الساحلي',
      phone: '051-268-3030',
      hours: 'الطوارئ 24 ساعة',
      mapUrl: 'https://maps.google.com/?q=Misrata+Ortho',
      services: ['كسور', 'مفاصل', 'تنظير'],
    ),
    HealthcareProvider(
      id: 'h14',
      specialtyId: '8',
      name: 'مركز العمود الفقري',
      summary: 'تخصص دقيق في آلام الظهر والرقبة والديسك.',
      address: 'مصراتة — حي الدافنية',
      phone: '091-888-4040',
      hours: '09:00–17:00',
      services: ['عمود فقري', 'حقن علاجي'],
    ),
    // ذوي احتياجات
    HealthcareProvider(
      id: 'h15',
      specialtyId: '7',
      name: 'مركز الأمل للتأهيل',
      summary: 'برامج تأهيل وتدريب لذوي الاحتياجات الخاصة ودعم أسري.',
      address: 'مصراتة — حي السلام',
      phone: '092-600-8080',
      hours: '08:00–15:00 · الأحد–الخميس',
      services: ['تأهيل حركي', 'تخاطب', 'دعم نفسي'],
    ),
  ];

  static HealthcareSpecialty? specialtyById(String id) {
    for (final s in specialties) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<HealthcareProvider> bySpecialty(String specialtyId) => [
        for (final p in providers)
          if (p.specialtyId == specialtyId) p,
      ];

  static int countFor(String specialtyId) => bySpecialty(specialtyId).length;

  static HealthcareProvider? providerById(String id) {
    for (final p in providers) {
      if (p.id == id) return p;
    }
    return null;
  }
}
