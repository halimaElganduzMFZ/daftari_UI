import '../models/employee.dart';

/// جلسة واجهة بسيطة — تُستبدل لاحقاً بمخزن آمن/توكن API.
abstract final class AppSession {
  static Employee? currentEmployee;
}
