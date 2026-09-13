import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/regulations_center.dart';

/// مركز اللوائح — من regulations-modal.php و single-reg-modal.php.
abstract final class StaticRegulationsCenter {
  static const List<RegulationTab> tabs = [
    RegulationTab(
      id: 'leaves',
      label: 'الإجازات',
      icon: FontAwesomeIcons.calendarDays,
      sections: [
        RegulationSection(
          title: 'الإجازة السنوية',
          items: [
            RegulationItem(
              article: 'م31',
              text:
                  'عند انتهاء الخدمة يُعوَّض العامل نقداً عن الإجازات السنوية المتراكمة فيما زاد على الشهر، بما لا يتجاوز 180 يوماً.',
            ),
          ],
        ),
        RegulationSection(
          title: 'الإجازة الطارئة',
          items: [
            RegulationItem(
              article: 'م36',
              text:
                  'الإجازة الطارئة لسبب قهري — يجب إبلاغ الرئيس المباشر مقدماً ما أمكن ذلك.',
            ),
            RegulationItem(
              article: 'م36',
              text:
                  'تكون بحدود 3 أيام في المرة الواحدة ولا يتجاوز مجموعها 12 يوماً في السنة.',
            ),
            RegulationItem(
              article: 'م36',
              text:
                  'وفاة الزوج/الزوجة أو قريب حتى الدرجة الثانية أو أحد أبوي الزوجين: أسبوع. وفاة قريب حتى الدرجة الرابعة: 3 أيام. يسقط الحق بمضي السنة.',
            ),
          ],
        ),
        RegulationSection(
          title: 'الإجازة المرضية وإجازة الوضع',
          items: [
            RegulationItem(
              article: 'م32',
              text: 'إصابة العمل: مرتب كامل (100٪) لمدة أقصاها سنتان.',
            ),
            RegulationItem(
              article: 'م32',
              text:
                  'المرض العادي: مرتب كامل حتى 15 يوماً، ثم 75٪ فيما زاد لمدة أقصاها سنة.',
            ),
            RegulationItem(
              article: 'م32',
              text:
                  'إجازة الوضع: مرتب كامل لمدة 3 أشهر شاملة فترة الغياب قبل الوضع وبعده.',
            ),
            RegulationItem(
              article: 'م33',
              text:
                  'إذا تجاوزت الإجازة المرضية 3 أشهر وجب العرض على اللجنة الطبية، وإذا ثبت العجز تنتهي الخدمة وتُصفّى المستحقات.',
            ),
          ],
        ),
        RegulationSection(
          title: 'الإجازات الخاصة بمرتب',
          items: [
            RegulationItem(
              article: 'م34',
              text: 'إجازة الحج: 45 يوماً بمرتب كامل — مرة واحدة طوال مدة الخدمة.',
            ),
            RegulationItem(
              article: 'م34',
              text: 'إجازة الزواج: 15 يوماً بمرتب كامل — مرة واحدة طوال مدة الخدمة.',
            ),
            RegulationItem(
              article: 'م34',
              text: 'إجازة العدة: 4 أشهر و10 أيام بمرتب كامل.',
            ),
            RegulationItem(
              article: 'م37',
              text:
                  'إجازة الامتحانات: يُصرف المرتب بشرط النجاح وتقديم شهادة تثبت الاشتراك والمدة.',
            ),
          ],
        ),
      ],
    ),
    RegulationTab(
      id: 'permissions',
      label: 'الأذونات',
      icon: FontAwesomeIcons.clock,
      sections: [
        RegulationSection(
          title: 'إذن خروج مبكر / إذن تأخير',
          items: [
            RegulationItem(
              article: 'م40',
              text:
                  'يُحظر على العامل الخروج من مقر العمل خلال أوقات العمل الرسمية أو الإضافية إلا بإذن خاص من رئيسه المباشر.',
            ),
            RegulationItem(
              article: 'م40',
              text:
                  'المغادرة بدون إذن تعدّ مخالفة تأديبية تستوجب المساءلة وفق لائحة الجزاءات.',
            ),
          ],
        ),
        RegulationSection(
          title: 'مهمة عمل / تفرغ عمل',
          items: [
            RegulationItem(
              article: 'م51',
              text:
                  'يجوز للجنة الإدارة ندب العاملين للقيام بمهام وظيفية أخرى على سبيل التفرغ أو بالإضافة إلى عملهم الأصلي.',
            ),
            RegulationItem(
              article: 'م101',
              text:
                  'تُصرف علاوة الإيفاد والمبيت وفق نظام تضعه لجنة الإدارة يراعي التكاليف الفعلية وطبيعة العمل.',
            ),
            RegulationItem(
              article: 'م102',
              text:
                  'يقدم الموفد طلبه على النموذج المعد مرفقاً بقرار التكليف، ويُحال إلى مدير الإدارة ثم إلى الشؤون المالية.',
            ),
            RegulationItem(
              article: 'م104',
              text:
                  'يجوز صرف سلفة على حساب علاوة الإيفاد لا تتجاوز العلاوة المستحقة، وتُسوّى خلال شهر من تاريخ العودة.',
            ),
          ],
        ),
        RegulationSection(
          title: 'العمل الإضافي',
          items: [
            RegulationItem(
              article: 'م50',
              text: 'لا يجوز أن تزيد ساعات العمل الإضافي على 3 ساعات في اليوم الواحد.',
            ),
            RegulationItem(
              article: 'م50',
              text:
                  'أيام العمل العادية: +50٪. العطلات الأسبوعية والرسمية: +100٪ من أجر الساعة.',
            ),
          ],
        ),
      ],
    ),
    RegulationTab(
      id: 'fingerprint',
      label: 'البصمات',
      icon: FontAwesomeIcons.fingerprint,
      sections: [
        RegulationSection(
          title: 'أحكام الحضور والانصراف',
          items: [
            RegulationItem(
              article: 'م54',
              text:
                  'تُحدد مواعيد الحضور والانصراف بقرار من رئيس لجنة الإدارة لجميع العاملين.',
            ),
            RegulationItem(
              article: 'م94',
              text:
                  'البصمة هي المرجع المالي الرسمي — كشوف المرتبات تُعدّ من واقع بطاقات الحضور والانصراف.',
            ),
            RegulationItem(
              article: 'م95',
              text:
                  'إذا استحق العامل مرتباً عن جزء من الشهر تُحسب مستحقاته بنسبة أيام الحضور الفعلي.',
            ),
          ],
        ),
        RegulationSection(
          title: 'مخالفات الحضور والتأخير',
          items: [
            RegulationItem(
              article: 'م39',
              text:
                  'يلتزم العامل بالمحافظة على مواعيد العمل وتخصيص وقت العمل لأداء واجباته.',
            ),
            RegulationItem(
              article: 'م3/ب',
              text:
                  'يجوز توقيع العقوبة دون تحقيق إذا كانت المخالفة ثابتة من النظام الإلكتروني، مع حق التظلم خلال أسبوع.',
            ),
            RegulationItem(
              article: 'م41',
              text:
                  'كل عامل يخالف مواعيد الدوام يُعاقب تأديبياً وفق لائحة الجزاءات.',
            ),
          ],
        ),
      ],
    ),
    RegulationTab(
      id: 'absenteeism',
      label: 'الغياب',
      icon: FontAwesomeIcons.userXmark,
      sections: [
        RegulationSection(
          title: 'الإطار التأديبي للغياب',
          items: [
            RegulationItem(
              article: 'م4أ',
              text:
                  'الغياب والتأخير من الحالات الثابتة بالمستندات، ويُحقق فيها رئيس الوحدة أو من يكلفه.',
            ),
            RegulationItem(
              article: 'م3ت',
              text:
                  'لا يجوز مساءلة العامل عن المخالفة الواحدة أكثر من مرة. يجوز مضاعفة الخصم إذا تكررت خلال 3 أشهر.',
            ),
          ],
        ),
        RegulationSection(
          title: 'إنهاء الخدمة بسبب الغياب',
          items: [
            RegulationItem(
              article: 'م33ج',
              text:
                  'يجوز إنهاء خدمة من يعود بعد إنذار كتابي إلى عدم المحافظة على مواعيد العمل أو التسيب في الأداء.',
            ),
          ],
        ),
      ],
    ),
    RegulationTab(
      id: 'penalties',
      label: 'الجزاءات',
      icon: FontAwesomeIcons.scaleBalanced,
      sections: [
        RegulationSection(
          title: 'جدول المخالفات والعقوبات',
          penaltyCategories: [
            PenaltyCategory(
              title: 'أولاً: مخالفات تتعلق بمواعيد العمل',
              shortLabel: 'مواعيد العمل',
              headers: [
                'نوع المخالفة',
                'الأولى',
                'الثانية',
                'الثالثة',
                'الرابعة',
                'الخامسة',
              ],
              rows: [
                PenaltyRow(
                  violation: 'التأخير حتى 30 دقيقة بدون إذن',
                  penalties: [
                    PenaltyCell('إنذار'),
                    PenaltyCell('خصم نصف يوم'),
                    PenaltyCell('خصم يوم'),
                    PenaltyCell('خصم يومين'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
                PenaltyRow(
                  violation: 'التأخير أكثر من 30 دقيقة حتى ساعة',
                  penalties: [
                    PenaltyCell('خصم نصف يوم'),
                    PenaltyCell('خصم يوم'),
                    PenaltyCell('خصم يومين'),
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
                PenaltyRow(
                  violation: 'التأخير أكثر من ساعة حتى ساعتين',
                  penalties: [
                    PenaltyCell('خصم يوم'),
                    PenaltyCell('خصم يومين'),
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم أربعة أيام'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
                PenaltyRow(
                  violation: 'التأخير أكثر من ساعتين بدون إذن',
                  penalties: [
                    PenaltyCell(
                      'لا يُسمح بالدخول ويُعتبر متغيباً ويُوقَّع عليه جزاء الغياب',
                      colspan: 5,
                    ),
                  ],
                ),
                PenaltyRow(
                  violation: 'الغياب بدون إذن بما لا يزيد عن 20 يوماً/سنة',
                  penalties: [
                    PenaltyCell(
                      'خصم يومين عن كل يوم حتى العاشر، ثم 3 أيام؛ وعند تجاوز 20 يوماً تُحال للتأديب',
                      colspan: 5,
                    ),
                  ],
                ),
                PenaltyRow(
                  violation: 'الغياب بدون إذن 10 أيام متصلة فأكثر',
                  penalties: [
                    PenaltyCell('الإحالة إلى مجلس التأديب', colspan: 5),
                  ],
                ),
                PenaltyRow(
                  violation: 'التلاعب في إثبات الحضور والانصراف',
                  penalties: [
                    PenaltyCell('خصم خمسة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم عشرة أيام'),
                    PenaltyCell('إحالة للتأديب', colspan: 2),
                  ],
                ),
              ],
            ),
            PenaltyCategory(
              title: 'ثانياً: مخالفات تتعلق بلوائح ونظام العمل',
              shortLabel: 'نظام العمل',
              headers: [
                'نوع المخالفة',
                'الأولى',
                'الثانية',
                'الثالثة',
                'الرابعة',
                'الخامسة',
              ],
              rows: [
                PenaltyRow(
                  violation: 'مخالفة التعليمات أو عدم مراعاة أوامر العمل',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم خمسة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم عشرة أيام'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
                PenaltyRow(
                  violation: 'الدخول إلى أماكن العمل خارج الأوقات بدون تصريح',
                  penalties: [
                    PenaltyCell('إنذار'),
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم خمسة أيام'),
                    PenaltyCell('خصم عشرة أيام'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
                PenaltyRow(
                  violation: 'الاستيلاء على مساكن أو مقرات مملوكة للمنطقة',
                  penalties: [
                    PenaltyCell(
                      'الإيقاف عن العمل مع الإحالة إلى مجلس التأديب',
                      colspan: 5,
                    ),
                  ],
                ),
              ],
            ),
            PenaltyCategory(
              title: 'ثالثاً: مخالفات متعلقة بأداء العمل',
              shortLabel: 'أداء العمل',
              headers: [
                'نوع المخالفة',
                'الأولى',
                'الثانية',
                'الثالثة',
                'الرابعة',
                'الخامسة',
              ],
              rows: [
                PenaltyRow(
                  violation: 'التسيب في أداء العمل',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم خمسة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم عشرة أيام'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
                PenaltyRow(
                  violation: 'الإهمال مما ينشأ عنه ضرر للممتلكات أو الأفراد',
                  penalties: [
                    PenaltyCell(
                      'الإحالة إلى مجلس التأديب لتقرير العقوبة المناسبة',
                      colspan: 5,
                    ),
                  ],
                ),
                PenaltyRow(
                  violation: 'التأخير في إنجاز الأعمال أو عدم الدقة',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم خمسة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم خمسة عشر يوماً'),
                    PenaltyCell('إحالة للتأديب'),
                  ],
                ),
              ],
            ),
            PenaltyCategory(
              title: 'رابعاً: مخالفات متعلقة بالسلوك في العمل',
              shortLabel: 'السلوك',
              headers: [
                'نوع المخالفة',
                'الأولى',
                'الثانية',
                'الثالثة',
                'الرابعة',
                'الخامسة',
              ],
              rows: [
                PenaltyRow(
                  violation: 'الاعتداء على الرؤساء أو تهديدهم أو إهانتهم',
                  penalties: [
                    PenaltyCell(
                      'الإحالة إلى مجلس التأديب لتقرير العقوبة المناسبة',
                      colspan: 5,
                    ),
                  ],
                ),
                PenaltyRow(
                  violation: 'الاعتداء البسيط أو التهديد للزملاء',
                  penalties: [
                    PenaltyCell('خصم عشرة أيام'),
                    PenaltyCell('إحالة للتأديب', colspan: 4),
                  ],
                ),
                PenaltyRow(
                  violation: 'الشكوى الكيدية ضد الرؤساء أو الزملاء',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم خمسة أيام'),
                    PenaltyCell('خصم عشرة أيام'),
                    PenaltyCell('إحالة للتأديب', colspan: 2),
                  ],
                ),
              ],
            ),
            PenaltyCategory(
              title: 'خامساً: مخالفات تتعلق بالسلامة العامة',
              shortLabel: 'السلامة',
              headers: [
                'نوع المخالفة',
                'الأولى',
                'الثانية',
                'الثالثة',
                'الرابعة',
                'الخامسة',
              ],
              rows: [
                PenaltyRow(
                  violation: 'التدخين في الأماكن المحظورة',
                  penalties: [
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم عشرين يوماً'),
                    PenaltyCell('إحالة للتأديب', colspan: 3),
                  ],
                ),
                PenaltyRow(
                  violation: 'عدم ارتداء ملابس العمل أو الأجهزة الواقية',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم خمسة عشر يوماً', colspan: 3),
                  ],
                ),
                PenaltyRow(
                  violation: 'حيازة أو تعاطي المسكرات أو المخدرات',
                  penalties: [
                    PenaltyCell(
                      'الإيقاف عن العمل مع الإحالة إلى مجلس التأديب',
                      colspan: 5,
                    ),
                  ],
                ),
              ],
            ),
            PenaltyCategory(
              title: 'سادساً: مخالفات خاصة بالعاملين في الأمن والسلامة',
              shortLabel: 'الأمن',
              headers: [
                'نوع المخالفة',
                'الأولى',
                'الثانية',
                'الثالثة',
                'الرابعة',
                'الخامسة',
              ],
              rows: [
                PenaltyRow(
                  violation: 'عدم التبليغ عن المخالفات التي تصل إلى علمه',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم خمسة وعشرين يوماً', colspan: 3),
                  ],
                ),
                PenaltyRow(
                  violation: 'التستر على مخالفات الأمن أو إعطاء معلومات غير صحيحة',
                  penalties: [
                    PenaltyCell('خصم ثلاثة أيام'),
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم خمسة وعشرين يوماً'),
                    PenaltyCell('إحالة للتأديب', colspan: 2),
                  ],
                ),
                PenaltyRow(
                  violation: 'مخالفة تعليمات السلامة',
                  penalties: [
                    PenaltyCell('خصم أسبوع'),
                    PenaltyCell('خصم خمسة وعشرين يوماً', colspan: 2),
                    PenaltyCell('إحالة للتأديب', colspan: 2),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static RegulationTab? byId(String id) {
    for (final tab in tabs) {
      if (tab.id == id) return tab;
    }
    return null;
  }
}
