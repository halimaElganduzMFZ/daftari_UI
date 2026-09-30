/// إعلانات لوحة الموظف (`GET /me/announcements` أو قسم `announcements` في اللوحة).
library;

import '../../core/config/api_config.dart';

int? _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
String? _str(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// يحوّل مسار الصورة النسبي من الـ API إلى رابط مطلق مع نفس المضيف.
String? resolveAnnouncementMediaUrl(Object? raw) {
  final url = _str(raw);
  if (url == null) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = Uri.parse(ApiConfig.baseUrl);
  final origin = '${base.scheme}://${base.authority}';
  if (url.startsWith('/')) return '$origin$url';
  return '$origin/${url.replaceFirst(RegExp(r'^/+'), '')}';
}

class AnnouncementSlideshow {
  const AnnouncementSlideshow({
    this.intervalSeconds = 6,
    this.autoplay = true,
    this.loop = true,
    this.asOf,
  });

  factory AnnouncementSlideshow.fromApi(Map<String, dynamic>? json) =>
      AnnouncementSlideshow(
        intervalSeconds: _int(json?['intervalSeconds']) ?? 6,
        autoplay: json?['autoplay'] != false,
        loop: json?['loop'] != false,
        asOf: _str(json?['asOf']),
      );

  final int intervalSeconds;
  final bool autoplay;
  final bool loop;
  final String? asOf;
}

class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    this.body,
    this.imageUrl,
    this.linkUrl,
    this.displaySeconds,
    this.pinned = false,
    this.sortOrder = 0,
  });

  factory AnnouncementItem.fromApi(Map<String, dynamic> json) {
    final image = _map(json['image']);
    final imageUrl = resolveAnnouncementMediaUrl(
      image?['url'] ??
          image?['href'] ??
          image?['path'] ??
          json['imageUrl'] ??
          json['imagePath'] ??
          (json['image'] is String ? json['image'] : null),
    );
    return AnnouncementItem(
      id: '${json['id'] ?? ''}',
      title: _str(json['title']) ?? '',
      body: _str(json['body'] ?? json['text'] ?? json['content']),
      imageUrl: imageUrl,
      linkUrl: _str(json['linkUrl'] ?? json['link'] ?? json['url']),
      displaySeconds: _int(json['displaySeconds'] ?? json['durationSeconds']),
      pinned: json['pinned'] == true || json['isPinned'] == true,
      sortOrder: _int(json['sortOrder'] ?? json['order'] ?? json['rank']) ?? 0,
    );
  }

  final String id;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? linkUrl;
  final int? displaySeconds;
  final bool pinned;
  final int sortOrder;

  bool get hasLink => (linkUrl ?? '').isNotEmpty;
  bool get hasImage => (imageUrl ?? '').isNotEmpty;
  bool get hasBody => (body ?? '').isNotEmpty;
}

class AnnouncementsFeed {
  const AnnouncementsFeed({
    required this.slideshow,
    required this.items,
  });

  factory AnnouncementsFeed.fromApi(Object? raw) {
    final json = _map(raw);
    if (json == null) {
      // بعض الاستجابات تُرجع القائمة مباشرة.
      if (raw is List) {
        final items = [
          for (final item in raw)
            if (item is Map)
              AnnouncementItem.fromApi(Map<String, dynamic>.from(item)),
        ]..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return a.sortOrder.compareTo(b.sortOrder);
          });
        return AnnouncementsFeed(
          slideshow: const AnnouncementSlideshow(),
          items: items,
        );
      }
      return empty;
    }
    final list = json['items'] ?? json['data'] ?? json['announcements'];
    final items = [
      for (final item in (list as List? ?? const []))
        if (item is Map)
          AnnouncementItem.fromApi(Map<String, dynamic>.from(item)),
    ]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    return AnnouncementsFeed(
      slideshow: AnnouncementSlideshow.fromApi(_map(json['slideshow'])),
      items: items,
    );
  }

  final AnnouncementSlideshow slideshow;
  final List<AnnouncementItem> items;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  static const empty = AnnouncementsFeed(
    slideshow: AnnouncementSlideshow(),
    items: [],
  );
}
