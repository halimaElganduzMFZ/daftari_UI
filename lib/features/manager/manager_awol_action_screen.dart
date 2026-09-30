import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/static/static_awol.dart';

/// اتخاذ إجراء على موظف منقطع — مقابل updateState.php.
class ManagerAwolActionScreen extends StatefulWidget {
  const ManagerAwolActionScreen({super.key, required this.employee});

  final AwolEmployee employee;

  @override
  State<ManagerAwolActionScreen> createState() =>
      _ManagerAwolActionScreenState();
}

class _ManagerAwolActionScreenState extends State<ManagerAwolActionScreen> {
  final _noteController = TextEditingController();
  final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب ملاحظة الإجراء قبل التأكيد')),
      );
      return;
    }

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    StaticAwol.markHandled(widget.employee.id, managerNote: note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل الإجراء على ${widget.employee.fullName}'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إجراء على منقطع'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          AppSurface(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFFF6EFE4),
                        AppColors.surface,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                        child: Text(
                          e.fullName.characters.first,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.employeeNumber,
                              style: const TextStyle(
                                color: AppColors.goldDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    children: [
                      _MetaRow(label: 'القسم', value: e.department),
                      _MetaRow(
                        label: 'أول يوم انقطاع',
                        value: _dateFormat.format(e.firstAbsentDate),
                      ),
                      _MetaRow(
                        label: 'أيام الانقطاع',
                        value: '${e.suspendedDays} يوم',
                        emphasize: true,
                      ),
                      if (e.note != null)
                        _MetaRow(label: 'ملاحظة النظام', value: e.note!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ملاحظة المدير',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تُحفظ مع تأكيد الإجراء وتظهر لشؤون الموظفين لاحقاً.',
            style: TextStyle(color: AppColors.slate, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 5,
            maxLength: 500,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظة الإجراء...',
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _confirm,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt_rounded),
            label: Text(_saving ? 'جاري الحفظ...' : 'تأكيد وإرسال'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: emphasize ? AppColors.danger : AppColors.charcoal,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
