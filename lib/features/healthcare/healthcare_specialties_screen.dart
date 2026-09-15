import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/static/static_healthcare.dart';
import 'healthcare_by_specialty_screen.dart';

/// المؤسسات الطبية المتعاقدة — تقسيم حسب التخصص (Contracted_Healthcare_Providers).
class HealthcareSpecialtiesScreen extends StatelessWidget {
  const HealthcareSpecialtiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final specialties = StaticHealthcare.specialties;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المؤسسات الطبية')),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF3D4A3F), Color(0xFF2A3030)],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.starAndCrescent,
                          color: Color(0xFFE2C79A),
                          size: 22,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'شركاء الصحة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'مؤسسات متعاقدة مع المنطقة الحرة بمصراتة — اختر التخصص ثم تصفّح التفاصيل.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'حسب التخصص',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'كل تخصص يفتح قائمة المؤسسات المرتبطة به',
                    style: TextStyle(color: AppColors.slate, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = specialties[index];
                  final count = StaticHealthcare.countFor(s.id);
                  return _SpecialtyCard(
                    title: s.title,
                    subtitle: s.subtitle,
                    icon: s.icon,
                    accent: s.accent,
                    count: count,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              HealthcareBySpecialtyScreen(specialtyId: s.id),
                        ),
                      );
                    },
                  );
                },
                childCount: specialties.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyCard extends StatefulWidget {
  const _SpecialtyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.count,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final FaIconData icon;
  final Color accent;
  final int count;
  final VoidCallback onTap;

  @override
  State<_SpecialtyCard> createState() => _SpecialtyCardState();
}

class _SpecialtyCardState extends State<_SpecialtyCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _down = v),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          widget.accent.withValues(alpha: 0.92),
                          widget.accent.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -8,
                          bottom: -12,
                          child: FaIcon(
                            widget.icon,
                            size: 72,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        Center(
                          child: FaIcon(
                            widget.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${widget.count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            height: 1.25,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
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
