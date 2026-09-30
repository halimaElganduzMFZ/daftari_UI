import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/di/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/models/employee_clip.dart';
import '../../data/repositories/documents_repository.dart';
import 'document_viewer_screen.dart';

/// حجم صفحة قائمة المستندات.
const int _kPageSize = 6;

/// قصاصات ومستندات الموظف (بديل getYourPdfs.php) — `GET /me/documents`.
class EmployeeClipsScreen extends StatefulWidget {
  const EmployeeClipsScreen({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.documents`.
  final DocumentsRepository? repository;

  @override
  State<EmployeeClipsScreen> createState() => _EmployeeClipsScreenState();
}

class _EmployeeClipsScreenState extends State<EmployeeClipsScreen> {
  DocumentsRepository get _repo => widget.repository ?? AppServices.documents;

  /// فلتر الشهر `YYYY-MM` (بديل «اختر التاريخ» القديم)؛ `null` = أحدث الملفات.
  String? _month;
  final List<EmployeeClip> _items = [];
  int _page = 0;
  bool _hasNext = false;
  bool _available = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.list(month: _month, page: 1, limit: _kPageSize);
      if (!mounted || seq != _seq) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
        _available = page.available;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _error = describeDocumentError(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    final seq = _seq;
    setState(() => _loadingMore = true);
    try {
      final page =
          await _repo.list(month: _month, page: _page + 1, limit: _kPageSize);
      if (!mounted || seq != _seq) return;
      final known = _items.map((c) => c.id).toSet();
      setState(() {
        _items.addAll(page.items.where((c) => !known.contains(c.id)));
        _page = page.page;
        _hasNext = page.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeDocumentError(e))),
      );
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final initial = _month == null
        ? now
        : DateTime(int.parse(_month!.substring(0, 4)),
            int.parse(_month!.substring(5, 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year, now.month + 1, 0),
      helpText: 'اختر أي يوم من الشهر المطلوب',
      confirmText: 'بحث',
      cancelText: 'إلغاء',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    final ym = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    if (ym == _month) return;
    setState(() => _month = ym);
    _reload();
  }

  void _clearMonth() {
    if (_month == null) return;
    setState(() => _month = null);
    _reload();
  }

  String get _monthLabel {
    if (_month == null) return 'أحدث الملفات';
    final d = DateTime(
      int.parse(_month!.substring(0, 4)),
      int.parse(_month!.substring(5, 7)),
    );
    return DateFormat('MMMM yyyy', 'ar').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('قصاصاتك')),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _buildFilterBar(),
            const SizedBox(height: 12),
            ..._buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF3A3530), Color(0xFF5A4A36)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.folderOpen,
            color: Color(0xFFE2C79A),
            size: 20,
          ),
          SizedBox(height: 10),
          Text(
            'مستنداتك الرسمية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'بطاقات زمنية، قسائم مالية، قسائم إنتاج ورسائل موجّهة إليك — اضغط للمعاينة.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _monthLabel,
            style: const TextStyle(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (_month != null)
          IconButton(
            tooltip: 'إلغاء الفلتر',
            onPressed: _clearMonth,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.slate,
          ),
        OutlinedButton.icon(
          onPressed: _pickMonth,
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: Text(_month == null ? 'بحث بالشهر' : 'تغيير الشهر'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.goldDeep,
            side: const BorderSide(color: AppColors.gold),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildList() {
    if (_loading) {
      return [
        for (var i = 0; i < 4; i++) ...[
          const _ClipSkeleton(),
          const SizedBox(height: 10),
        ],
      ];
    }
    if (_error != null) {
      return [
        _StatusCard(
          icon: FontAwesomeIcons.plugCircleXmark,
          title: 'تعذّر تحميل المستندات',
          message: _error!,
          onRetry: _reload,
        ),
      ];
    }
    if (!_available) {
      return [
        _StatusCard(
          icon: FontAwesomeIcons.database,
          title: 'فهرس المستندات غير متاح حالياً',
          message:
              'قاعدة فهرس القسائم مطفأة أو لا يمكن الوصول إليها من الـ API. حاول لاحقاً.',
          onRetry: _reload,
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        _StatusCard(
          icon: FontAwesomeIcons.folderOpen,
          title: _month == null ? 'لا توجد ملفات بعد' : 'لا توجد ملفات في هذا الشهر',
          message: _month == null
              ? 'عند تجهيز قسيمة أو بطاقة زمنية باسمك ستظهر هنا.'
              : 'جرّب شهراً آخر أو أزل الفلتر لعرض أحدث الملفات.',
        ),
      ];
    }
    return [
      for (final clip in _items) ...[
        _ClipTile(
          clip: clip,
          onOpen: () =>
              DocumentViewerScreen.open(context, clip, repository: widget.repository),
        ),
        const SizedBox(height: 10),
      ],
      if (_hasNext)
        _loadingMore
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('عرض المزيد'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.goldDeep,
                  side: const BorderSide(color: AppColors.gold),
                ),
              ),
    ];
  }
}

class _ClipTile extends StatelessWidget {
  const _ClipTile({required this.clip, required this.onOpen});

  final EmployeeClip clip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = clipStyle(clip.kind);
    final date = clip.date == null
        ? '—'
        : DateFormat('yyyy/MM/dd', 'ar').format(clip.date!);
    return AppSurface(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: FaIcon(style.icon, size: 17, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clip.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$date · ${clip.extension.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onOpen,
            child: const Text('عرض'),
          ),
        ],
      ),
    );
  }
}

class _ClipSkeleton extends StatelessWidget {
  const _ClipSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, {double height = 12}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          bar(46, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(140),
                const SizedBox(height: 8),
                bar(90, height: 10),
              ],
            ),
          ),
          bar(60, height: 36),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final FaIconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        children: [
          FaIcon(icon, size: 28, color: AppColors.slate.withValues(alpha: 0.85)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate, height: 1.45),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldDeep,
                side: const BorderSide(color: AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
