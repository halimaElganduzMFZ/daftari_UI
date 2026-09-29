import 'package:flutter_test/flutter_test.dart';
import 'package:employee_affairs/data/models/announcements.dart';
import 'package:employee_affairs/data/models/app_notification.dart';
import 'package:employee_affairs/data/models/employee_dashboard.dart';

void main() {
  test('dashboard parses announcements slideshow and unread counts', () {
    final data = EmployeeDashboardData.fromApi({
      'employee': {'fullName': 'أحمد'},
      'leave': {
        'emergency': {'remaining': 5, 'pendingRequests': 0},
        'annual': {'balance': 10, 'pendingRequests': 0},
      },
      'permissions': {
        'monthlyBalance': {'used': 1, 'remaining': 2},
        'monthlyCounts': [],
      },
      'requests': {
        'pending': [],
        'rejected': [],
        'counts': {'pending': 0, 'approved': 0, 'rejected': 0},
      },
      'notifications': {
        'portal': 'employee',
        'unread': 4,
        'employee': 3,
        'manager': 1,
      },
      'announcements': {
        'slideshow': {
          'intervalSeconds': 7,
          'autoplay': true,
          'loop': true,
        },
        'items': [
          {
            'id': 9,
            'title': 'إعلان',
            'body': 'نص',
            'linkUrl': 'https://facebook.com',
            'image': {'url': 'https://example.com/a.jpg'},
            'pinned': true,
            'displaySeconds': 5,
          },
        ],
      },
    });
    expect(data.unreadNotifications, 4);
    expect(data.notificationCounts.portal.name, 'employee');
    expect(data.notificationCounts.manager, 1);
    expect(data.announcements.items, hasLength(1));
    expect(data.announcements.items.single.hasLink, isTrue);
    expect(data.announcements.slideshow.intervalSeconds, 7);
  });

  test('notification unread accepts numeric payload', () {
    expect(NotificationUnreadCounts.fromApi(5).unread, 5);
  });

  test('notification unread parses portal field', () {
    final counts = NotificationUnreadCounts.fromApi({
      'portal': 'manager',
      'unread': 2,
      'employee': 1,
      'manager': 2,
    });
    expect(counts.portal.name, 'manager');
    expect(counts.unread, 2);
    expect(counts.employee, 1);
  });

  test('announcements feed tolerates missing section', () {
    expect(AnnouncementsFeed.fromApi(null).isEmpty, isTrue);
  });

  test('resolves relative announcement image urls against API host', () {
    final item = AnnouncementItem.fromApi({
      'id': 1,
      'title': 'إعلان',
      'image': {'url': '/api/v1/me/announcements/1/image'},
    });
    expect(item.imageUrl, contains('/api/v1/me/announcements/1/image'));
    expect(item.imageUrl, startsWith('http'));
  });

  test('parses bare list announcements payload', () {
    final feed = AnnouncementsFeed.fromApi([
      {'id': 2, 'title': 'أ', 'order': 2},
      {'id': 1, 'title': 'ب', 'pinned': true, 'order': 9},
    ]);
    expect(feed.items.first.pinned, isTrue);
    expect(feed.items.first.title, 'ب');
  });
}
