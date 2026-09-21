import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/permission_request.dart';
import '../static/static_permission_types.dart';

/// تقديم طلب إذن (بديل `makeRequest.php`).
///
/// - `options(date)` → `GET  /me/requests/options?date=`
///   الأنواع المسموحة حسب الدوام، البصمات، قفل الشهر، الرصيد الشهري.
/// - `submit()`      → `POST /me/requests { type, date }`
///   الرفض يأتي مع `code` ثابت ورسالة عربية من الـ API.
abstract class PermissionRequestsRepository {
  Future<PermissionRequestOptions> options({DateTime? date});

  Future<PermissionRequestResult> submit({
    required int type,
    required DateTime date,
  });
}

final _isoDate = DateFormat('yyyy-MM-dd');

String isoDate(DateTime d) => _isoDate.format(d);

class ApiPermissionRequestsRepository implements PermissionRequestsRepository {
  const ApiPermissionRequestsRepository(this._client);

  final ApiClient _client;

  @override
  Future<PermissionRequestOptions> options({DateTime? date}) async {
    final json = await _client.getJson(
      '/me/requests/options',
      query: {if (date != null) 'date': isoDate(date)},
    );
    return PermissionRequestOptions.fromApi(json);
  }

  @override
  Future<PermissionRequestResult> submit({
    required int type,
    required DateTime date,
  }) async {
    final json = await _client.postJson(
      '/me/requests',
      body: {'type': type, 'date': isoDate(date)},
      auth: true,
    );
    return PermissionRequestResult.fromApi(json);
  }
}

/// نسخة تجريبية: كل الأنواع الثابتة مسموحة، دوام إداري 08–14، رصيد 3.
class StaticPermissionRequestsRepository implements PermissionRequestsRepository {
  StaticPermissionRequestsRepository();

  final _submitted = <String>{};

  @override
  Future<PermissionRequestOptions> options({DateTime? date}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    final day = date ?? now;
    final key = isoDate(day);
    final allowed = [
      for (final t in StaticPermissionTypes.all)
        ApiPermissionType(type: int.parse(t.id), code: t.id, name: t.title),
    ];
    return PermissionRequestOptions(
      date: key,
      today: isoDate(now),
      minDate: isoDate(DateTime(now.year, now.month - 1, now.day)),
      maxDate: isoDate(DateTime(now.year, now.month + 1, now.day)),
      schedule: const RequestSchedule(
        status: ScheduleStatus.ok,
        profile: 'SHORT',
        source: 'date',
        scheduleId: 67,
        scheduleName: 'دوام صباحي',
        checkIn: '08:00:00',
        checkOut: '14:00:00',
        shiftHours: 6,
        dayType: 'W',
      ),
      punches: day.isAfter(now)
          ? null
          : const DayPunches(checkIn: '08:12:40', checkOut: '14:03:11'),
      monthLocked: false,
      quota: const RequestQuota(limit: 3, used: 1, pending: 0, remaining: 2),
      allowedTypes: allowed,
      requestedTypes: [
        for (final t in allowed)
          if (_submitted.contains('$key:${t.type}'))
            RequestedPermissionType(
              type: t.type,
              code: t.code,
              name: t.name,
              registered: false,
            ),
      ],
      canSubmit: true,
    );
  }

  @override
  Future<PermissionRequestResult> submit({
    required int type,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final key = '${isoDate(date)}:$type';
    if (_submitted.contains(key)) {
      throw const ApiException(
        statusCode: 409,
        code: 'DUPLICATE_REQUEST',
        message: 'لا يمكن تقديم الطلب مرة أخرى لأنه يوجد طلب مشابه',
      );
    }
    _submitted.add(key);
    final match = StaticPermissionTypes.all.where((t) => t.id == '$type');
    final name = match.isEmpty ? 'إذن' : match.first.title;
    return PermissionRequestResult(
      id: 90000 + _submitted.length,
      type: ApiPermissionType(type: type, code: '$type', name: name),
      date: isoDate(date),
      state: 'تم الإرسال',
      submittedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      message: 'تم تقديم طلبك بنجاح',
    );
  }
}
