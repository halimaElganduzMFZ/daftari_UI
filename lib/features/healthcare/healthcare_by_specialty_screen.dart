import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/healthcare_provider.dart';
import '../../data/static/static_healthcare.dart';
import 'healthcare_provider_detail_screen.dart';

/// مؤسسات تخصص معيّن (بديل details.php?id=).
class HealthcareBySpecialtyScreen extends StatefulWidget {
  const HealthcareBySpecialtyScreen({super.key, required this.specialtyId});

  final String specialtyId;

  @override
  State<HealthcareBySpecialtyScreen> createState() =>
      _HealthcareBySpecialtyScreenState();
}

class _HealthcareBySpecialtyScreenState
    extends State<HealthcareBySpecialtyScreen> {
  static const _pageSize = 6;
  final _query = TextEditingController();
  int _visible = _pageSize;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialty = StaticHealthcare.specialtyById(widget.specialtyId);
    final all = StaticHealthcare.bySpecialty(widget.specialtyId);
    final q = _query.text.trim();
    final filtered = [
      for (final p in all)
        if (q.isEmpty ||
            p.name.contains(q) ||
            p.summary.contains(q) ||
            p.address.contains(q))
          p,
    ];
    final visible = filtered.take(_visible).toList();
    final hasMore = _visible < filtered.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(specialty?.title ?? 'التخصص')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          if (specialty != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    specialty.accent,
                    specialty.accent.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(specialty.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialty.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '${all.length} مؤسسة ضمن التعاقد',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {
              _visible = _pageSize;
            }),
            decoration: const InputDecoration(
              hintText: 'ابحث باسم المؤسسة أو العنوان',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'لا توجد مؤسسات تطابق البحث',
                  style: TextStyle(color: AppColors.slate),
                ),
              ),
            )
          else ...[
            Text(
              'عرض ${visible.length} من ${filtered.length}',
              style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            for (final p in visible) ...[
              _ProviderCard(
                provider: p,
                accent: specialty?.accent ?? AppColors.goldDeep,
                icon: specialty?.icon ?? FontAwesomeIcons.hospital,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HealthcareProviderDetailScreen(
                        providerId: p.id,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (hasMore)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _visible = (_visible + _pageSize).clamp(0, filtered.length);
                }),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text('عرض المزيد (${filtered.length - visible.length})'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.goldDeep,
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final HealthcareProvider provider;
  final Color accent;
  final FaIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      accent.withValues(alpha: 0.95),
                      accent.withValues(alpha: 0.55),
                      const Color(0xFF2F2F2F),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 8,
                      bottom: -10,
                      child: FaIcon(
                        icon,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(icon, color: Colors.white, size: 26),
                          const SizedBox(height: 8),
                          Text(
                            provider.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: 12,
                          color: AppColors.goldDeep,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            provider.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        const FaIcon(
                          FontAwesomeIcons.chevronLeft,
                          size: 12,
                          color: AppColors.slate,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
