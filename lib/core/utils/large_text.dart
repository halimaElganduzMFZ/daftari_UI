import 'package:flutter/widgets.dart';

/// خط الجهاز من ١٣٠٪ فأكثر. عندها تنتقل الصفوف والشبكات الضيقة إلى ترتيب عمودي،
/// لأن الكلمة العربية التي لا يتسع لها السطر تنكسر حرفاً حرفاً.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.3;
