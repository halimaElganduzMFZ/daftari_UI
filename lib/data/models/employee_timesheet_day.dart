enum DayType { work, weekend, holiday, unknown }

class EmployeeTimesheetDay {
  const EmployeeTimesheetDay({
    required this.id,
    required this.date,
    required this.dayType,
    required this.dayTypeLabel,
    this.checkIn,
    this.breakOut,
    this.breakIn,
    this.checkOut,
    this.delayLabel,
    this.statusLabel = 'حاضر',
  });

  final String id;
  final DateTime date;
  final DayType dayType;
  final String dayTypeLabel;
  final String? checkIn;
  final String? breakOut;
  final String? breakIn;
  final String? checkOut;
  final String? delayLabel;
  final String statusLabel;

  bool get isWorkDay => dayType == DayType.work;
}
