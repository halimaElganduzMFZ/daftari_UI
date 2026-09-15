class VehicleGateDay {
  const VehicleGateDay({
    required this.id,
    required this.date,
    required this.dayName,
    required this.carNumber,
    required this.gateInCount,
    required this.gateOutCount,
    required this.carInsideMinutes,
    required this.workDurationMinutes,
    this.exemptionLabel,
    this.isViolation = false,
    this.judgmentLabel = 'حضور مطابق',
    this.checkIn,
    this.checkOut,
  });

  final String id;
  final DateTime date;
  final String dayName;
  final String carNumber;
  final int gateInCount;
  final int gateOutCount;
  final int carInsideMinutes;
  final int workDurationMinutes;
  final String? exemptionLabel;
  final bool isViolation;
  final String judgmentLabel;
  final String? checkIn;
  final String? checkOut;

  String get carInsideLabel {
    final h = carInsideMinutes ~/ 60;
    final m = carInsideMinutes % 60;
    if (h <= 0) return '$m د';
    return '$hس ${m.toString().padLeft(2, '0')}د';
  }
}
