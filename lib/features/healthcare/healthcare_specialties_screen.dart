import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/healthcare_provider.dart';
import '../../data/repositories/healthcare_repository.dart';
import '../../data/static/static_healthcare.dart';
import 'healthcare_by_specialty_screen.dart';

/// المؤسسات الطبية المتعاقدة — التصنيفات مع عدد المؤسسات
/// (بديل `Contracted_Healthcare_Providers.php`).
class HealthcareSpecialtiesScreen extends StatefulWidget {
  const HealthcareSpecialtiesScreen({super.key, this.repository});

  final HealthcareRepository? repository;

  @override
  State<HealthcareSpecialtiesScreen> createState() =>
      _HealthcareSpecialtiesScreenState();
}

class _HealthcareSpecialtiesScreenState
    extends State<HealthcareSpecialtiesScreen> {
  HealthcareRepository get _repo => widget.repository ?? AppServices.healthcare;

  List<HealthcareCategory>? _categories;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.categories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _open(int? category, String title, {String? initialQuery}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HealthcareBySpecialtyScreen(
          category: category,
          title: title,
          initialQuery: initialQuery,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final total = categories?.fold<int>(0, (sum, c) => sum + c.count);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المؤسسات الطبية')),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.starAndCrescent,
                            color: Color(0xFFE2C79A),
                            size: 22,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'شركاء الصحة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            total == null
                                ? 'مؤسسات متعاقدة مع المنطقة الحرة بمصراتة — اختر التخصص ثم تصفّح التفاصيل.'
                                : '$total مؤسسة متعاقدة مع المنطقة الحرة بمصراتة — اختر التخصص ثم تصفّح التفاصيل.',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.45,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SearchAllTile(
                      onSubmitted: (q) => _open(
                        null,
                        'كل المؤسسات',
                        initialQuery: q,
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
            if (_error != null && categories == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrorCard(error: _error!, onRetry: _load),
                ),
              )
            else
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
                      if (_loading && categories == null) {
                        return const _CategorySkeleton();
                      }
                      final c = categories![index];
                      final look = StaticHealthcare.specialtyById(c.id);
                      final known = look.id == c.id;
                      final title = known
                          ? look.title
                          : (c.name ?? 'تصنيف رقم ${c.id}');
                      final subtitle = known
                          ? (c.name ?? look.subtitle)
                          : look.subtitle;
                      return _SpecialtyCard(
                        title: title,
                        subtitle: subtitle,
                        icon: look.icon,
                        accent: look.accent,
                        count: c.count,
                        onTap: () => _open(c.id, c.name ?? title),
                      );
                    },
                    childCount: _loading && categories == null
                        ? 6
                        : categories!.length,
                  ),
                ),
              ),
            if (!_loading && categories != null && categories.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'لا توجد تصنيفات مسجّلة حالياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchAllTile extends StatefulWidget {
  const _SearchAllTile({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_SearchAllTile> createState() => _SearchAllTileState();
}

class _SearchAllTileState extends State<_SearchAllTile> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go() {
    final q = _controller.text.trim();
    widget.onSubmitted(q);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _go(),
      maxLength: HealthcareRepository.searchMaxLength,
      decoration: InputDecoration(
        counterText: '',
        hintText: 'ابحث في كل المؤسسات بالاسم أو العنوان',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: 'بحث',
          onPressed: _go,
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 15),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final message = e is ApiException
        ? (e.isNetwork
            ? 'تعذر الوصول إلى الخادم. تأكد من الشبكة ثم أعد المحاولة.'
            : e.message)
        : 'حدث خطأ غير متوقع.';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 15,
                color: AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ),
        ],
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              decoration: const BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 70,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
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
