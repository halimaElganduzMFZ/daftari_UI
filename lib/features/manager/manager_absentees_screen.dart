import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/static/static_awol.dart';
import 'manager_awol_action_screen.dart';

/// المنقطعون عن العمل — إشعارات المدير من AWOL_employee.php.
class ManagerAbsenteesScreen extends StatefulWidget {
  const ManagerAbsenteesScreen({super.key});

  @override
  State<ManagerAbsenteesScreen> createState() => _ManagerAbsenteesScreenState();
}

class _ManagerAbsenteesScreenState extends State<ManagerAbsenteesScreen> {
  final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');

  Future<void> _openAction(AwolEmployee item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManagerAwolActionScreen(employee: item),
      ),
    );
    if (changed == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final open = StaticAwol.openAbsentees;
    final handled = StaticAwol.absentees.where((e) => e.handled).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المنقطعون عن العمل'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppSurface(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.danger.withValues(alpha: 0.18),
                        AppColors.goldSoft,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        open.isEmpty
                            ? 'لا يوجد منقطعون بانتظار إجراء'
                            : '${open.length} موظف بحاجة لإجراء',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'اضغط على الموظف لتأكيد الإجراء وإرسال الملاحظة — كما في updateState.php',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (open.isEmpty)
            const AppSurface(
              child: Column(
                children: [
                  Icon(Icons.verified_outlined, size: 36, color: AppColors.success),
                  SizedBox(height: 10),
                  Text(
                    'تم التعامل مع كل حالات الانقطاع الحالية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'بانتظار إجراءك',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in open)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AwolCard(
                  item: item,
                  dateFormat: _dateFormat,
                  onTap: () => _openAction(item),
                ),
              ),
          ],
          if (handled.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'تم اتخاذ إجراء',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in handled)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AwolCard(
                  item: item,
                  dateFormat: _dateFormat,
                  muted: true,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AwolCard extends StatelessWidget {
  const _AwolCard({
    required this.item,
    required this.dateFormat,
    this.onTap,
    this.muted = false,
  });

  final AwolEmployee item;
  final DateFormat dateFormat;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: muted ? AppColors.slate : AppColors.charcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (muted ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  muted ? 'تم' : '${item.suspendedDays} يوم',
                  style: TextStyle(
                    color: muted ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.employeeNumber,
            style: const TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            item.department,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أول يوم انقطاع: ${dateFormat.format(item.firstAbsentDate)}',
            style: const TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          if (item.note != null) ...[
            const SizedBox(height: 8),
            Text(
              item.note!,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (item.managerNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'ملاحظة المدير: ${item.managerNote}',
              style: const TextStyle(
                color: AppColors.goldDeep,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AppColors.goldDeep.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                const Text(
                  'اتخاذ إجراء',
                  style: TextStyle(
                    color: AppColors.goldDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
