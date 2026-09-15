import '../models/vehicle_gate_day.dart';

const _dayNames = {
  DateTime.monday: 'الإثنين',
  DateTime.tuesday: 'الثلاثاء',
  DateTime.wednesday: 'الأربعاء',
  DateTime.thursday: 'الخميس',
  DateTime.friday: 'الجمعة',
  DateTime.saturday: 'السبت',
  DateTime.sunday: 'الأحد',
};

/// سجل حركة السيارة في البوابة — بيانات تجريبية للموظف.
abstract final class StaticVehicleGateLog {
  static final List<VehicleGateDay> days = _build();

  static List<VehicleGateDay> _build() {
    final list = <VehicleGateDay>[];
    final start = DateTime(2026, 9, 14);
    for (var i = 0; i < 36; i++) {
      final date = start.subtract(Duration(days: i));
      if (date.weekday == DateTime.friday || date.weekday == DateTime.saturday) {
        continue;
      }
      final violation = i % 9 == 3;
      final exempt = i % 12 == 1;
      list.add(
        VehicleGateDay(
          id: 'g$i',
          date: date,
          dayName: _dayNames[date.weekday] ?? '',
          carNumber: '5-${2400 + (i % 17)}',
          gateInCount: 1 + (i % 3),
          gateOutCount: 1 + ((i + 1) % 3),
          carInsideMinutes: 420 + (i % 5) * 18,
          workDurationMinutes: 450 + (i % 4) * 10,
          exemptionLabel: exempt ? 'إذن خروج' : null,
          isViolation: violation,
          judgmentLabel: violation
              ? 'مخالفة بوابة'
              : (exempt ? 'مجاز بإذن' : 'حضور مطابق'),
          checkIn: '07:4${i % 8}',
          checkOut: '15:2${i % 7}',
        ),
      );
    }
    return List.unmodifiable(list);
  }
}
