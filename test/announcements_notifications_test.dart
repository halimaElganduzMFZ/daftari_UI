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
      'notifications': {'unread': 4, 'employee': 3, 'manager': 1},
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
    expect(data.notificationCounts.manager, 1);
    expect(data.announcements.items, hasLength(1));
    expect(data.announcements.items.single.hasLink, isTrue);
    expect(data.announcements.slideshow.intervalSeconds, 7);
  });

  test('notification unread accepts numeric payload', () {
    expect(NotificationUnreadCounts.fromApi(5).unread, 5);
  });

  test('announcements feed tolerates missing section', () {
    expect(AnnouncementsFeed.fromApi(null).isEmpty, isTrue);
  });
}
