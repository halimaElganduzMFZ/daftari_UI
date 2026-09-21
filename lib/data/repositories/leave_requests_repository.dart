import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/leave_request_form.dart';
import '../static/static_employee_dashboard.dart';

/// مرفق يُرسل مع طلب الإجازة الدراسية.
class LeaveAttachmentUpload {
  const LeaveAttachmentUpload({
    required this.fileName,
    required this.bytes,
    this.contentType,
  });

  final String fileName;
  final Uint8List bytes;
  final String? contentType;
}

/// تقديم طلب إجازة (بديل `Taking_a_day_off.php`).
///
/// - `options(date)` → `GET  /me/leave/requests/options?date=`
/// - `preview()`     → `GET  /me/leave/requests/preview?kind&from&to`
/// - `submit()`      → `POST /me/leave/requests` (JSON أو multipart مع `attachment`)
abstract class LeaveRequestsRepository {
  /// الحد الأقصى لسبب الإجازة (textarea القديم `maxlength=1500`).
  static const reasonMaxLength = 1500;

  /// الحد الأقصى لحجم المرفق (5 م.ب).
  static const attachmentMaxBytes = 5 * 1024 * 1024;

  Future<LeaveRequestOptions> options({DateTime? date});

  Future<LeavePlan> preview({
    required String kind,
    required DateTime from,
    DateTime? to,
  });

  Future<LeaveRequestResult> submit({
    required String kind,
    required DateTime from,
    DateTime? to,
    String? reason,
    LeaveLocation? location,
    LeaveAttachmentUpload? attachment,
  });
}

final _isoDate = DateFormat('yyyy-MM-dd');
String _iso(DateTime d) => _isoDate.format(d);

class ApiLeaveRequestsRepository implements LeaveRequestsRepository {
  const ApiLeaveRequestsRepository(this._client);

  final ApiClient _client;

  @override
  Future<LeaveRequestOptions> options({DateTime? date}) async {
    final json = await _client.getJson(
      '/me/leave/requests/options',
      query: {if (date != null) 'date': _iso(date)},
    );
    return LeaveRequestOptions.fromApi(json);
  }

  @override
  Future<LeavePlan> preview({
    required String kind,
    required DateTime from,
    DateTime? to,
  }) async {
    final json = await _client.getJson(
      '/me/leave/requests/preview',
      query: {
        'kind': kind,
        'from': _iso(from),
        if (to != null) 'to': _iso(to),
      },
    );
    return LeavePlan.fromApi(json);
  }

  @override
  Future<LeaveRequestResult> submit({
    required String kind,
    required DateTime from,
    DateTime? to,
    String? reason,
    LeaveLocation? location,
    LeaveAttachmentUpload? attachment,
  }) async {
    final trimmedReason = reason?.trim();
    final fields = <String, String>{
      'kind': kind,
      'from': _iso(from),
      if (to != null) 'to': _iso(to),
      if (trimmedReason != null && trimmedReason.isNotEmpty)
        'reason': trimmedReason,
      if (location != null) 'location': location.code,
    };

    final Map<String, dynamic> json;
    if (attachment != null) {
      json = await _client.postMultipart(
        '/me/leave/requests',
        fields: fields,
        file: MultipartFile(
          field: 'attachment',
          fileName: attachment.fileName,
          bytes: attachment.bytes,
          contentType: attachment.contentType,
        ),
      );
    } else {
      json = await _client.postJson(
        '/me/leave/requests',
        body: fields,
        auth: true,
      );
    }
    return LeaveRequestResult.fromApi(json);
  }
}

/// نسخة تجريبية تحاكي قواعد الـ API الأساسية (أيام تقويمية، رصيد ثابت).
class StaticLeaveRequestsRepository implements LeaveRequestsRepository {
  StaticLeaveRequestsRepository();

  final _pending = <String, int>{};

  static const _kinds = <(String, String, int, LeaveKindCategory, int?)>[
    ('ANNUAL_LEAVE', 'إجازة سنوية', 1, LeaveKindCategory.balance, null),
    ('EMERGENCY_LEAVE', 'طارئة', 4, LeaveKindCategory.balance, null),
    ('MARRIAGE_LEAVE', 'زواج', 5, LeaveKindCategory.fixed, 15),
    ('HAJJ_LEAVE', 'حج', 6, LeaveKindCategory.fixed, 45),
    ('MATERNITY_LEAVE', 'إجازة وضع', 7, LeaveKindCategory.fixed, 90),
    ('STUDY_LEAVE', 'إجازة دراسية', 9, LeaveKindCategory.attachment, null),
    ('IDDAH_LEAVE', 'عدة', 10, LeaveKindCategory.fixed, 130),
  ];

  LeaveKindOption _kind((String, String, int, LeaveKindCategory, int?) k) {
    final (code, label, holidayType, category, fixedDays) = k;
    final pending = _pending[code] ?? 0;
    return LeaveKindOption(
      code: code,
      label: label,
      holidayType: holidayType,
      category: category,
      fixedDays: fixedDays,
      fields: LeaveKindFields(
        reasonRequired: code == 'EMERGENCY_LEAVE',
        locationEnabled: true,
        attachmentRequired: category == LeaveKindCategory.attachment,
        endDateFixed: category == LeaveKindCategory.fixed,
      ),
      available: pending == 0,
      pendingRequests: pending,
      unavailableReason: pending == 0 ? null : 'SAME_KIND_PENDING',
    );
  }

  @override
  Future<LeaveRequestOptions> options({DateTime? date}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    final dash = StaticEmployeeDashboard.data;
    return LeaveRequestOptions(
      date: _iso(date ?? now),
      today: _iso(now),
      minDate: _iso(DateTime(now.year, now.month - 1, now.day)),
      maxDate: _iso(DateTime(now.year, now.month + 1, now.day)),
      employee: const LeaveEligibility(
        eligible: true,
        female: false,
        fridaysOff: true,
        topLevelAssigner: false,
      ),
      shift: const LeaveShiftInfo(
        status: 'ok',
        shift: 'REGULAR',
        source: 'date',
        scheduleName: 'دوام صباحي',
        checkIn: '08:00:00',
        checkOut: '14:00:00',
        shiftHours: 6,
        dayType: 'W',
      ),
      monthLocked: false,
      balances: LeaveBalances(
        asOf: _iso(now),
        emergencyAllowance: 12,
        emergencyUsed: (12 - dash.emergencyBalance).toDouble(),
        emergencyRemaining: dash.emergencyBalance.toDouble(),
        emergencyPending: _pending['EMERGENCY_LEAVE'] ?? 0,
        annualBalance: dash.annualBalance,
        annualExact: dash.annualBalance.toDouble(),
        annualPending: _pending['ANNUAL_LEAVE'] ?? 0,
      ),
      kinds: _kinds.map(_kind).toList(),
    );
  }

  @override
  Future<LeavePlan> preview({
    required String kind,
    required DateTime from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final def = _kinds.where((k) => k.$1 == kind);
    if (def.isEmpty) {
      throw const ApiException(statusCode: 400, message: 'نوع إجازة غير معروف');
    }
    final option = _kind(def.first);
    final start = DateTime(from.year, from.month, from.day);
    final end = option.fixedDays != null
        ? start.add(Duration(days: option.fixedDays! - 1))
        : DateTime((to ?? from).year, (to ?? from).month, (to ?? from).day);
    if (end.isBefore(start)) {
      throw const ApiException(
        statusCode: 400,
        code: 'INVALID_DATE_RANGE',
        message: 'الفرق في التواريخ يساوي عدداً سالباً، يرجى إعادة تحديد يوم النهاية',
      );
    }
    var days = 0;
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (option.isAnnual && d.weekday == DateTime.friday) continue;
      days++;
    }
    final dash = StaticEmployeeDashboard.data;
    LeaveBalanceCheck? balance;
    if (option.isAnnual || option.isEmergency) {
      final available = (option.isAnnual ? dash.annualBalance : dash.emergencyBalance)
          .toDouble();
      balance = LeaveBalanceCheck(
        kind: option.isAnnual ? 'annual' : 'emergency',
        asOf: _iso(start),
        available: available,
        required: days.toDouble(),
        remaining: available - days,
      );
      if (balance.remaining < 0) {
        throw ApiException(
          statusCode: 422,
          code: 'INSUFFICIENT_BALANCE',
          message:
              'نعتذر ولكن عدد الأيام المطلوبة أكبر من رصيد إجازاتك حيث أن رصيد إجازاتك هو ${available.toStringAsFixed(0)}',
        );
      }
    }
    return LeavePlan(
      kind: option,
      from: _iso(start),
      to: _iso(end),
      requestedTo: _iso(end),
      days: days.toDouble(),
      blocks: [LeaveBlock(from: _iso(start), to: _iso(end), days: days.toDouble())],
      method: option.fixedDays != null
          ? 'FIXED'
          : (option.isAnnual ? 'FRIDAYS_EXCLUDED' : 'CALENDAR'),
      balance: balance,
    );
  }

  @override
  Future<LeaveRequestResult> submit({
    required String kind,
    required DateTime from,
    DateTime? to,
    String? reason,
    LeaveLocation? location,
    LeaveAttachmentUpload? attachment,
  }) async {
    final plan = await preview(kind: kind, from: from, to: to);
    if ((_pending[kind] ?? 0) > 0) {
      throw ApiException(
        statusCode: 409,
        code: 'SAME_KIND_PENDING',
        message:
            'لا يمكن تقديم طلب لمثل هذا النوع لأنه لديك طلب ${plan.kind.label} لا يزال معلقاً لم يتم اتخاذ إجراء به',
      );
    }
    if (kind == 'EMERGENCY_LEAVE' && (reason == null || reason.trim().isEmpty)) {
      throw const ApiException(
        statusCode: 400,
        code: 'REASON_REQUIRED',
        message: 'يرجى كتابة سبب الإجازة الطارئة',
      );
    }
    if (kind == 'STUDY_LEAVE' && attachment == null) {
      throw const ApiException(
        statusCode: 400,
        code: 'ATTACHMENT_REQUIRED',
        message: 'يرجى إرفاق المستند المطلوب للإجازة الدراسية',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _pending[kind] = (_pending[kind] ?? 0) + 1;
    return LeaveRequestResult(
      requests: [
        LeaveBlock(
          id: 91000 + _pending.length,
          from: plan.from,
          to: plan.to,
          days: plan.days,
        ),
      ],
      plan: plan,
      state: 'تم الإرسال',
      submittedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      message:
          'تم تقديم طلبك بنجاح للحصول على ${plan.kind.label} في الفترة من ${plan.from} إلى ${plan.to}',
      attachment: attachment == null
          ? null
          : LeaveAttachmentInfo(
              fileName: attachment.fileName,
              extension: attachment.fileName.split('.').last.toLowerCase(),
              size: attachment.bytes.length,
            ),
    );
  }
}
