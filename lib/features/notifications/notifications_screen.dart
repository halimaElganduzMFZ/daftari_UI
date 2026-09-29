import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notifications_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.repository});
  final NotificationsRepository? repository;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationsRepository get _repo =>
      widget.repository ?? AppServices.notifications;
  final _items = <AppNotification>[];
  bool _loading = true;
  Object? _error;
  bool _unreadOnly = false;

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
      // الصندوق يتبع portal الجلسة على الخادم — بلا معامل audience.
      final page = await _repo.list(
        unread: _unreadOnly ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
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

  Future<void> _markAll() async {
    try {
      await _repo.markAllRead();
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'تعذّر تعليم الإشعارات كمقروءة',
          ),
        ),
      );
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      try {
        await _repo.markRead(item.id);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      final i = _items.indexWhere((n) => n.id == item.id);
      if (i >= 0) {
        _items[i] = AppNotification(
          id: item.id,
          title: item.title,
          body: item.body,
          kind: item.kind,
          audience: item.audience,
          requestId: item.requestId,
          route: item.route,
          readAt: item.readAt ?? DateTime.now().toIso8601String(),
          createdAt: item.createdAt,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('الإشعارات'),
      actions: [
        TextButton(
          onPressed: _items.isEmpty ? null : _markAll,
          child: const Text('قراءة الكل'),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('الكل'),
                selected: !_unreadOnly,
                onSelected: (_) {
                  setState(() => _unreadOnly = false);
                  _load();
                },
              ),
              ChoiceChip(
                label: const Text('غير مقروء'),
                selected: _unreadOnly,
                onSelected: (_) {
                  setState(() => _unreadOnly = true);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            AppSurface(
              child: Column(
                children: [
                  Text(
                    _error is ApiException
                        ? (_error as ApiException).message
                        : 'تعذّر تحميل الإشعارات',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(onPressed: _load, child: const Text('إعادة')),
                ],
              ),
            )
          else if (_items.isEmpty)
            const AppSurface(
              child: Text(
                'لا توجد إشعارات حالياً.\n'
                'بعد موافقة/رفض طلبك اسحب للتحديث، أو تأكد أن خادم الإشعارات مفعّل.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppSurface(
                  onTap: () => _open(item),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? AppColors.background
                              : AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.isRead
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_active_rounded,
                          color: AppColors.goldDeep,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: item.isRead
                                    ? AppColors.slate
                                    : AppColors.charcoal,
                              ),
                            ),
                            if (item.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: const TextStyle(
                                  color: AppColors.slate,
                                  height: 1.4,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (item.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.createdAt!,
                                style: const TextStyle(
                                  color: AppColors.slate,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!item.isRead)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: FaIcon(
                            FontAwesomeIcons.circle,
                            size: 8,
                            color: AppColors.gold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
