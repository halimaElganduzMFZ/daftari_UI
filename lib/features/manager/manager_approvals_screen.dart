import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/static/static_awol.dart';
import '../../data/static/static_manager_approvals.dart';
import 'manager_absentees_screen.dart';

enum _InboxTab { all, permissions, leaves }

enum _ViewMode { focus, list }

/// صندوق وارد المدير — تبويبات + طلب فردي / قائمة لمئات الطلبات.
class ManagerApprovalsScreen extends StatefulWidget {
  const ManagerApprovalsScreen({super.key, required this.structureName});

  final String structureName;

  @override
  State<ManagerApprovalsScreen> createState() => _ManagerApprovalsScreenState();
}

class _ManagerApprovalsScreenState extends State<ManagerApprovalsScreen> {
  late final List<PendingManagerRequest> _requests;
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('yyyy/MM/dd — HH:mm', 'ar');

  static const _listPageSize = 15;

  _InboxTab _tab = _InboxTab.all;
  _ViewMode _mode = _ViewMode.focus;
  int _focusIndex = 0;
  String _query = '';
  final Set<String> _selectedIds = {};
  int _listVisibleCount = _listPageSize;

  @override
  void initState() {
    super.initState();
    _requests = List<PendingManagerRequest>.from(
      StaticManagerApprovals.pending,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetListPaging() => _listVisibleCount = _listPageSize;

  List<PendingManagerRequest> get _pendingFiltered {
    var list = _requests.where((r) => r.isPending).toList();
    switch (_tab) {
      case _InboxTab.permissions:
        list = list
            .where((r) => r.kind == ManagerRequestKind.permission)
            .toList();
      case _InboxTab.leaves:
        list =
            list.where((r) => r.kind == ManagerRequestKind.leave).toList();
      case _InboxTab.all:
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final qDigits = q.replaceAll(RegExp(r'[\s\-]'), '');
      list = list
          .where((r) {
            final name = r.employeeName.toLowerCase();
            final number = r.employeeNumber.toLowerCase();
            final numberDigits = number.replaceAll(RegExp(r'[\s\-]'), '');
            return name.contains(q) ||
                number.contains(q) ||
                numberDigits.contains(qDigits);
          })
          .toList();
    }
    return list;
  }

  int get _permissionCount => _requests
      .where((r) => r.isPending && r.kind == ManagerRequestKind.permission)
      .length;

  int get _leaveCount => _requests
      .where((r) => r.isPending && r.kind == ManagerRequestKind.leave)
      .length;

  int get _allPendingCount => _requests.where((r) => r.isPending).length;

  void _clampFocus(List<PendingManagerRequest> pending) {
    if (pending.isEmpty) {
      _focusIndex = 0;
      return;
    }
    if (_focusIndex >= pending.length) {
      _focusIndex = pending.length - 1;
    }
  }

  Future<void> _approve(PendingManagerRequest request) async {
    setState(() {
      request.decision = ManagerDecision.approved;
      request.statusLabel = 'تمت موافقة المدير المباشر';
      _selectedIds.remove(request.id);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت الموافقة على طلب ${request.employeeName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reject(PendingManagerRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectReasonDialog(),
    );
    if (reason == null || !mounted) return;
    setState(() {
      request.decision = ManagerDecision.rejected;
      request.rejectReason = reason;
      request.statusLabel = 'تم الرفض من المدير المباشر';
      _selectedIds.remove(request.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم رفض طلب ${request.employeeName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _bulkApprove() async {
    final ids = {..._selectedIds};
    if (ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('موافقة جماعية'),
        content: Text('الموافقة على ${ids.length} طلب محدد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.approve),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      for (final request in _requests) {
        if (ids.contains(request.id) && request.isPending) {
          request.decision = ManagerDecision.approved;
          request.statusLabel = 'تمت موافقة المدير المباشر';
        }
      }
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت الموافقة على ${ids.length} طلب'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAbsentees() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ManagerAbsenteesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingFiltered;
    _clampFocus(pending);
    final focusItem = pending.isEmpty ? null : pending[_focusIndex];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.structureName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldDeep,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'صندوق الطلبات',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                _NotificationBell(
                  count: StaticAwol.notificationCount,
                  onTap: _openAbsentees,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _MiniStat(
                    label: 'بانتظارك',
                    value: '$_allPendingCount',
                    color: AppColors.warning,
                  ),
                  _vline(),
                  _MiniStat(
                    label: 'موافقة الشهر',
                    value: '${StaticManagerApprovals.approvedThisMonth}',
                    color: AppColors.success,
                  ),
                  _vline(),
                  _MiniStat(
                    label: 'رفض الشهر',
                    value: '${StaticManagerApprovals.rejectedThisMonth}',
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {
                _query = value;
                _focusIndex = 0;
                _resetListPaging();
              }),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الرقم الوظيفي',
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: AppColors.background,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _focusIndex = 0;
                            _resetListPaging();
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _TabChip(
                    label: 'الكل',
                    count: _allPendingCount,
                    selected: _tab == _InboxTab.all,
                    onTap: () => setState(() {
                      _tab = _InboxTab.all;
                      _focusIndex = 0;
                      _resetListPaging();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabChip(
                    label: 'أذونات',
                    count: _permissionCount,
                    selected: _tab == _InboxTab.permissions,
                    onTap: () => setState(() {
                      _tab = _InboxTab.permissions;
                      _focusIndex = 0;
                      _resetListPaging();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabChip(
                    label: 'إجازات',
                    count: _leaveCount,
                    selected: _tab == _InboxTab.leaves,
                    onTap: () => setState(() {
                      _tab = _InboxTab.leaves;
                      _focusIndex = 0;
                      _resetListPaging();
                    }),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('طلب فردي'),
                  selected: _mode == _ViewMode.focus,
                  onSelected: (_) => setState(() {
                    _mode = _ViewMode.focus;
                    _resetListPaging();
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('قائمة'),
                  selected: _mode == _ViewMode.list,
                  onSelected: (_) => setState(() {
                    _mode = _ViewMode.list;
                    _resetListPaging();
                  }),
                ),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: _bulkApprove,
                    child: Text('موافقة (${_selectedIds.length})'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: pending.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد طلبات في هذا التبويب',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  )
                : _mode == _ViewMode.focus
                    ? _FocusInbox(
                        request: focusItem!,
                        index: _focusIndex,
                        total: pending.length,
                        dateLabel: _dateFormat.format(focusItem.submittedAt),
                        onPrev: _focusIndex > 0
                            ? () => setState(() => _focusIndex--)
                            : null,
                        onNext: _focusIndex < pending.length - 1
                            ? () => setState(() => _focusIndex++)
                            : null,
                        onApprove: () => _approve(focusItem),
                        onReject: () => _reject(focusItem),
                      )
                    : Builder(
                        builder: (context) {
                          final visible = pending.take(_listVisibleCount).toList();
                          final hasMore = _listVisibleCount < pending.length;
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: visible.length + (hasMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (hasMore && index == visible.length) {
                                return OutlinedButton.icon(
                                  onPressed: () => setState(() {
                                    _listVisibleCount = (_listVisibleCount +
                                            _listPageSize)
                                        .clamp(0, pending.length);
                                  }),
                                  icon: const Icon(Icons.expand_more_rounded),
                                  label: Text(
                                    'عرض المزيد (${pending.length - visible.length})',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    foregroundColor: AppColors.goldDeep,
                                    side: const BorderSide(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                );
                              }

                              final request = visible[index];
                              final selected =
                                  _selectedIds.contains(request.id);
                              return _CompactRequestTile(
                                request: request,
                                dateLabel: _dateFormat
                                    .format(request.submittedAt),
                                selected: selected,
                                onToggleSelect: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedIds.remove(request.id);
                                    } else {
                                      _selectedIds.add(request.id);
                                    }
                                  });
                                },
                                onApprove: () => _approve(request),
                                onReject: () => _reject(request),
                                onOpenFocus: () => setState(() {
                                  _mode = _ViewMode.focus;
                                  _focusIndex = pending.indexOf(request);
                                }),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _vline() =>
      Container(width: 1, height: 36, color: AppColors.line);
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'المنقطعون',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.danger,
        child: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.warning,
          size: 28,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.goldSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.goldDeep : AppColors.slate,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.charcoal : AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusInbox extends StatelessWidget {
  const _FocusInbox({
    required this.request,
    required this.index,
    required this.total,
    required this.dateLabel,
    required this.onPrev,
    required this.onNext,
    required this.onApprove,
    required this.onReject,
  });

  final PendingManagerRequest request;
  final int index;
  final int total;
  final String dateLabel;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final kindLabel =
        request.kind == ManagerRequestKind.leave ? 'إجازة' : 'إذن';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Expanded(
                child: Text(
                  '${index + 1} من $total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AppSurface(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kindLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDeep,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    request.employeeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.employeeNumber,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    request.typeLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.statusLabel,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (request.notes != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        request.notes!,
                        style: const TextStyle(
                          color: AppColors.slate,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text(AppStrings.approve),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text(AppStrings.reject),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRequestTile extends StatelessWidget {
  const _CompactRequestTile({
    required this.request,
    required this.dateLabel,
    required this.selected,
    required this.onToggleSelect,
    required this.onApprove,
    required this.onReject,
    required this.onOpenFocus,
  });

  final PendingManagerRequest request;
  final String dateLabel;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenFocus;

  @override
  Widget build(BuildContext context) {
    final kindLabel =
        request.kind == ManagerRequestKind.leave ? 'إجازة' : 'إذن';

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onToggleSelect(),
          ),
          Expanded(
            child: InkWell(
              onTap: onOpenFocus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.employeeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.typeLabel} · $kindLabel',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.approve,
            onPressed: onApprove,
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          IconButton(
            tooltip: AppStrings.reject,
            onPressed: onReject,
            icon: const Icon(
              Icons.cancel_outlined,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.rejectReasonTitle),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: AppStrings.rejectReasonHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context, text);
          },
          child: const Text(AppStrings.reject),
        ),
      ],
    );
  }
}
