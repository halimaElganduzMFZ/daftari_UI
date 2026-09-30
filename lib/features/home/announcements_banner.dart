import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/announcements.dart';
import '../../data/session/app_session.dart';

/// بانر إعلانات من `GET /me/announcements` — صورة+نص، صورة فقط، أو نص بزخرفة.
class AnnouncementsBanner extends StatefulWidget {
  const AnnouncementsBanner({super.key, required this.feed});
  final AnnouncementsFeed feed;
  @override
  State<AnnouncementsBanner> createState() => _AnnouncementsBannerState();
}

class _AnnouncementsBannerState extends State<AnnouncementsBanner> {
  final _page = PageController(viewportFraction: 0.96);
  int _index = 0;
  Timer? _timer;
  bool _autoplayAllowed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // لا تقليب تلقائي مع «إزالة الحركة» أو قارئ الشاشة؛ يبقى التمرير باليد.
    _autoplayAllowed =
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant AnnouncementsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.feed, widget.feed) ||
        oldWidget.feed.items.length != widget.feed.items.length) {
      _index = 0;
      if (_page.hasClients) _page.jumpToPage(0);
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    final feed = widget.feed;
    if (!_autoplayAllowed || !feed.slideshow.autoplay || feed.items.length < 2) {
      return;
    }
    final seconds =
        feed.items[_index.clamp(0, feed.items.length - 1)].displaySeconds ??
        feed.slideshow.intervalSeconds;
    _timer = Timer(Duration(seconds: seconds.clamp(3, 30)), () {
      if (!mounted || feed.items.isEmpty) return;
      final next = _index + 1;
      if (next >= feed.items.length) {
        if (!feed.slideshow.loop) return;
        _page.animateToPage(
          0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      } else {
        _page.nextPage(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.feed.items;
    if (items.isEmpty) return const SizedBox.shrink();
    // الشرائح بارتفاع ثابت (PageView)، فيكبر الارتفاع مع حجم الخط كي لا يُقص النص.
    final textGrowth = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(
      children: [
        SizedBox(
          height: 178 * math.max(1, textGrowth),
          child: PageView.builder(
            controller: _page,
            itemCount: items.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _restartTimer();
            },
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _AnnouncementSlide(
                  item: item,
                  accentIndex: i,
                  onTap: item.hasLink ? () => _openLink(item.linkUrl) : null,
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.gold : AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AnnouncementSlide extends StatelessWidget {
  const _AnnouncementSlide({
    required this.item,
    required this.accentIndex,
    this.onTap,
  });
  final AnnouncementItem item;
  final int accentIndex;
  final VoidCallback? onTap;

  static const _accents = <List<Color>>[
    [Color(0xFF3A342C), Color(0xFF5C4E3A)],
    [Color(0xFF2F3A42), Color(0xFF4A5C66)],
    [Color(0xFF3A2F36), Color(0xFF6B4E5A)],
    [Color(0xFF2E3A32), Color(0xFF4F6B58)],
  ];

  @override
  Widget build(BuildContext context) {
    final token = AppSession.accessToken;
    final colors = _accents[accentIndex % _accents.length];
    final hasImage = item.hasImage;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: colors,
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: .28)),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: .22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    headers: token == null || token.isEmpty
                        ? null
                        : {'Authorization': 'Bearer $token'},
                    errorBuilder: (_, _, _) =>
                        _BubbleBackdrop(seed: accentIndex),
                  )
                else
                  _BubbleBackdrop(seed: accentIndex),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: hasImage ? .75 : .45),
                        Colors.black.withValues(alpha: hasImage ? .28 : .12),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (item.pinned)
                            _Chip(
                              label: 'مثبّت',
                              icon: FontAwesomeIcons.thumbtack,
                            ),
                          if (item.pinned && item.hasLink)
                            const SizedBox(width: 6),
                          if (item.hasLink)
                            const _Chip(
                              label: 'رابط',
                              icon: FontAwesomeIcons.link,
                            ),
                          if (!item.pinned && !item.hasLink && !hasImage)
                            const _Chip(
                              label: 'إعلان',
                              icon: FontAwesomeIcons.bullhorn,
                            ),
                        ],
                      ),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.title.isNotEmpty)
                              Text(
                                item.title,
                                maxLines: item.hasBody ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  height: 1.25,
                                ),
                              ),
                            if (item.hasBody) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .14),
                                  ),
                                ),
                                child: Text(
                                  item.body!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .92),
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            if (item.hasLink)
                              // «اضغط للفتح» يكرر شارة «رابط» أعلاه، فيُخفى حين لا يترك
                              // العنوان والنص مكاناً له في الارتفاع الثابت للشريحة.
                              Flexible(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final needed = 10 +
                                        math.max(
                                          22.0,
                                          MediaQuery.textScalerOf(
                                                context,
                                              ).scale(12) *
                                              1.3,
                                        );
                                    if (constraints.maxHeight < needed) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldSoft
                                                  .withValues(alpha: .2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const FaIcon(
                                              FontAwesomeIcons
                                                  .arrowUpRightFromSquare,
                                              size: 10,
                                              color: AppColors.goldSoft,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'اضغط للفتح',
                                            style: TextStyle(
                                              color: AppColors.goldSoft,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});
  final String label;
  final FaIconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.goldSoft.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 9, color: AppColors.goldDeep),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.goldDeep,
          ),
        ),
      ],
    ),
  );
}

/// زخرفة فقاعات/أشكال للشرائح بدون صورة.
class _BubbleBackdrop extends StatelessWidget {
  const _BubbleBackdrop({required this.seed});
  final int seed;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BubblePainter(seed: seed),
    child: const SizedBox.expand(),
  );
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed + 17);
    final soft = Paint()..color = Colors.white.withValues(alpha: .06);
    final gold = Paint()..color = AppColors.goldSoft.withValues(alpha: .12);
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    void bubble(Offset c, double r, Paint p) => canvas.drawCircle(c, r, p);

    bubble(Offset(size.width * .12, size.height * .28), 38, soft);
    bubble(Offset(size.width * .82, size.height * .22), 52, gold);
    bubble(Offset(size.width * .7, size.height * .78), 46, soft);
    bubble(Offset(size.width * .22, size.height * .82), 26, gold);
    canvas.drawCircle(Offset(size.width * .5, size.height * .45), 64, ring);
    canvas.drawCircle(Offset(size.width * .88, size.height * .65), 22, ring);

    for (var i = 0; i < 7; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      bubble(Offset(x, y), 4 + rnd.nextDouble() * 10, soft);
    }

    final arc = Path()
      ..moveTo(size.width * .05, size.height * .9)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .55,
        size.width * .95,
        size.height * .85,
      );
    canvas.drawPath(
      arc,
      Paint()
        ..color = AppColors.gold.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
