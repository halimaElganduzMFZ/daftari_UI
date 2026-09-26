import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/repositories/manager_repository.dart';

String managerError(Object error) => error is ApiException
    ? error.message
    : 'تعذّر تحميل البيانات. حاول مرة أخرى.';

String managerText(Object? value) =>
    value == null || value.toString().trim().isEmpty ? '—' : value.toString();

class ManagerError extends StatelessWidget {
  const ManagerError({super.key, required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      children: [
        Text(managerError(error), textAlign: TextAlign.center),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    ),
  );
}

/// Fetches only the requested page. A failed next page preserves previous rows;
/// refresh invalidates outstanding responses and starts from page one.
class ManagerPagedList extends StatefulWidget {
  const ManagerPagedList({
    super.key,
    required this.load,
    required this.itemBuilder,
    this.header = const [],
    this.onRefresh,
  });
  final Future<ManagerPage> Function(int page) load;
  final Widget Function(ManagerJson item) itemBuilder;
  final List<Widget> header;
  final Future<void> Function()? onRefresh;
  @override
  State<ManagerPagedList> createState() => ManagerPagedListState();
}

class ManagerPagedListState extends State<ManagerPagedList> {
  List<ManagerJson> _items = [];
  int _page = 0;
  int _generation = 0;
  int? _total;
  bool _hasNext = false;
  bool _loading = false;
  Object? _error;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    _generation++;
    setState(() {
      _items = [];
      _page = 0;
      _total = null;
      _hasNext = false;
      _loading = false;
    });
    await Future.wait([
      _load(),
      if (widget.onRefresh != null) widget.onRefresh!(),
    ]);
  }

  Future<void> _load() async {
    if (_loading) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.load(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        final ids = _items.map((e) => e['id']).toSet();
        _items.addAll(result.items.where((e) => ids.add(e['id'])));
        _page++;
        _hasNext = result.hasNext;
        _total = result.total;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: refresh,
    child: ListView(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...widget.header,
        Row(
          children: [
            Expanded(
              child: Text(
                _total == null ? '' : 'عدد النتائج: $_total',
                style: const TextStyle(color: AppColors.slate),
              ),
            ),
            IconButton(
              onPressed: _loading ? null : refresh,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget.itemBuilder(item),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ManagerError(error: _error!, retry: _load),
        if (!_loading && _error == null && _items.isEmpty)
          const AppSurface(
            child: Text('لا توجد نتائج', textAlign: TextAlign.center),
          ),
        if (!_loading && _error == null && _hasNext)
          OutlinedButton(onPressed: _load, child: const Text('عرض المزيد')),
      ],
    ),
  );
}

class ManagerInfo extends StatelessWidget {
  const ManagerInfo(this.label, this.value, {super.key});
  final String label;
  final Object? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      '$label: ${managerText(value)}',
      style: const TextStyle(height: 1.6),
    ),
  );
}

/// Horizontal swipe reveals تفاصيل / موافقة / رفض behind the request card.
class ManagerSwipeActions extends StatefulWidget {
  const ManagerSwipeActions({
    super.key,
    required this.child,
    required this.onDetails,
    required this.onApprove,
    required this.onReject,
  });
  final Widget child;
  final VoidCallback onDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  @override
  State<ManagerSwipeActions> createState() => _ManagerSwipeActionsState();
}

class _ManagerSwipeActionsState extends State<ManagerSwipeActions>
    with SingleTickerProviderStateMixin {
  static const _extent = 78.0;
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = (_rtl ? details.delta.dx : -details.delta.dx) / _extent;
    _open.value = (_open.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = _rtl
        ? details.primaryVelocity ?? 0
        : -(details.primaryVelocity ?? 0);
    if (velocity > 400 || (_open.value > 0.45 && velocity >= -200)) {
      _open.forward();
    } else {
      _open.reverse();
    }
  }

  Future<void> _run(VoidCallback action) async {
    await _open.reverse();
    if (mounted) action();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _open,
    builder: (context, _) {
      final shift = _extent * _open.value;
      final dx = _rtl ? shift : -shift;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.goldSoft.withValues(alpha: .55),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: _extent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SwipeAction(
                          icon: Icons.info_outline_rounded,
                          label: 'تفاصيل',
                          color: AppColors.info,
                          onTap: () => _run(widget.onDetails),
                        ),
                        _SwipeAction(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'موافقة',
                          color: AppColors.success,
                          onTap: () => _run(widget.onApprove),
                        ),
                        _SwipeAction(
                          icon: Icons.cancel_outlined,
                          label: 'رفض',
                          color: AppColors.danger,
                          onTap: () => _run(widget.onReject),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: widget.child,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<String?> managerNoteDialog(
  BuildContext context, {
  required String title,
  required int maxLength,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NoteDialog(title, maxLength),
);

class _NoteDialog extends StatefulWidget {
  const _NoteDialog(this.title, this.maxLength);
  final String title;
  final int maxLength;
  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      maxLength: widget.maxLength,
      maxLines: 4,
      autofocus: true,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(labelText: 'الملاحظة مطلوبة'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _controller.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('تأكيد'),
      ),
    ],
  );
}
