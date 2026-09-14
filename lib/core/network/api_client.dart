import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// عميل HTTP بسيط لـ Nest API مع دعم Bearer.
class ApiClient {
  ApiClient({http.Client? httpClient, this.getAccessToken})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Future<String?> Function()? getAccessToken;

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized');
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getAccessToken?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    try {
      final response = await _http
          .post(
            _uri(path),
            headers: await _headers(auth: auth),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.receiveTimeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'تعذّر الاتصال بالخادم. تأكد أن الـ API يعمل على المنفذ 3000.',
      );
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool auth = true,
  }) async {
    try {
      final response = await _http
          .get(
            _uri(path),
            headers: await _headers(auth: auth),
          )
          .timeout(ApiConfig.receiveTimeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'تعذّر الاتصال بالخادم. تأكد أن الـ API يعمل على المنفذ 3000.',
      );
    }
  }

  Future<void> postNoContent(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await _http
          .post(
            _uri(path),
            headers: await _headers(auth: auth),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 204 || response.statusCode == 200) return;
      _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'تعذّر الاتصال بالخادم. تأكد أن الـ API يعمل على المنفذ 3000.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    }

    if (status >= 200 && status < 300) return json;

    final message = _extractMessage(json, status);
    throw ApiException(message: message, statusCode: status);
  }

  String _extractMessage(Map<String, dynamic> json, int status) {
    final raw = json['message'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).join('\n');
    }

    return switch (status) {
      401 => 'رقم الموظف أو كلمة المرور غير صحيحة',
      403 => 'هذا الحساب غير مخوّل بتسجيل الدخول',
      429 => 'محاولات كثيرة. حاول بعد قليل',
      404 => 'مسار الخدمة غير موجود. تحقق من عنوان الـ API',
      >= 500 => 'خطأ في الخادم. حاول لاحقاً',
      _ => 'فشل الطلب (رمز $status)',
    };
  }

  void close() => _http.close();
}
