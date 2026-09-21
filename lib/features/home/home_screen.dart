import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_dashboard.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/session/app_session.dart';
import '../assets/employee_assets_screen.dart';
import '../clips/employee_clips_screen.dart';
import '../feedback/employee_feedback_screen.dart';
import '../healthcare/healthcare_specialties_screen.dart';
import '../timesheet/timesheet_hub_screen.dart';

/// الصفحة الرئيسية للموظف العادي — من index.php بتوزيع أوضح وأقل ازدحاماً.
///
/// المصدر: [DashboardRepository] (`GET /me/dashboard` للأرصدة والمعلّقة/المرفوضة،
/// و`GET /me/requests?status=` للتصفح). في وضع التصميم يعمل نفس الكود فوق
/// البيانات الثابتة.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNewRequest});

  /// ينقل المستخدم لتبويب تقديم الطلب من الـ Shell.
  final VoidCallback? onNewRequest;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// حالة قائمة طلبات لحالة واحدة (معلّقة/مقبولة/مرفوضة) مع التصفح.
class _RequestsFeed {
  _RequestsFeed();

  final List<EmployeeRequest> items = [];
  final Set<String> _ids = {};

  /// حجم الصفحة عند طلب المزيد من الخادم.
  int limit = _HomeScreenState._pageSize;

  /// عدد العناصر الظاهرة (تصفح محلي قبل طلب صفحة جديدة).
  int visible = 0;

  /// آخر صفحة محمّلة (0 = لم يُطلب شيء بعد).
  int page = 0;
  bool hasNext = true;
  bool loading = false;
  Object? error;

  bool get started => page > 0;
  bool get canShowMore => visible < items.length || hasNext;

  void seed(List<EmployeeRequest> seeded, {required bool more, int? limit}) {
    reset();
    if (limit != null) this.limit = limit;
    append(seeded);
    page = 1;
    hasNext = more;
    visible = seeded.length.clamp(0, _HomeScreenState._pageSize);
  }

  void append(Iterable<EmployeeRequest> more) {
    for (final r in more) {
      if (_ids.add(r.id)) items.add(r);
    }
  }

  void reset() {
    items.clear();
    _ids.clear();
    visible = 0;
    page = 0;
    hasNext = true;
    loading = false;
    error = null;
  }
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 6;

  /// حجم القائمة المضمّنة في `/me/dashboard` لكل حالة.
  static const _dashboardListSize = 20;

  final DashboardRepository _repo = AppServices.dashboard;

  RequestStatus _filter = RequestStatus.pending;
  EmployeeDashboardData? _data;
  Object? _error;
  bool _loading = true;

  final Map<RequestStatus, _RequestsFeed> _feeds = {
    for (final s in RequestStatus.values) s: _RequestsFeed(),
  };

  _RequestsFeed get _feed => _feeds[_filter]!;

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
      final data = await _repo.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _seedFeeds(data);
        _loading = false;
      });
      if (!_feed.started) _loadMore(_filter);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  /// المعلّقة والمرفوضة تأتي داخل اللوحة (حتى 20)؛ المقبولة تُجلب عند الطلب.
  void _seedFeeds(EmployeeDashboardData data) {
    for (final status in [RequestStatus.pending, RequestStatus.rejected]) {
      final items = data.byStatus(status);
      final total = data.counts?.of(status);
      _feeds[status]!.seed(
        items,
        more: total != null
            ? total > items.length
            : items.length >= _dashboardListSize,
        limit: _dashboardListSize,
      );
    }
    _feeds[RequestStatus.approved]!
      ..reset()
      ..limit = _pageSize;
  }

  Future<void> _loadMore(RequestStatus status) async {
    final feed = _feeds[status]!;
    if (feed.loading || (feed.started && !feed.hasNext)) return;
    setState(() {
      feed.loading = true;
      feed.error = null;
    });
    try {
      final page = await _repo.requests(
        status: status,
        page: feed.page + 1,
        limit: feed.limit,
      );
      if (!mounted) return;
      setState(() {
        feed.append(page.items);
        feed.page = page.page;
        feed.hasNext = page.hasNext;
        feed.visible = (feed.visible + _pageSize).clamp(0, feed.items.length);
        feed.loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        feed.error = error;
        feed.loading = false;
      });
    }
  }

  void _showMore() {
    final feed = _feed;
    if (feed.visible < feed.items.length) {
      setState(() {
        feed.visible = (feed.visible + _pageSize).clamp(0, feed.items.length);
      });
      return;
    }
    if (feed.hasNext) _loadMore(_filter);
  }

  void _changeFilter(RequestStatus status) {
    setState(() => _filter = status);
    if (!_feed.started && _data != null) _loadMore(status);
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'حدث خطأ غير متوقع أثناء تحميل البيانات.';
  }

  String _countLabel(RequestStatus status) {
    final count = _data?.counts?.of(status);
    return count == null ? '' : ' ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final data = _data;
    final feed = _feed;
    final visible = feed.items.take(feed.visible).toList();
    final totalForStatus = data?.counts?.of(_filter) ?? feed.items.length;
    final initialLoading = _loading && data == null;

    final name = (data?.employeeName ?? '').isNotEmpty
        ? data!.employeeName!
        : employee?.fullName ?? 'الموظف';
    final department = (data?.workplaceName ?? '').isNotEmpty
        ? data!.workplaceName!
        : employee?.department ?? '—';

    String balance(int value, {bool available = true}) {
      if (initialLoading) return '…';
      if (!available) return '—';
      return '$value';
    }

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.goldDeep,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: _WelcomeHeader(
                  name: name,
                  jobTitle: employee?.jobTitle ?? 'موظف',
                  department: department,
                ),
              ),
            ),
            if (AppSession.isImpersonating)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _ImpersonationBanner(
                    employeeName: employee?.fullName ?? 'الموظف',
                    managerName:
                        AppSession.impersonatingManager?.fullName ?? 'المدير',
                  ),
                ),
              ),
            if (_error != null && data == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _ErrorCard(
                    message: _errorMessage(_error!),
                    onRetry: _loading ? null : _load,
                  ),
                ),
              )
            else if (data != null && data.hasWarnings)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _InfoBanner(
                    text:
                        'بعض الأقسام غير متاحة مؤقتاً (قاعدة البصمة أو الأرصدة). اسحب للتحديث.',
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.45,
                  children: [
                    _BalanceCard(
                      title: 'رصيد السنوية',
                      value: balance(
                        data?.annualBalance ?? 0,
                        available: data?.annualBalanceAvailable ?? true,
                      ),
                      unit: 'يوم',
                      icon: FontAwesomeIcons.calendarDays,
                    ),
                    _BalanceCard(
                      title: 'رصيد الطارئة',
                      value: balance(data?.emergencyBalance ?? 0),
                      unit: 'يوم',
                      icon: FontAwesomeIcons.circleExclamation,
                    ),
                    _BalanceCard(
                      title: 'رصيد الأذونات المتبقي',
                      value: balance(
                        data?.permissionBalanceRemaining ?? 0,
                        available: data?.permissionBalanceRemaining != null,
                      ),
                      unit: 'هذا الشهر',
                      icon: FontAwesomeIcons.userClock,
                    ),
                    _BalanceCard(
                      title: 'أذونات الدخول والخروج المأخوذة',
                      value: balance(
                        data?.entryExitPermissionsTakenThisMonth ?? 0,
                        available: data?.permissionsAvailable ?? true,
                      ),
                      unit: 'هذا الشهر',
                      icon: FontAwesomeIcons.rightLeft,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: FilledButton.icon(
                  onPressed: widget.onNewRequest,
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('تقديم طلب جديد'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'روابط تهمك',
                      subtitle: 'اختصارات يومية بدون تشتيت',
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.35,
                      children: [
                        _ServiceTile(
                          title: 'عرض التايم شيت',
                          icon: FontAwesomeIcons.clock,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TimesheetHubScreen(),
                              ),
                            );
                          },
                        ),
                        _ServiceTile(
                          title: 'الأصول المسجلة',
                          icon: FontAwesomeIcons.laptop,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const EmployeeAssetsScreen(),
                              ),
                            );
                          },
                        ),
                        _ServiceTile(
                          title: 'عرض قصاصاتك',
                          icon: FontAwesomeIcons.fileLines,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const EmployeeClipsScreen(),
                              ),
                            );
                          },
                        ),
                        _ServiceTile(
                          title: 'المستشفيات',
                          icon: FontAwesomeIcons.starAndCrescent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const HealthcareSpecialtiesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _FeedbackInviteCard(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'طلباتك',
                      subtitle: 'فلتر حسب الحالة بدل ثلاث جداول مزدحمة',
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<RequestStatus>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: RequestStatus.pending,
                          label: Text(
                            'معلّقة${_countLabel(RequestStatus.pending)}',
                          ),
                        ),
                        ButtonSegment(
                          value: RequestStatus.approved,
                          label: Text(
                            'مقبولة${_countLabel(RequestStatus.approved)}',
                          ),
                        ),
                        ButtonSegment(
                          value: RequestStatus.rejected,
                          label: Text(
                            'مرفوضة${_countLabel(RequestStatus.rejected)}',
                          ),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (value) =>
                          _changeFilter(value.first),
                    ),
                  ],
                ),
              ),
            ),
            if (initialLoading || (feed.loading && feed.items.isEmpty))
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.goldDeep,
                      ),
                    ),
                  ),
                ),
              )
            else if (feed.error != null && feed.items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: _ErrorCard(
                    message: _errorMessage(feed.error!),
                    onRetry: () => _loadMore(_filter),
                  ),
                ),
              )
            else if (data == null)
              const SliverToBoxAdapter(child: SizedBox(height: 32))
            else if (feed.items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: _EmptyHint(
                    title: 'لا توجد طلبات في هذا التصنيف',
                    subtitle:
                        'جرّب تصنيفاً آخر، أو قدّم طلباً جديداً من الزر أعلاه.',
                    onAction: widget.onNewRequest,
                  ),
                ),
              )
            else ...[
              if (totalForStatus > _pageSize)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'عرض ${visible.length} من $totalForStatus',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  feed.canShowMore ? 8 : 32,
                ),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _RequestTile(
                        key: ValueKey('${_filter.name}-${visible[index].id}'),
                        request: visible[index],
                      ),
                    );
                  },
                ),
              ),
              if (feed.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      _errorMessage(feed.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              if (feed.canShowMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: OutlinedButton.icon(
                      onPressed: feed.loading ? null : _showMore,
                      icon: feed.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more_rounded),
                      label: Text(
                        totalForStatus > visible.length
                            ? 'عرض المزيد (${totalForStatus - visible.length})'
                            : 'عرض المزيد',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.goldDeep,
                        side: const BorderSide(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.name,
    required this.jobTitle,
    required this.department,
  });

  final String name;
  final String jobTitle;
  final String department;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF7F1E6),
            Color(0xFFEFEFEA),
            Color(0xFFE8E8E4),
          ],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.handSparkles,
                size: 14,
                color: AppColors.goldDeep,
              ),
              SizedBox(width: 8),
              Text(
                'أهلاً بك',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$jobTitle • $department',
            style: const TextStyle(
              color: AppColors.goldDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: AppColors.goldDeep, size: 14),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// دعوة هادئة لإرسال شكوى/مقترح — ظاهرة دون إفساد إيقاع الرئيسية.
class _FeedbackInviteCard extends StatelessWidget {
  const _FeedbackInviteCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EmployeeFeedbackScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                AppColors.goldSoft.withValues(alpha: 0.55),
                AppColors.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.envelopeOpenText,
                    size: 16,
                    color: AppColors.goldDeep,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'شكوى أو مقترح',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'مساحة هادئة لملاحظاتك — اختيارية وغير ملحّة',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const FaIcon(
                  FontAwesomeIcons.chevronLeft,
                  size: 12,
                  color: AppColors.goldDeep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// روابط الخدمات — بطاقات Font Awesome أنيقة، جاهزة للنقر لاحقاً.
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final FaIconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap ??
          () {
            // سيتم ربط الصفحات لاحقاً (تايم شيت، قصاصات، مستشفيات).
          },
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, color: AppColors.goldDeep, size: 18),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.3,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.title,
    required this.subtitle,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.inbox,
            size: 30,
            color: AppColors.goldDeep,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate, height: 1.45),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: const Text('تقديم طلب جديد'),
            ),
          ],
        ],
      ),
    );
  }
}

/// خطأ تحميل مع زر إعادة المحاولة — بنفس لغة الأسطح الهادئة.
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
            'تعذّر تحميل البيانات',
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.info.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.charcoal,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({super.key, required this.request});

  final EmployeeRequest request;

  @override
  Widget build(BuildContext context) {
    final date = EmployeeRequest.formatDay(request.requestedAt);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  _kindIcon(request.kind),
                  color: AppColors.goldDeep,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (request.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        request.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: _statusLabel(request.status),
                tone: _statusTone(request.status),
              ),
            ],
          ),
          if (request.attachment != null) ...[
            const SizedBox(height: 10),
            AttachmentChip(
              attachment: request.attachment!,
              dense: true,
              viewerSubtitle:
                  '${request.displayTitle} · ${_statusLabel(request.status)}',
            ),
          ],
        ],
      ),
    );
  }

  static FaIconData _kindIcon(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => FontAwesomeIcons.hourglassHalf,
        RequestKind.earlyLeavePermission => FontAwesomeIcons.doorOpen,
        RequestKind.emergencyLeave => FontAwesomeIcons.triangleExclamation,
        RequestKind.annualLeave => FontAwesomeIcons.calendarCheck,
        RequestKind.studyLeave => FontAwesomeIcons.graduationCap,
        RequestKind.other => FontAwesomeIcons.fileLines,
      };

  static String _statusLabel(RequestStatus status) => switch (status) {
        RequestStatus.pending => 'معلّقة',
        RequestStatus.approved => 'مقبولة',
        RequestStatus.rejected => 'مرفوضة',
      };

  static StatusTone _statusTone(RequestStatus status) => switch (status) {
        RequestStatus.pending => StatusTone.warning,
        RequestStatus.approved => StatusTone.success,
        RequestStatus.rejected => StatusTone.danger,
      };
}

class _ImpersonationBanner extends StatelessWidget {
  const _ImpersonationBanner({
    required this.employeeName,
    required this.managerName,
  });

  final String employeeName;
  final String managerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.goldSoft.withValues(alpha: 0.9),
            AppColors.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.switch_account_rounded, color: AppColors.goldDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'أنت تدخل نيابة عن $employeeName — المدير: $managerName',
              style: const TextStyle(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
