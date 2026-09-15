import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/attachment_viewer.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/employee_dashboard.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_employee_dashboard.dart';
import '../assets/employee_assets_screen.dart';
import '../clips/employee_clips_screen.dart';
import '../feedback/employee_feedback_screen.dart';
import '../healthcare/healthcare_specialties_screen.dart';
import '../timesheet/timesheet_hub_screen.dart';

/// الصفحة الرئيسية للموظف العادي — من index.php بتوزيع أوضح وأقل ازدحاماً.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNewRequest});

  /// ينقل المستخدم لتبويب تقديم الطلب من الـ Shell.
  final VoidCallback? onNewRequest;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 6;

  RequestStatus _filter = RequestStatus.pending;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final data = StaticEmployeeDashboard.data;
    final filtered = [
      for (final r in data.requests)
        if (r.status == _filter) r,
    ];
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: _WelcomeHeader(
                name: employee?.fullName ?? 'الموظف',
                jobTitle: employee?.jobTitle ?? 'موظف',
                department: employee?.department ?? '—',
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
                    value: '${data.annualBalance}',
                    unit: 'يوم',
                    icon: FontAwesomeIcons.calendarDays,
                  ),
                  _BalanceCard(
                    title: 'رصيد الطارئة',
                    value: '${data.emergencyBalance}',
                    unit: 'يوم',
                    icon: FontAwesomeIcons.circleExclamation,
                  ),
                  _BalanceCard(
                    title: 'رصيد الأذونات المتبقي',
                    value: '${data.permissionBalanceRemaining ?? 0}',
                    unit: 'هذا الشهر',
                    icon: FontAwesomeIcons.userClock,
                  ),
                  _BalanceCard(
                    title: 'أذونات الدخول والخروج المأخوذة',
                    value: '${data.entryExitPermissionsTakenThisMonth}',
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
                    segments: const [
                      ButtonSegment(
                        value: RequestStatus.pending,
                        label: Text('معلّقة'),
                      ),
                      ButtonSegment(
                        value: RequestStatus.approved,
                        label: Text('مقبولة'),
                      ),
                      ButtonSegment(
                        value: RequestStatus.rejected,
                        label: Text('مرفوضة'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) {
                      setState(() {
                        _filter = value.first;
                        _visibleCount = _pageSize;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
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
            if (filtered.length > _pageSize)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'عرض ${visible.length} من ${filtered.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, hasMore ? 8 : 32),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _RequestTile(
                      key: ValueKey('${_filter.name}-$index'),
                      request: visible[index],
                    ),
                  );
                },
              ),
            ),
            if (hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _visibleCount =
                          (_visibleCount + _pageSize).clamp(0, filtered.length);
                    }),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(
                      'عرض المزيد (${filtered.length - visible.length})',
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                  height: 1,
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

class _RequestTile extends StatelessWidget {
  const _RequestTile({super.key, required this.request});

  final EmployeeRequest request;

  @override
  Widget build(BuildContext context) {
    final date =
        '${request.requestedAt.year}/${request.requestedAt.month.toString().padLeft(2, '0')}/${request.requestedAt.day.toString().padLeft(2, '0')}';

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
                      _kindLabel(request.kind),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
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
                  '${_kindLabel(request.kind)} · ${_statusLabel(request.status)}',
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

  static String _kindLabel(RequestKind kind) => switch (kind) {
        RequestKind.delayPermission => 'إذن تأخير',
        RequestKind.earlyLeavePermission => 'إذن خروج مبكر',
        RequestKind.emergencyLeave => 'إجازة طارئة',
        RequestKind.annualLeave => 'إجازة سنوية',
        RequestKind.studyLeave => 'إجازة دراسية',
        RequestKind.other => 'طلب آخر',
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
