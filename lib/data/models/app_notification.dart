/// إشعارات التطبيق (`GET /me/notifications`).
library;

int? _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
String? _str(Object? v) => v == null ? null : '$v'.trim();
Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

class NotificationUnreadCounts {
  const NotificationUnreadCounts({
    this.unread = 0,
    this.employee = 0,
    this.manager = 0,
  });

  factory NotificationUnreadCounts.fromApi(Object? raw) {
    if (raw is num) {
      final n = raw.toInt();
      return NotificationUnreadCounts(unread: n, employee: n);
    }
    final json = _map(raw);
    if (json == null) return const NotificationUnreadCounts();
    final unread = _int(json['unread']) ?? 0;
    return NotificationUnreadCounts(
      unread: unread,
      employee: _int(json['employee']) ?? unread,
      manager: _int(json['manager']) ?? 0,
    );
  }

  final int unread;
  final int employee;
  final int manager;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.audience,
    this.requestId,
    this.route,
    this.readAt,
    this.createdAt,
  });

  factory AppNotification.fromApi(Map<String, dynamic> json) => AppNotification(
    id: '${json['id'] ?? ''}',
    title: _str(json['title']) ?? '',
    body: _str(json['body'] ?? json['text']) ?? '',
    kind: _str(json['kind']) ?? '',
    audience: _str(json['audience']) ?? 'employee',
    requestId: json['requestId']?.toString(),
    route: _str(json['route'] ?? json['openPath']),
    readAt: _str(json['readAt']),
    createdAt: _str(json['createdAt'] ?? json['sentAt']),
  );

  final String id;
  final String title;
  final String body;
  final String kind;
  final String audience;
  final String? requestId;
  final String? route;
  final String? readAt;
  final String? createdAt;

  bool get isRead => (readAt ?? '').isNotEmpty;
}

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.hasNext,
    this.total,
  });

  factory NotificationsPage.fromApi(Map<String, dynamic> json) {
    final meta = _map(json['meta']) ?? const {};
    return NotificationsPage(
      items: [
        for (final item in (json['data'] as List? ?? const []))
          if (item is Map)
            AppNotification.fromApi(Map<String, dynamic>.from(item)),
      ],
      hasNext: meta['hasNext'] == true,
      total: _int(meta['total']),
    );
  }

  final List<AppNotification> items;
  final bool hasNext;
  final int? total;
}
