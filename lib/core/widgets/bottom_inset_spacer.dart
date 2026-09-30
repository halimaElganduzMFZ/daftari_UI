import 'package:flutter/widgets.dart';

/// تُوضع في `bottomNavigationBar` للشاشات المفتوحة فوق الأقسام، فينتهي المحتوى
/// فوق شريط تنقل النظام (Android 15+ يرسم التطبيق تحته) أو مؤشر الرئيسية في iOS
/// بدل أن يختفي آخره خلفه. ارتفاعها صفر ولوحة المفاتيح مفتوحة.
class BottomInsetSpacer extends StatelessWidget {
  const BottomInsetSpacer({super.key});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: MediaQuery.paddingOf(context).bottom);
}
