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

/// الصفحة الرئيسية للموظف العادي — من index.php بتوزيع أوضح وأقل ازدحاماً.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNewRequest});

  /// ينقل المستخدم لتبويب تقديم الطلب من الـ Shell.
  final VoidCallback? onNewRequest;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RequestStatus _filter = RequestStatus.pending;

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final data = StaticEmployeeDashboard.data;
    final filtered = [
      for (final r in data.requests)
        if (r.status == _filter) r,
    ];

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
              child: Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      title: 'رصيد السنوية',
                      value: '${data.annualBalance}',
                      unit: 'يوم',
                      icon: FontAwesomeIcons.calendarDays,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceCard(
                      title: 'رصيد الطارئة',
                      value: '${data.emergencyBalance}',
                      unit: 'يوم',
                      icon: FontAwesomeIcons.circleExclamation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (data.permissionBalanceRemaining != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _PermissionBalanceBar(
                  remaining: data.permissionBalanceRemaining!,
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
                      const _ServiceTile(
                        title: 'عرض التايم شيت',
                        icon: FontAwesomeIcons.clock,
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
                      const _ServiceTile(
                        title: 'عرض قصاصاتك',
                        icon: FontAwesomeIcons.fileLines,
                      ),
                      const _ServiceTile(
                        title: 'المستشفيات',
                        icon: FontAwesomeIcons.hospital,
                      ),
                    ],
                  ),
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
                    title: 'ملخص طلباتك الشهري',
                    subtitle: 'أرقام سريعة لهذا الشهر فقط',
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _SummaryStat(
                        label: 'إذن تأخير',
                        value: '${data.delayPermissionCount}',
                        icon: FontAwesomeIcons.hourglassHalf,
                      ),
                      _SummaryStat(
                        label: 'خروج مبكر',
                        value: '${data.earlyLeaveCount}',
                        icon: FontAwesomeIcons.doorOpen,
                      ),
                      _SummaryStat(
                        label: 'طارئة معلّقة',
                        value: '${data.pendingEmergencyCount}',
                        icon: FontAwesomeIcons.triangleExclamation,
                      ),
                      _SummaryStat(
                        label: 'سنوية معلّقة',
                        value: '${data.pendingAnnualCount}',
                        icon: FontAwesomeIcons.calendarCheck,
                      ),
                    ],
                  ),
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
                      setState(() => _filter = value.first);
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
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverList.separated(
                itemCount: filtered.length.clamp(0, 6),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _RequestTile(
                      key: ValueKey('${_filter.name}-$index'),
                      request: filtered[index],
                    ),
                  );
                },
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: AppColors.goldDeep, size: 18),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(color: AppColors.slate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionBalanceBar extends StatelessWidget {
  const _PermissionBalanceBar({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.userClock,
            color: AppColors.goldDeep,
            size: 16,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'رصيد الأذونات المتبقي لهذا الشهر',
              style: TextStyle(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '$remaining',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.charcoal,
            ),
          ),
        ],
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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          FaIcon(icon, color: AppColors.goldDeep, size: 14),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
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
