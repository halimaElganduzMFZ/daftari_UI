/// إعلانات لوحة الموظف (`GET /me/announcements` أو قسم `announcements` في اللوحة).
library;

int? _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
String? _str(Object? v) => v == null ? null : '$v'.trim();
Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

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
  });

  factory AnnouncementItem.fromApi(Map<String, dynamic> json) {
    final image = _map(json['image']);
    return AnnouncementItem(
      id: '${json['id'] ?? ''}',
      title: _str(json['title']) ?? '',
      body: _str(json['body'] ?? json['text']),
      imageUrl: _str(image?['url'] ?? json['imageUrl']),
      linkUrl: _str(json['linkUrl'] ?? json['link']),
      displaySeconds: _int(json['displaySeconds']),
      pinned: json['pinned'] == true,
    );
  }

  final String id;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? linkUrl;
  final int? displaySeconds;
  final bool pinned;

  bool get hasLink => (linkUrl ?? '').isNotEmpty;
}

class AnnouncementsFeed {
  const AnnouncementsFeed({
    required this.slideshow,
    required this.items,
  });

  factory AnnouncementsFeed.fromApi(Object? raw) {
    final json = _map(raw);
    if (json == null) {
      return const AnnouncementsFeed(
        slideshow: AnnouncementSlideshow(),
        items: [],
      );
    }
    final list = json['items'] ?? json['data'];
    return AnnouncementsFeed(
      slideshow: AnnouncementSlideshow.fromApi(_map(json['slideshow'])),
      items: [
        for (final item in (list as List? ?? const []))
          if (item is Map)
            AnnouncementItem.fromApi(Map<String, dynamic>.from(item)),
      ],
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

  /// شرائح تصميمية تظهر عندما لا توجد إعلانات من الـ API بعد.
  static const demo = AnnouncementsFeed(
    slideshow: AnnouncementSlideshow(intervalSeconds: 5),
    items: [
      AnnouncementItem(
        id: 'demo-1',
        title: 'مرحباً بك في دفتري',
        body: 'هنا تظهر إعلانات الإدارة — صورة، نص، ورابط عند توفرها.',
        pinned: true,
        displaySeconds: 5,
      ),
      AnnouncementItem(
        id: 'demo-2',
        title: 'مثال: رابط خارجي',
        body: 'اضغط الشريحة لفتح رابط (جيميل / موقع الإدارة…).',
        linkUrl: 'https://mail.google.com',
        displaySeconds: 5,
      ),
      AnnouncementItem(
        id: 'demo-3',
        title: 'تابع رصيد إجازاتك',
        body: 'يمكنك تقديم إذن أو إجازة مباشرة من الرئيسية.',
        displaySeconds: 5,
      ),
    ],
  );
}
