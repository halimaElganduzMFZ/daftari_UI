enum AttendanceState { present, late, absent, remote }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.state,
    this.checkIn,
    this.checkOut,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final AttendanceState state;
  final String? checkIn;
  final String? checkOut;
}
