import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/session/app_session.dart';

enum _MessageKind { complaint, suggestion }

/// إرسال شكوى أو مقترح من الموظف (بديل sendMessage.php).
class EmployeeFeedbackScreen extends StatefulWidget {
  const EmployeeFeedbackScreen({super.key});

  @override
  State<EmployeeFeedbackScreen> createState() => _EmployeeFeedbackScreenState();
}

class _EmployeeFeedbackScreenState extends State<EmployeeFeedbackScreen> {
  final _controller = TextEditingController();
  _MessageKind _kind = _MessageKind.suggestion;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب نص الرسالة أولاً')),
      );
      return;
    }
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _sending = false);
    _controller.clear();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم الإرسال'),
        content: const Text(
          'وصلت رسالتك بنجاح. شكراً لمشاركتك — سيتم مراجعتها من الجهة المختصة.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = AppSession.currentEmployee;
    final name = employee?.fullName ?? 'موظف';
    final number = employee?.employeeNumber ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('شكوى أو مقترح')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
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
          ),
          const SizedBox(height: 16),
          AppSurface(
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
              ],
            ),
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
            maxLength: 1500,
            textAlign: TextAlign.right,
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
