import '../models/attendance_record.dart';

abstract final class StaticAttendance {
  static final DateTime today = DateTime(2026, 9, 12);

  static final List<AttendanceRecord> todayRecords =
      List<AttendanceRecord>.unmodifiable([
    AttendanceRecord(
      id: 'a1',
      employeeId: 'e1',
      employeeName: 'أحمد محمد العلي',
      date: today,
      state: AttendanceState.present,
      checkIn: '07:52',
      checkOut: null,
    ),
    AttendanceRecord(
      id: 'a2',
      employeeId: 'e2',
      employeeName: 'سارة خالد المنصور',
      date: today,
      state: AttendanceState.late,
      checkIn: '08:21',
      checkOut: null,
    ),
    AttendanceRecord(
      id: 'a3',
      employeeId: 'e3',
      employeeName: 'يوسف إبراهيم الحربي',
      date: today,
      state: AttendanceState.absent,
    ),
    AttendanceRecord(
      id: 'a4',
      employeeId: 'e4',
      employeeName: 'نورة فهد الشمري',
      date: today,
      state: AttendanceState.present,
      checkIn: '07:48',
      checkOut: null,
    ),
    AttendanceRecord(
      id: 'a5',
      employeeId: 'e5',
      employeeName: 'ماجد عبدالعزيز القحطاني',
      date: today,
      state: AttendanceState.remote,
      checkIn: '08:05',
      checkOut: null,
    ),
  ]);
}
