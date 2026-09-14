import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/leave_kind.dart';
import '../models/permission_type.dart';

/// أنواع الإجازات وضوابطها — من Taking_a_day_off.php (regulationsData).
abstract final class StaticLeaveKinds {
  static const List<LeaveKind> all = [
    LeaveKind(
      id: 'annual',
      title: 'إجازة سنوية',
      subtitle: 'من الرصيد السنوي — مع تحديد مكان القضاء',
      icon: FontAwesomeIcons.calendarCheck,
      needsLocation: true,
      points: [
        RegulationPoint(
          article: 'م28',
          text:
              'الإجازة السنوية: 30 يوماً للعامل، و45 يوماً لمن بلغ سن الخمسين أو جاوزت مدة خدمته 20 سنة.',
        ),
        RegulationPoint(
          article: 'م28',
          text:
              'لا يجوز تأجيل الإجازة أو قطعها إلا لضرورة قصوى وبموافقة رئيس لجنة الإدارة.',
        ),
        RegulationPoint(
          article: 'م28',
          text:
              'يجب التمتع بـ15 يوماً على الأقل سنوياً، وإلا سقط الحق فيها وشُطبت من الرصيد إذا أُخطر العامل بالخروج لمصلحة العمل ولم يستجب.',
        ),
        RegulationPoint(
          article: 'م28',
          text:
              'الحد الأقصى للحفظ: 15 يوماً في السنة، و180 يوماً طوال مدة الخدمة.',
        ),
        RegulationPoint(
          article: 'م31',
          text:
              'يُصرف تعويض نقدي عن الرصيد المتراكم عند انتهاء الخدمة، أو بناءً على طلب العامل عما زاد عن شهر بحد أقصى 180 يوماً.',
        ),
      ],
      fullText:
          'الإجازة السنوية 30 يوماً (45 يوماً لمن بلغ الخمسين أو أتم 20 سنة خدمة)، تُحدَّد مواعيدها بالتنسيق مع الإدارة. الحد الأقصى للحفظ 15 يوماً سنوياً و180 يوماً طوال الخدمة، وتُعوَّض نقدياً عند انتهاء العمل أو عند الطلب.',
    ),
    LeaveKind(
      id: 'emergency',
      title: 'إجازة طارئة',
      subtitle: 'لأسباب قهرية — يُذكر السبب',
      icon: FontAwesomeIcons.bolt,
      needsEmergencyReason: true,
      points: [
        RegulationPoint(
          article: 'م36',
          text: 'الإجازة الطارئة لسبب قهري — يجب إبلاغ الرؤساء مقدماً ما أمكن.',
        ),
        RegulationPoint(
          article: 'م36',
          text:
              'الحد الأقصى في المرة الواحدة: 3 أيام، ولا تتجاوز في مجموعها 12 يوماً في السنة.',
        ),
        RegulationPoint(
          article: 'م36',
          text:
              'حالة وفاة الزوج/الزوجة أو قريب حتى الدرجة الثانية أو أحد أبوَي الزوجين: أسبوع في المرة.',
        ),
        RegulationPoint(
          article: 'م36',
          text: 'حالة وفاة قريب حتى الدرجة الرابعة: 3 أيام في المرة.',
        ),
        RegulationPoint(
          article: 'م36',
          text: 'يسقط الحق بمضي السنة.',
        ),
      ],
      fullText:
          'الإجازة الطارئة تُمنح للأسباب القهرية. حالات الوفاة لها أحكام خاصة بمدد مختلفة حسب درجة القرابة.',
    ),
    LeaveKind(
      id: 'study',
      title: 'إجازة دراسية',
      subtitle: 'أداء امتحانات — يُرفق مستند الإثبات',
      icon: FontAwesomeIcons.graduationCap,
      needsStudyAttachment: true,
      points: [
        RegulationPoint(
          article: 'م37',
          text: 'إجازة أداء الامتحانات تُمنح بقرار من رئيس لجنة الإدارة.',
        ),
        RegulationPoint(
          article: 'م37',
          text: 'يُصرف المرتب فقط إذا نجح العامل في الامتحان.',
        ),
        RegulationPoint(
          article: 'م37',
          text:
              'يُشترط تقديم شهادة من الجهة المختصة تُثبت الاشتراك في الامتحان والمدة المحددة له.',
        ),
      ],
      fullText:
          'يجب إرفاق شهادة القيد وجدول الامتحانات. صرف المرتب مشروط بإثبات النجاح.',
    ),
    LeaveKind(
      id: 'maternity',
      title: 'إجازة وضع',
      subtitle: '90 يوماً بمرتب كامل',
      icon: FontAwesomeIcons.baby,
      fixedDays: 90,
      points: [
        RegulationPoint(
          article: 'م32',
          text:
              'إجازة الوضع: مرتب كامل (100٪) لمدة ثلاثة أشهر، شاملة فترة الغياب قبل الوضع وبعده.',
        ),
        RegulationPoint(
          article: 'م32',
          text: 'تُمنح بناءً على تقرير طبي من جهة مختصة.',
        ),
      ],
      fullText:
          'مدة إجازة الوضع ثلاثة أشهر بمرتب كامل، تشمل فترة الغياب قبل الولادة وبعدها.',
    ),
    LeaveKind(
      id: 'idda',
      title: 'إجازة العدة',
      subtitle: '4 أشهر و10 أيام بمرتب كامل',
      icon: FontAwesomeIcons.moon,
      fixedDays: 130,
      points: [
        RegulationPoint(
          article: 'م34/بند3',
          text:
              'إجازة العدة: أربعة أشهر وعشرة أيام للمتوفَّى عنها زوجها، بمرتب كامل.',
        ),
      ],
      fullText:
          'إجازة العدة مخصصة للزوجة عند وفاة زوجها، بأجر كامل طوال المدة المقررة شرعاً.',
    ),
    LeaveKind(
      id: 'hajj',
      title: 'إجازة الحج',
      subtitle: '45 يوماً — مرة واحدة طوال الخدمة',
      icon: FontAwesomeIcons.kaaba,
      fixedDays: 45,
      points: [
        RegulationPoint(
          article: 'م34/بند1',
          text:
              'إجازة الحج: 45 يوماً بمرتب كامل — مرة واحدة فقط طوال مدة الخدمة.',
        ),
      ],
      fullText:
          'تُمنح إجازة الحج مرة واحدة فقط طوال فترة الخدمة، ولا تحسب ضمن رصيد الإجازات السنوية.',
    ),
    LeaveKind(
      id: 'marriage',
      title: 'إجازة الزواج',
      subtitle: '15 يوماً — مرة واحدة طوال الخدمة',
      icon: FontAwesomeIcons.ring,
      fixedDays: 15,
      points: [
        RegulationPoint(
          article: 'م34/بند2',
          text:
              'إجازة الزواج: 15 يوماً بمرتب كامل — مرة واحدة فقط طوال مدة الخدمة.',
        ),
      ],
      fullText: 'تُمنح إجازة الزواج مرة واحدة فقط طوال فترة الخدمة.',
    ),
  ];
}
