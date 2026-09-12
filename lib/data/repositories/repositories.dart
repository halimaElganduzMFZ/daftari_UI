import '../models/attendance_record.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import '../static/static_attendance.dart';
import '../static/static_employees.dart';
import '../static/static_leaves.dart';

/// واجهة المستودع — لاحقاً تُستبدل بتنفيذ API دون لمس الواجهات.
abstract class EmployeeRepository {
  List<Employee> getEmployees();
  Employee? getById(String id);
  List<Employee> search(String query);
}

abstract class LeaveRepository {
  List<LeaveRequest> getLeaves();
  List<LeaveRequest> getPending();
}

abstract class AttendanceRepository {
  List<AttendanceRecord> getToday();
}

class StaticEmployeeRepository implements EmployeeRepository {
  const StaticEmployeeRepository();

  @override
  List<Employee> getEmployees() => StaticEmployees.all;

  @override
  Employee? getById(String id) {
    for (final e in StaticEmployees.all) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  List<Employee> search(String query) {
    if (query.trim().isEmpty) return StaticEmployees.all;
    return [
      for (final e in StaticEmployees.all)
        if (e.matchesQuery(query)) e,
    ];
  }
}

class StaticLeaveRepository implements LeaveRepository {
  const StaticLeaveRepository();

  @override
  List<LeaveRequest> getLeaves() => StaticLeaves.all;

  @override
  List<LeaveRequest> getPending() => [
        for (final leave in StaticLeaves.all)
          if (leave.status == LeaveStatus.pending) leave,
      ];
}

class StaticAttendanceRepository implements AttendanceRepository {
  const StaticAttendanceRepository();

  @override
  List<AttendanceRecord> getToday() => StaticAttendance.todayRecords;
}
