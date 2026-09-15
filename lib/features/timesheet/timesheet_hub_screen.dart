import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import 'attendance_timesheet_screen.dart';
import 'vehicle_gate_log_screen.dart';

/// بوابة اختيار نوع السجل: حضور/انصراف أو حركة السيارة في البوابة.
class TimesheetHubScreen extends StatefulWidget {
  const TimesheetHubScreen({super.key});

  @override
  State<TimesheetHubScreen> createState() => _TimesheetHubScreenState();
}

class _TimesheetHubScreenState extends State<TimesheetHubScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التايم شيت')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'اختر طريقة العرض',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'سجلّان مختلفان لنفس يوم عملك — حضور البصمة، أو حركة سيارتك عبر البوابة.',
            style: TextStyle(color: AppColors.slate, height: 1.5),
          ),
          const SizedBox(height: 22),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_pulse.value);
              return Column(
                children: [
                  _ChoicePanel(
                    title: 'حضور وانصراف',
                    subtitle:
                        'بصمات الدخول والخروج والاستراحة، مع التأخير والحالة اليومية.',
                    badge: 'دوام',
                    icon: FontAwesomeIcons.fingerprint,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.lerp(
                          const Color(0xFF2F2F2F),
                          AppColors.goldDeep,
                          0.15 + t * 0.08,
                        )!,
                        const Color(0xFF3A3A38),
                      ],
                    ),
                    onTap: () => _open(const AttendanceTimesheetScreen()),
                  ),
                  const SizedBox(height: 14),
                  _OrDivider(glow: t),
                  const SizedBox(height: 14),
                  _ChoicePanel(
                    title: 'سجل البوابة',
                    subtitle:
                        'دخول وخروج السيارة، مدة البقاء داخل المنطقة، والمخالفات إن وُجدت.',
                    badge: 'مركبة',
                    icon: FontAwesomeIcons.carSide,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.lerp(
                          AppColors.goldDeep,
                          const Color(0xFF5A4630),
                          t * 0.2,
                        )!,
                        const Color(0xFF6B5538),
                      ],
                    ),
                    onTap: () => _open(const VehicleGateLogScreen()),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.goldSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 16,
                  color: AppColors.goldDeep,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يمكنك التبديل بين السجلّين في أي وقت. كل قائمة تدعم «عرض المزيد» لتصفح الأيام دون صفحات مرقّمة.',
                    style: TextStyle(
                      color: AppColors.charcoal,
                      height: 1.45,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.glow});

  final double glow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.line.withValues(alpha: 0.9))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.surface, AppColors.goldSoft, glow),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          child: const Text(
            'أو',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.goldDeep,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.line.withValues(alpha: 0.9))),
      ],
    );
  }
}

class _ChoicePanel extends StatefulWidget {
  const _ChoicePanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final FaIconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  State<_ChoicePanel> createState() => _ChoicePanelState();
}

class _ChoicePanelState extends State<_ChoicePanel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Ink(
            height: 168,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -20,
                  bottom: -24,
                  child: FaIcon(
                    widget.icon,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: FaIcon(
                              widget.icon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.35,
                          fontSize: 13.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
