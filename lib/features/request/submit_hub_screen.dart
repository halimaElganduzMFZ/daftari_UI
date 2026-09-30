import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/session/app_session.dart';
import '../leave/make_leave_screen.dart';
import 'make_request_screen.dart';
import 'request_kind_chooser.dart';

/// تبويب «تقديم» — يسهّل الاختيار بين إجازة وإذن.
class SubmitHubScreen extends StatelessWidget {
  const SubmitHubScreen({super.key});

  Future<void> _open(BuildContext context, RequestKind kind) async {
    if (kind == RequestKind.permission) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MakeRequestScreen(),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MakeLeaveScreen(
          onSubmitted: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _askThenOpen(BuildContext context) async {
    final kind = await showRequestKindChooser(context);
    if (kind == null || !context.mounted) return;
    await _open(context, kind);
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'تقديم طلب',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            employee == null
                ? 'اختر نوع الطلب للبدء'
                : 'مرحباً ${employee.fullName} — اختر نوع الطلب للبدء',
            style: const TextStyle(
              color: AppColors.slate,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          _HubCard(
            title: 'طلب إجازة',
            subtitle: 'سنوية · طارئة · دراسية · وضع · عدة · حج · زواج',
            icon: FontAwesomeIcons.umbrellaBeach,
            onTap: () => _open(context, RequestKind.leave),
          ),
          const SizedBox(height: 12),
          _HubCard(
            title: 'طلب إذن',
            subtitle: 'خروج · تأخر · استئذان · مهمة عمل وغيرها',
            icon: FontAwesomeIcons.clockRotateLeft,
            onTap: () => _open(context, RequestKind.permission),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: () => _askThenOpen(context),
              icon: const FaIcon(FontAwesomeIcons.circleQuestion, size: 14),
              label: const Text('لست متأكداً؟ اختر من القائمة'),
              style: TextButton.styleFrom(foregroundColor: AppColors.goldDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
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
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 20, color: AppColors.goldDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 14,
            color: AppColors.slate,
          ),
        ],
      ),
    );
  }
}
