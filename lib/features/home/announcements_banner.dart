import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/announcements.dart';
import '../../data/session/app_session.dart';

/// بانر إعلانات بأسلوب شرائح (مثل تطبيقات التوصيل) فوق محتوى الرئيسية.
class AnnouncementsBanner extends StatefulWidget {
  const AnnouncementsBanner({super.key, required this.feed});
  final AnnouncementsFeed feed;
  @override
  State<AnnouncementsBanner> createState() => _AnnouncementsBannerState();
}

class _AnnouncementsBannerState extends State<AnnouncementsBanner> {
  final _page = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant AnnouncementsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed.items.length != widget.feed.items.length) {
      _index = 0;
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
    if (!feed.slideshow.autoplay || feed.items.length < 2) return;
    final seconds = feed.items[_index].displaySeconds ??
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
    return Column(
      children: [
        SizedBox(
          height: 168,
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
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _AnnouncementSlide(
                  item: item,
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
                    color: i == _index
                        ? AppColors.gold
                        : AppColors.line,
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
  const _AnnouncementSlide({required this.item, this.onTap});
  final AnnouncementItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final token = AppSession.accessToken;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF3A342C), AppColors.charcoal],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    headers: token == null || token.isEmpty
                        ? null
                        : {'Authorization': 'Bearer $token'},
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: .72),
                        Colors.black.withValues(alpha: .25),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.pinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'مثبّت',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 1.25,
                        ),
                      ),
                      if ((item.body ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .86),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (item.hasLink) ...[
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.arrowUpRightFromSquare,
                              size: 11,
                              color: AppColors.goldSoft,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'افتح الرابط',
                              style: TextStyle(
                                color: AppColors.goldSoft,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
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
