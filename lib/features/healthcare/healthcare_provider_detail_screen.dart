import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/static/static_healthcare.dart';

/// تفاصيل مؤسسة طبية — عرض غامر مع خدمات وخريطة.
class HealthcareProviderDetailScreen extends StatelessWidget {
  const HealthcareProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  Future<void> _openMap(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final provider = StaticHealthcare.providerById(providerId);
    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('التفاصيل')),
        body: const Center(child: Text('المؤسسة غير موجودة')),
      );
    }
    final specialty = StaticHealthcare.specialtyById(provider.specialtyId);
    final accent = specialty?.accent ?? AppColors.goldDeep;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: accent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                provider.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          accent,
                          accent.withValues(alpha: 0.7),
                          const Color(0xFF1F1F1F),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -30,
                    child: FaIcon(
                      specialty?.icon ?? FontAwesomeIcons.hospital,
                      size: 200,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.15),
                    child: FaIcon(
                      specialty?.icon ?? FontAwesomeIcons.hospital,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (specialty != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        specialty.title,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    provider.summary,
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      height: 1.55,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'معلومات التواصل',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: FontAwesomeIcons.locationDot,
                    label: 'العنوان',
                    value: provider.address,
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: FontAwesomeIcons.phone,
                    label: 'الهاتف',
                    value: provider.phone,
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: FontAwesomeIcons.clock,
                    label: 'ساعات العمل',
                    value: provider.hours,
                    accent: accent,
                  ),
                  if (provider.services.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'الخدمات',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in provider.services)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (provider.mapUrl != null) ...[
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () => _openMap(provider.mapUrl!),
                      icon: const FaIcon(FontAwesomeIcons.mapLocationDot, size: 16),
                      label: const Text('عرض على الخريطة'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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
