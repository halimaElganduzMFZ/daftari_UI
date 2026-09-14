import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/static/static_manager_approvals.dart';

/// مقابلة Manager_App/index.php — طلبات الموظفين بانتظار موافقة المدير.
class ManagerApprovalsScreen extends StatefulWidget {
  const ManagerApprovalsScreen({super.key, required this.structureName});

  final String structureName;

  @override
  State<ManagerApprovalsScreen> createState() => _ManagerApprovalsScreenState();
}

class _ManagerApprovalsScreenState extends State<ManagerApprovalsScreen> {
  late final List<PendingManagerRequest> _requests;
  final _dateFormat = DateFormat('yyyy/MM/dd — HH:mm', 'ar');

  @override
  void initState() {
    super.initState();
    _requests = List<PendingManagerRequest>.from(
      StaticManagerApprovals.pending,
    );
  }

  Future<void> _approve(PendingManagerRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text(
          'هل توافق على طلب ${request.employeeName}؟\n${request.typeLabel}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.approve),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      request.decision = ManagerDecision.approved;
      request.statusLabel = 'تمت موافقة المدير المباشر';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت الموافقة على طلب ${request.employeeName}')),
    );
  }

  Future<void> _reject(PendingManagerRequest request) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.rejectReasonTitle),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: AppStrings.rejectReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, text);
            },
            child: const Text(AppStrings.reject),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    setState(() {
      request.decision = ManagerDecision.rejected;
      request.rejectReason = reason;
      request.statusLabel = 'تم الرفض من المدير المباشر';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم رفض طلب ${request.employeeName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests.where((r) => r.isPending).toList();
    final decided = _requests.where((r) => !r.isPending).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            widget.structureName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.managerApprovalsTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          AppSurface(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCell(
                    label: 'بانتظارك',
                    value: '${pending.length}',
                    color: AppColors.warning,
                  ),
                ),
                Container(width: 1, height: 44, color: AppColors.line),
                Expanded(
                  child: _SummaryCell(
                    label: 'موافقة الشهر',
                    value: '${StaticManagerApprovals.approvedThisMonth}',
                    color: AppColors.success,
                  ),
                ),
                Container(width: 1, height: 44, color: AppColors.line),
                Expanded(
                  child: _SummaryCell(
                    label: 'رفض الشهر',
                    value: '${StaticManagerApprovals.rejectedThisMonth}',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'الطلبات قيد الانتظار',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            AppSurface(
              child: Text(
                'لا توجد طلبات بانتظار الإجراء',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
            )
          else
            ...pending.map(_buildRequestCard),
          if (decided.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'إجراءات هذه الجلسة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            ...decided.map(_buildRequestCard),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(PendingManagerRequest request) {
    final kindLabel =
        request.kind == ManagerRequestKind.leave ? 'إجازة' : 'إذن';
    final isPending = request.isPending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.employeeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kindLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              request.employeeNumber,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              request.typeLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.statusLabel,
              style: TextStyle(
                color: request.decision == ManagerDecision.approved
                    ? AppColors.success
                    : request.decision == ManagerDecision.rejected
                        ? AppColors.danger
                        : AppColors.slate,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dateFormat.format(request.submittedAt),
              style: const TextStyle(color: AppColors.slate, fontSize: 12),
            ),
            if (request.notes != null) ...[
              const SizedBox(height: 6),
              Text(
                request.notes!,
                style: const TextStyle(color: AppColors.slate, fontSize: 13),
              ),
            ],
            if (request.rejectReason != null) ...[
              const SizedBox(height: 6),
              Text(
                'سبب الرفض: ${request.rejectReason}',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _approve(request),
                      child: const Text(AppStrings.approve),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text(AppStrings.reject),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slate,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
