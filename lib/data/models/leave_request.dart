enum LeaveType { annual, sick, emergency, unpaid }

enum LeaveStatus { pending, approved, rejected }

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final LeaveType type;
  final LeaveStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  int get dayCount => endDate.difference(startDate).inDays + 1;
}
