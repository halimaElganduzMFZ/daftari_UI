import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';

enum RequestKind { leave, permission }

/// يسأل المستخدم: إجازة أم إذن؟ — لتسهيل الوصول من الرئيسية / تبويب تقديم.
Future<RequestKind?> showRequestKindChooser(BuildContext context) {
  return showModalBottomSheet<RequestKind>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'ماذا تريد تقديمه؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'اختر نوع الطلب لننقلك مباشرة للنموذج المناسب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.slate,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _ChooserTile(
                title: 'طلب إجازة',
                subtitle: 'سنوية، طارئة، دراسية، وضع، حج…',
                icon: FontAwesomeIcons.umbrellaBeach,
                onTap: () => Navigator.pop(context, RequestKind.leave),
              ),
              const SizedBox(height: 10),
              _ChooserTile(
                title: 'طلب إذن',
                subtitle: 'خروج، تأخر، استئذان، مهمة…',
                icon: FontAwesomeIcons.clockRotateLeft,
                onTap: () => Navigator.pop(context, RequestKind.permission),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChooserTile extends StatelessWidget {
  const _ChooserTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final FaIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: FaIcon(icon, size: 18, color: AppColors.goldDeep),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronLeft,
                size: 13,
                color: AppColors.slate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
