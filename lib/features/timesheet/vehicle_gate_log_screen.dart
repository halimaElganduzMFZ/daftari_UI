import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/timesheet.dart';
import '../../data/repositories/timesheet_repository.dart';
import 'timesheet_log_scaffold.dart';

/// سجل حركة السيارة في بوابة المنطقة (بديل `Vehicle_Employee_Log.php`) — `GET /me/timesheet`.
///
/// يعرض لكل يوم: مرات الدخول/الخروج، مدة البقاء، وقت الخروج بلا إذن، هامش السماحية،
/// وشارة «الحالة» بعد تطبيق فترة السماح — كلها محسوبة في الخادم.
class VehicleGateLogScreen extends StatelessWidget {
  const VehicleGateLogScreen({super.key, this.repository});

  /// للاختبارات؛ الافتراضي `AppServices.timesheet`.
  final TimesheetRepository? repository;

  @override
  Widget build(BuildContext context) {
    return TimesheetLogScaffold(
      title: 'سجل البوابة',
      filterHint: 'تصفية سجل البوابة حسب الفترة',
      emptyText: 'لا توجد حركات مؤرشفة ضمن الفترة المحددة',
      unavailableText: 'سجل البوابة غير متاح',
      repository: repository,
      headerBuilder: (context, result, shown) =>
          _Header(result: result, shown: shown),
      dayBuilder: (context, day, result) => _GateCard(day: day),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.result, required this.shown});

  final TimesheetResult? result;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final s = result?.summary;
    final carNumber = result?.days.reversed
        .map((d) => d.car.number)
        .firstWhere((n) => n != null, orElse: () => null);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF6B5538), Color(0xFF3A3228)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.carSide,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'بوابة المركبات',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (carNumber != null)
                Text(
                  'لوحة $carNumber',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'حركة سيارتك داخل المنطقة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TimesheetMiniStat(
                label: 'أيام',
                value: result == null ? '—' : '${result!.days.length}',
              ),
              const SizedBox(width: 10),
              TimesheetMiniStat(
                label: 'مخالفات',
                value: s == null ? '—' : '${s.carViolations}',
              ),
              const SizedBox(width: 10),
              TimesheetMiniStat(
                label: 'خروج بلا إذن',
                value: s?.totalLeak ?? '—',
              ),
              const SizedBox(width: 10),
              TimesheetMiniStat(label: 'المعروض', value: '$shown'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.day});

  final TimesheetDay day;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy/MM/dd · EEEE', 'ar');
    final car = day.car;
    final judgment = car.judgment;
    final violation = car.countsAsViolation ||
        judgment.badge.tone == BadgeTone.red ||
        judgment.badge.tone == BadgeTone.orange;
    final iconColor = violation
        ? AppColors.danger
        : judgment.badge.tone == BadgeTone.green
            ? AppColors.success
            : AppColors.goldDeep;

    return TimesheetDayCard(
      accent: rowAccentOf(day.tone),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: violation
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: FaIcon(FontAwesomeIcons.car, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFmt.format(day.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        ?day.dayTypeName,
                        if (car.number case final n?) 'لوحة $n',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: judgment.badge.text,
                tone: statusToneOf(judgment.badge.tone),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!car.hasData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                day.isRest
                    ? 'يوم راحة — لا حركة مسجلة'
                    : 'لا توجد حركة سيارة مسجلة لهذا اليوم',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  TimesheetMeta(
                    label: 'دخول بوابة',
                    value: '${car.gateInCount ?? 0}',
                  ),
                  TimesheetMeta(
                    label: 'خروج بوابة',
                    value: '${car.gateOutCount ?? 0}',
                  ),
                  TimesheetMeta(label: 'داخل المنطقة', value: car.insideLabel),
                  TimesheetMeta(
                    label: 'فترة الانقطاع',
                    value: car.leak,
                    valueColor:
                        car.leakMinutes > 0 ? AppColors.danger : null,
                  ),
                  TimesheetMeta(
                    label: 'حضور',
                    value: day.punches.checkIn ?? '—',
                  ),
                  TimesheetMeta(
                    label: 'انصراف',
                    value: day.punches.checkOut ?? '—',
                  ),
                  TimesheetMeta(
                    label: 'هامش / إذن السماحية',
                    value: car.permissionMargin,
                    width: 208,
                    valueColor: car.exemption?.isReal == true
                        ? AppColors.success
                        : null,
                  ),
                ],
              ),
            ),
          if (car.displayText case final text?) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.charcoal,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          if (car.isViolation && car.inGracePeriod) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 12,
                  color: AppColors.slate,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'هذا اليوم ضمن فترة السماح قبل بدء احتساب المخالفات، فلا يُحتسب.',
                    style: TextStyle(color: AppColors.slate, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
