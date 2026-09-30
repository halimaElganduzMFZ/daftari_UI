import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/healthcare_provider.dart';
import '../../data/static/static_healthcare.dart';
import 'healthcare_by_specialty_screen.dart' show ProviderLogo;

/// تفاصيل مؤسسة طبية — ما يوفره `hospitals`: التفاصيل (اسم وعنوان)،
/// التصنيف، الشعار، ورابط الخريطة.
class HealthcareProviderDetailScreen extends StatelessWidget {
  const HealthcareProviderDetailScreen({super.key, required this.provider});

  final HealthcareProvider provider;

  Future<void> _openMap(BuildContext context) async {
    final uri = Uri.tryParse(provider.mapUrl ?? '');
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط الخريطة')),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: provider.details));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ التفاصيل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = StaticHealthcare.specialtyById(provider.category);
    final accent = look.accent;
    final categoryLabel = provider.categoryName ?? look.title;

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
                provider.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                      look.icon,
                      size: 200,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.15),
                    child: provider.imageUrl != null
                        ? ProviderLogo(url: provider.imageUrl!, size: 84)
                        : FaIcon(
                            look.icon,
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
                      categoryLabel,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'التفاصيل والعنوان',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: FontAwesomeIcons.building,
                    label: 'كما هو مسجّل في التعاقد',
                    value: provider.details,
                    accent: accent,
                    onCopy: () => _copy(context),
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: FontAwesomeIcons.mapLocationDot,
                    label: 'الخريطة',
                    value: provider.hasMap
                        ? 'رابط موقع متاح — اضغط الزر أدناه لفتحه'
                        : 'لم يُسجَّل رابط خريطة لهذه المؤسسة',
                    accent: accent,
                  ),
                  if (provider.hasMap) ...[
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () => _openMap(context),
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
    this.onCopy,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onCopy;

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
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'نسخ',
              onPressed: onCopy,
              icon: const FaIcon(FontAwesomeIcons.copy, size: 15, color: AppColors.slate),
            ),
        ],
      ),
    );
  }
}
