import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/healthcare_provider.dart';
import '../../data/repositories/healthcare_repository.dart';
import '../../data/static/static_healthcare.dart';
import 'healthcare_provider_detail_screen.dart';

/// مؤسسات تصنيف معيّن — أو كل التصنيفات عند `category == null`
/// (بديل `details.php?id=`). البحث والتصفح يجريان على الخادم.
class HealthcareBySpecialtyScreen extends StatefulWidget {
  const HealthcareBySpecialtyScreen({
    super.key,
    required this.category,
    required this.title,
    this.initialQuery,
    this.repository,
  });

  /// `hospitals.category`؛ null للبحث في كل التصنيفات.
  final int? category;
  final String title;
  final String? initialQuery;
  final HealthcareRepository? repository;

  @override
  State<HealthcareBySpecialtyScreen> createState() =>
      _HealthcareBySpecialtyScreenState();
}

class _HealthcareBySpecialtyScreenState
    extends State<HealthcareBySpecialtyScreen> {
  static const _pageSize = 10;
  static const _debounce = Duration(milliseconds: 400);

  HealthcareRepository get _repo => widget.repository ?? AppServices.healthcare;

  late final TextEditingController _query;
  Timer? _debounceTimer;
  int _seq = 0;

  final _items = <HealthcareProvider>[];
  int _page = 0;
  bool _hasNext = true;
  int? _total;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery ?? '');
    _reload();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _reload);
    setState(() {}); // لتحديث زر المسح.
  }

  Future<void> _reload() async {
    _seq++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasNext = true;
      _total = null;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasNext) return;
    final seq = _seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.list(
        category: widget.category,
        query: _query.text,
        page: _page + 1,
        limit: _pageSize,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
        _total = page.total ?? _total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.category == null
        ? null
        : StaticHealthcare.specialtyById(widget.category!);
    final accent = look?.accent ?? AppColors.goldDeep;
    final icon = look?.icon ?? FontAwesomeIcons.building;
    final q = _query.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
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
                    child: FaIcon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          _total == null
                              ? 'مؤسسات ضمن التعاقد'
                              : '$_total مؤسسة ضمن التعاقد',
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
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _debounceTimer?.cancel();
                _reload();
              },
              maxLength: HealthcareRepository.searchMaxLength,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ابحث بالاسم أو العنوان',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح',
                        onPressed: () {
                          _query.clear();
                          _debounceTimer?.cancel();
                          _reload();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null && _items.isEmpty)
              _ErrorCard(error: _error!, onRetry: _reload)
            else if (_loading && _items.isEmpty)
              for (var i = 0; i < 3; i++) const _ProviderSkeleton()
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 30,
                      color: AppColors.slate,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q.isEmpty
                          ? 'لا توجد مؤسسات مسجّلة في هذا التصنيف'
                          : 'لا توجد مؤسسات تطابق «$q»',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.slate),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                _total == null
                    ? 'عرض ${_items.length}'
                    : 'عرض ${_items.length} من $_total',
                style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              for (final p in _items) ...[
                _ProviderCard(
                  provider: p,
                  accent: widget.category == null
                      ? StaticHealthcare.specialtyById(p.category).accent
                      : accent,
                  icon: widget.category == null
                      ? StaticHealthcare.specialtyById(p.category).icon
                      : icon,
                  showCategory: widget.category == null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            HealthcareProviderDetailScreen(provider: p),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (_error != null) _ErrorCard(error: _error!, onRetry: _loadMore),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              else if (_hasNext)
                OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text(
                    _total == null
                        ? 'عرض المزيد'
                        : 'عرض المزيد (${_total! - _items.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.goldDeep,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.accent,
    required this.icon,
    required this.showCategory,
    required this.onTap,
  });

  final HealthcareProvider provider;
  final Color accent;
  final FaIconData icon;
  final bool showCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = provider.subtitle;
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
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
                      if (provider.imageUrl != null)
                        Positioned(
                          left: 14,
                          top: 14,
                          child: ProviderLogo(url: provider.imageUrl!, size: 44),
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(icon, color: Colors.white, size: 26),
                              const SizedBox(height: 8),
                              Text(
                                provider.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCategory && provider.categoryName != null) ...[
                      Text(
                        provider.categoryName!,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
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
                            subtitle.isEmpty ? provider.details : subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (provider.hasMap)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: FaIcon(
                              FontAwesomeIcons.mapLocationDot,
                              size: 13,
                              color: AppColors.slate,
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

/// شعار المؤسسة من `imageUrl` مع بديل صامت عند الفشل.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(4),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const FaIcon(
          FontAwesomeIcons.building,
          size: 18,
          color: AppColors.slate,
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
      margin: const EdgeInsets.only(bottom: 12),
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

class _ProviderSkeleton extends StatelessWidget {
  const _ProviderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 110,
            decoration: const BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
