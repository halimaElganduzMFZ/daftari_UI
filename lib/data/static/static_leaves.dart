import '../models/leave_request.dart';

abstract final class StaticLeaves {
  static final List<LeaveRequest> all = List<LeaveRequest>.unmodifiable([
    LeaveRequest(
      id: 'l1',
      employeeId: 'e3',
      employeeName: 'يوسف إبراهيم الحربي',
      type: LeaveType.annual,
      status: LeaveStatus.approved,
      startDate: DateTime(2026, 9, 8),
      endDate: DateTime(2026, 9, 15),
      reason: 'إجازة سنوية مخطط لها مسبقاً',
    ),
    LeaveRequest(
      id: 'l2',
      employeeId: 'e2',
      employeeName: 'سارة خالد المنصور',
      type: LeaveType.sick,
      status: LeaveStatus.pending,
      startDate: DateTime(2026, 9, 12),
      endDate: DateTime(2026, 9, 13),
      reason: 'مراجعة طبية عاجلة',
    ),
    LeaveRequest(
      id: 'l3',
      employeeId: 'e4',
      employeeName: 'نورة فهد الشمري',
      type: LeaveType.emergency,
      status: LeaveStatus.pending,
      startDate: DateTime(2026, 9, 14),
      endDate: DateTime(2026, 9, 14),
      reason: 'ظرف عائلي طارئ',
    ),
    LeaveRequest(
      id: 'l4',
      employeeId: 'e1',
      employeeName: 'أحمد محمد العلي',
      type: LeaveType.unpaid,
      status: LeaveStatus.rejected,
      startDate: DateTime(2026, 8, 20),
      endDate: DateTime(2026, 8, 22),
      reason: 'طلب غير مكتمل المستندات',
    ),
  ]);
}
