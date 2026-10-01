import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../utils/large_text.dart';

/// شريط اختيار فترة «من / إلى» مشترك بين التايم شيت وطلباتي.
class DateRangeFilterBar extends StatelessWidget {
  const DateRangeFilterBar({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    this.onCleared,
    this.hint = 'حدّد الفترة لتصفية السجلات',
  });

  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;
  final VoidCallback? onCleared;
  final String hint;

  static final _fmt = DateFormat('yyyy/MM/dd');

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool inRange(DateTime date, DateTime? from, DateTime? to) {
    final d = dateOnly(date);
    if (from != null && d.isBefore(dateOnly(from))) return false;
    if (to != null && d.isAfter(dateOnly(to))) return false;
    return true;
  }

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final initial = isFrom
        ? (from ?? to ?? DateTime.now())
        : (to ?? from ?? DateTime.now());
    final first = DateTime(2023);
    final last = DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'من تاريخ' : 'إلى تاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تم',
    );
    if (picked == null) return;
    if (isFrom) {
      onFromChanged(dateOnly(picked));
    } else {
      onToChanged(dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromField = _DateField(
      label: 'من تاريخ',
      value: from == null ? null : _fmt.format(from!),
      onTap: () => _pick(context, isFrom: true),
    );
    final toField = _DateField(
      label: 'إلى تاريخ',
      value: to == null ? null : _fmt.format(to!),
      onTap: () => _pick(context, isFrom: false),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الفترة',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const Spacer(),
            if (onCleared != null && (from != null || to != null))
              TextButton(onPressed: onCleared, child: const Text('مسح')),
          ],
        ),
        const SizedBox(height: 4),
        Text(hint, style: TextStyle(color: AppColors.slate, fontSize: 12.5)),
        const SizedBox(height: 10),
        // مع الخط الكبير لا يتسع نصف العرض للتاريخ فينكسر وسطه،
        // فيأخذ كل حقل سطراً كاملاً.
        if (isLargeText(context))
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fromField, const SizedBox(height: 10), toField],
          )
        else
          Row(
            children: [
              Expanded(child: fromField),
              const SizedBox(width: 10),
              Expanded(child: toField),
            ],
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: AppColors.slate,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? 'اختر',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: value == null
                            ? AppColors.slate
                            : AppColors.charcoal,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppColors.goldDeep,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
