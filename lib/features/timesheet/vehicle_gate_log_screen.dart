import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/models/vehicle_gate_day.dart';
import '../../data/static/static_vehicle_gate.dart';

/// سجل حركة السيارة في بوابة المنطقة الحرة.
class VehicleGateLogScreen extends StatefulWidget {
  const VehicleGateLogScreen({super.key});

  @override
  State<VehicleGateLogScreen> createState() => _VehicleGateLogScreenState();
}

class _VehicleGateLogScreenState extends State<VehicleGateLogScreen> {
  static const _pageSize = 8;
  int _visible = _pageSize;

  @override
  Widget build(BuildContext context) {
    final days = StaticVehicleGateLog.days;
    final visible = days.take(_visible).toList();
    final hasMore = _visible < days.length;
    final violations = days.where((d) => d.isViolation).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('سجل البوابة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Container(
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
                const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.carSide,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'بوابة المركبات',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
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
                    _ChipStat(label: 'أيام', value: '${days.length}'),
                    const SizedBox(width: 10),
                    _ChipStat(label: 'مخالفات', value: '$violations'),
                    const SizedBox(width: 10),
                    _ChipStat(label: 'المعروض', value: '${visible.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'عرض ${visible.length} من ${days.length}',
            style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          for (final day in visible) ...[
            _GateCard(day: day),
            const SizedBox(height: 10),
          ],
          if (hasMore)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _visible = (_visible + _pageSize).clamp(0, days.length);
              }),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('عرض المزيد (${days.length - visible.length})'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.goldDeep,
                side: const BorderSide(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.day});

  final VehicleGateDay day;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy/MM/dd', 'ar');
    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: day.isViolation
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  FontAwesomeIcons.car,
                  size: 16,
                  color: day.isViolation ? AppColors.danger : AppColors.goldDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dateFmt.format(day.date)} · ${day.dayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'لوحة ${day.carNumber}',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: day.judgmentLabel,
                tone: day.isViolation
                    ? StatusTone.danger
                    : (day.exemptionLabel != null
                        ? StatusTone.warning
                        : StatusTone.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                _Meta(label: 'دخول بوابة', value: '${day.gateInCount}'),
                _Meta(label: 'خروج بوابة', value: '${day.gateOutCount}'),
                _Meta(label: 'داخل المنطقة', value: day.carInsideLabel),
                _Meta(label: 'حضور', value: day.checkIn ?? '—'),
                _Meta(label: 'انصراف', value: day.checkOut ?? '—'),
                if (day.exemptionLabel != null)
                  _Meta(label: 'استثناء', value: day.exemptionLabel!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
