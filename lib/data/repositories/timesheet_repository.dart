import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../models/timesheet.dart';
import '../static/static_timesheet.dart';

/// سجل الحضور + حركة البوابة لكل يوم — `GET /me/timesheet`
/// (بديل `time_sheet_employee.php` و`Vehicle_Employee_Log.php`).
///
/// الخادم يرجع كل الأيام في الفترة دفعة واحدة (حتى 366 يوماً)، لذا لا توجد
/// صفحات؛ الشاشات تتصفح محلياً بـ «عرض المزيد».
abstract class TimesheetRepository {
  /// [from]/[to] بالتاريخ فقط؛ عند إغفالهما يطبّق الخادم افتراضاته
  /// (أول الشهر الحالي → اليوم) ويقصّ «من» إلى `minDate` إن كان أقدم.
  Future<TimesheetResult> load({DateTime? from, DateTime? to});
}

class ApiTimesheetRepository implements TimesheetRepository {
  const ApiTimesheetRepository(this._client);

  final ApiClient _client;

  static final _iso = DateFormat('yyyy-MM-dd');

  @override
  Future<TimesheetResult> load({DateTime? from, DateTime? to}) async {
    final json = await _client.getJson(
      '/me/timesheet',
      query: {
        if (from != null) 'from': _iso.format(from),
        if (to != null) 'to': _iso.format(to),
      },
    );
    return TimesheetResult.fromApi(json);
  }
}

class StaticTimesheetRepository implements TimesheetRepository {
  const StaticTimesheetRepository({
    this.latency = const Duration(milliseconds: 400),
  });

  final Duration latency;

  @override
  Future<TimesheetResult> load({DateTime? from, DateTime? to}) async {
    await Future<void>.delayed(latency);
    return StaticTimesheet.build(from: from, to: to);
  }
}
