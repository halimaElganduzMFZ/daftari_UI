import '../../core/network/api_client.dart';
import '../models/announcements.dart';
import '../models/app_notification.dart';

/// إشعارات الموظف/المدير — `GET/POST /me/notifications`.
abstract class NotificationsRepository {
  Future<NotificationsPage> list({
    bool? unread,
    String? audience,
    String? kind,
    int page = 1,
    int limit = 20,
  });

  Future<NotificationUnreadCounts> unreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._client);
  final ApiClient _client;

  @override
  Future<NotificationsPage> list({
    bool? unread,
    String? audience,
    String? kind,
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _client.getJson(
      '/me/notifications',
      query: {
        if (unread != null) 'unread': unread ? 'true' : 'false',
        if (audience != null) 'audience': audience,
        if (kind != null) 'kind': kind,
        'page': '$page',
        'limit': '$limit',
        'withTotal': 'true',
      },
    );
    return NotificationsPage.fromApi(json);
  }

  @override
  Future<NotificationUnreadCounts> unreadCount() async {
    final json = await _client.getJson('/me/notifications/unread-count');
    return NotificationUnreadCounts.fromApi(json);
  }

  @override
  Future<void> markRead(String id) async {
    await _client.postJson('/me/notifications/$id/read', auth: true);
  }

  @override
  Future<void> markAllRead() async {
    await _client.postJson('/me/notifications/read-all', auth: true);
  }
}

class StaticNotificationsRepository implements NotificationsRepository {
  StaticNotificationsRepository();

  final _items = <AppNotification>[
    AppNotification(
      id: 'n1',
      title: 'طلب جديد بانتظار قرارك',
      body: 'إجازة سنوية من موظف في هيكلك — راجع الموافقات.',
      kind: 'REQUEST_PENDING',
      audience: 'manager',
      createdAt: '2026-09-28 09:00:00',
    ),
    AppNotification(
      id: 'n2',
      title: 'موافقة مرحلية على طلبك',
      body: 'تمت موافقة المدير المباشر؛ الطلب بانتظار المستوى الأعلى.',
      kind: 'REQUEST_INTERMEDIATE',
      audience: 'employee',
      createdAt: '2026-09-27 14:20:00',
    ),
  ];

  @override
  Future<NotificationsPage> list({
    bool? unread,
    String? audience,
    String? kind,
    int page = 1,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final filtered = [
      for (final n in _items)
        if ((unread == null || (unread ? !n.isRead : n.isRead)) &&
            (audience == null || n.audience == audience) &&
            (kind == null || n.kind == kind))
          n,
    ];
    return NotificationsPage(
      items: filtered,
      hasNext: false,
      total: filtered.length,
    );
  }

  @override
  Future<NotificationUnreadCounts> unreadCount() async {
    final unread = _items.where((n) => !n.isRead).length;
    return NotificationUnreadCounts(
      unread: unread,
      employee: _items.where((n) => !n.isRead && n.audience == 'employee').length,
      manager: _items.where((n) => !n.isRead && n.audience == 'manager').length,
    );
  }

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0) return;
    final n = _items[i];
    _items[i] = AppNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      kind: n.kind,
      audience: n.audience,
      requestId: n.requestId,
      route: n.route,
      readAt: DateTime.now().toIso8601String(),
      createdAt: n.createdAt,
    );
  }

  @override
  Future<void> markAllRead() async {
    for (final n in List<AppNotification>.from(_items)) {
      await markRead(n.id);
    }
  }
}

/// إعلانات الشاشة الرئيسية — عادةً من اللوحة؛ مسار احتياطي مستقل.
abstract class AnnouncementsRepository {
  Future<AnnouncementsFeed> mine();
}

class ApiAnnouncementsRepository implements AnnouncementsRepository {
  const ApiAnnouncementsRepository(this._client);
  final ApiClient _client;

  @override
  Future<AnnouncementsFeed> mine() async {
    final json = await _client.getJson('/me/announcements');
    return AnnouncementsFeed.fromApi(json);
  }
}

class StaticAnnouncementsRepository implements AnnouncementsRepository {
  const StaticAnnouncementsRepository();

  @override
  Future<AnnouncementsFeed> mine() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const AnnouncementsFeed(
      slideshow: AnnouncementSlideshow(intervalSeconds: 5),
      items: [
        AnnouncementItem(
          id: 'a1',
          title: 'مرحباً بك في دفتري',
          body: 'تابع طلباتك ومواعيد دوامك من مكان واحد.',
          pinned: true,
          displaySeconds: 5,
        ),
        AnnouncementItem(
          id: 'a2',
          title: 'تذكير: راجع رصيد إجازاتك',
          body: 'يمكنك تقديم طلب إجازة أو إذن مباشرة من الرئيسية.',
          displaySeconds: 5,
        ),
      ],
    );
  }
}
