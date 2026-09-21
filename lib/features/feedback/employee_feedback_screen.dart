import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_message.dart';
import '../../data/repositories/messages_repository.dart';
import '../../data/session/app_session.dart';

enum _MessageKind { complaint, suggestion }

/// حجم صفحة قائمة الرسائل السابقة.
const int _kPageSize = 5;

/// إرسال شكوى أو مقترح من الموظف + قائمة رسائله السابقة (بديل sendMessage.php).
class EmployeeFeedbackScreen extends StatefulWidget {
  const EmployeeFeedbackScreen({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.messages`.
  final MessagesRepository? repository;

  @override
  State<EmployeeFeedbackScreen> createState() => _EmployeeFeedbackScreenState();
}

class _EmployeeFeedbackScreenState extends State<EmployeeFeedbackScreen> {
  final _controller = TextEditingController();
  _MessageKind _kind = _MessageKind.suggestion;
  bool _sending = false;

  MessagesRepository get _repo => widget.repository ?? AppServices.messages;

  // ---- قائمة الرسائل السابقة ----
  MessageStatus? _filter; // null = الكل
  MessageCounts _counts = MessageCounts.zero;
  final List<EmployeeMessage> _items = [];
  int _page = 0;
  bool _hasNext = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// يعيد تحميل العدّادات والصفحة الأولى للفلتر الحالي.
  Future<void> _reload() async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.counts(),
        _repo.list(status: _filter, page: 1, limit: _kPageSize),
      ]);
      if (!mounted || seq != _requestSeq) return;
      final page = results[1] as MessagesPage;
      setState(() {
        _counts = results[0] as MessageCounts;
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _error = _describe(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    final seq = _requestSeq;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.list(
        status: _filter,
        page: _page + 1,
        limit: _kPageSize,
      );
      if (!mounted || seq != _requestSeq) return;
      final known = _items.map((m) => m.key).toSet();
      setState(() {
        _items.addAll(page.items.where((m) => !known.contains(m.key)));
        _page = page.page;
        _hasNext = page.hasNext;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describe(e))),
      );
    }
  }

  void _setFilter(MessageStatus? status) {
    if (status == _filter) return;
    setState(() => _filter = status);
    _reload();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب نص الرسالة أولاً')),
      );
      return;
    }
    // الجدول القديم بلا حقل «نوع»، فنُسبق النص بالتصنيف ليراه قسم الموارد البشرية.
    final prefix = _kind == _MessageKind.complaint ? 'شكوى' : 'مقترح';
    final alreadyPrefixed = text.startsWith('شكوى') || text.startsWith('مقترح');
    var body = alreadyPrefixed ? text : '$prefix: $text';
    if (body.length > MessagesRepository.maxLength) {
      body = body.substring(0, MessagesRepository.maxLength);
    }

    setState(() => _sending = true);
    try {
      final result = await _repo.send(body);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _controller.clear();
        // أدرج الرسالة أعلى القائمة إن كانت تطابق الفلتر الحالي.
        if (_filter == null || _filter == result.sent.status) {
          _items.removeWhere((m) => m.key == result.sent.key);
          _items.insert(0, result.sent);
        }
        _counts = MessageCounts(
          total: _counts.total + 1,
          sent: _counts.sent + 1,
          read: _counts.read,
          replied: _counts.replied,
        );
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تم الإرسال'),
          content: Text(
            '${result.message}. سيتم مراجعتها من الجهة المختصة وستجد الرد هنا.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isDuplicate(e) ? 'رسالة مكرّرة' : 'لم يتم الإرسال'),
          content: Text(_describe(e)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    }
  }

  bool _isDuplicate(Object e) =>
      e is ApiException && (e.statusCode == 409 || e.code == 'DUPLICATE_MESSAGE');

  String _describe(Object e) {
    if (e is ApiException) {
      if (_isDuplicate(e)) {
        return 'أرسلت نفس النص اليوم من قبل. عدّل الرسالة أو انتظر حتى الغد.';
      }
      if (e.statusCode == 400) return 'نص الرسالة مطلوب ولا يتجاوز 1500 حرف.';
      if (e.statusCode == 401) return 'انتهت الجلسة، أعد تسجيل الدخول.';
      if (e.statusCode == 403) return 'هذه الميزة متاحة لحساب الموظف فقط.';
      if (e.isNetwork) return 'لا يوجد اتصال بالخادم. تحقق من الشبكة وحاول مجدداً.';
      return e.message;
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final name = employee?.fullName ?? 'موظف';
    final number = employee?.employeeNumber ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('شكوى أو مقترح')),
      body: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _buildForm(name, number),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'رسائلك السابقة',
              subtitle: _counts.total == 0
                  ? 'تظهر هنا ردود الموارد البشرية على ما ترسله'
                  : '${_counts.total} رسالة · ${_counts.replied} تم الرد عليها',
            ),
            const SizedBox(height: 12),
            _buildFilters(),
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
            FontAwesomeIcons.envelopeOpenText,
            color: Color(0xFFE2C79A),
            size: 20,
          ),
          SizedBox(height: 10),
          Text(
            'صوتك مسموع',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'أرسل شكوى أو مقترحاً لتحسين بيئة العمل — بهدوء ووضوح.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(String name, String number) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بياناتك',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Text('الاسم: $name', style: const TextStyle(color: AppColors.slate)),
          const SizedBox(height: 4),
          Text(
            'الرقم الوظيفي: $number',
            style: const TextStyle(color: AppColors.slate),
          ),
          const SizedBox(height: 14),
          const Text(
            'نوع الرسالة',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KindChip(
                  label: 'مقترح',
                  icon: FontAwesomeIcons.lightbulb,
                  selected: _kind == _MessageKind.suggestion,
                  onTap: () => setState(() => _kind = _MessageKind.suggestion),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KindChip(
                  label: 'شكوى',
                  icon: FontAwesomeIcons.commentDots,
                  selected: _kind == _MessageKind.complaint,
                  onTap: () => setState(() => _kind = _MessageKind.complaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'نص الرسالة',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 7,
            maxLength: MessagesRepository.maxLength,
            textAlign: TextAlign.right,
            enabled: !_sending,
            decoration: const InputDecoration(
              hintText: 'اكتب هنا بوضوح…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'جاري الإرسال…' : 'إرسال المراسلة'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const options = <(MessageStatus?, String)>[
      (null, 'الكل'),
      (MessageStatus.sent, 'بانتظار القراءة'),
      (MessageStatus.read, 'مقروءة'),
      (MessageStatus.replied, 'تم الرد'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (status, label) in options) ...[
            _FilterChip(
              label: label,
              count: _counts.of(status),
              selected: _filter == status,
              onTap: () => _setFilter(status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildList() {
    if (_loading) {
      return [
        for (var i = 0; i < 3; i++) ...[
          const _MessageSkeleton(),
          const SizedBox(height: 10),
        ],
      ];
    }
    if (_error != null) {
      return [_ErrorCard(message: _error!, onRetry: _reload)];
    }
    if (_items.isEmpty) {
      return [
        AppSurface(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
          child: Column(
            children: [
              const FaIcon(
                FontAwesomeIcons.inbox,
                size: 26,
                color: AppColors.slate,
              ),
              const SizedBox(height: 10),
              Text(
                _filter == null
                    ? 'لا توجد رسائل بعد'
                    : 'لا توجد رسائل بهذه الحالة',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final message in _items) ...[
        _MessageCard(message: message),
        const SizedBox(height: 10),
      ],
      if (_hasNext)
        Center(
          child: _loadingMore
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('عرض المزيد'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.goldDeep,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
        ),
    ];
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FaIconData icon;
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 14,
                color: selected ? AppColors.goldDeep : AppColors.slate,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.goldDeep : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      color: selected ? AppColors.charcoal : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.charcoal : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.charcoal,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white24 : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.goldDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final EmployeeMessage message;

  StatusTone get _tone => switch (message.status) {
        MessageStatus.replied => StatusTone.success,
        MessageStatus.read => StatusTone.info,
        MessageStatus.sent => StatusTone.warning,
        MessageStatus.unknown => StatusTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message.body,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: message.statusLabel,
                child: StatusPill(
                  label: EmployeeMessage.shortLabel(message.status),
                  tone: _tone,
                ),
              ),
            ],
          ),
          if (message.hasReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EB),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  right: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.7),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.reply,
                        size: 12,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'رد الموارد البشرية',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.reply!.trim(),
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageSkeleton extends StatelessWidget {
  const _MessageSkeleton();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              bar(80),
              const Spacer(),
              bar(70, height: 20),
            ],
          ),
          const SizedBox(height: 14),
          bar(double.infinity),
          const SizedBox(height: 8),
          bar(200),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.plugCircleXmark,
            size: 26,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          const Text(
            'تعذّر تحميل الرسائل',
            textAlign: TextAlign.center,
            style: TextStyle(
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
