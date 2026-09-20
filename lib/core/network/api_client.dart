import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// يُستدعى عند 401 على طلب محمي؛ يعيد `true` إذا نجح تجديد التوكن
/// وينبغي إعادة المحاولة مرة واحدة بالتوكن الجديد.
typedef UnauthorizedHandler = Future<bool> Function();

/// عميل HTTP بسيط لـ Nest API مع دعم Bearer وتجديد تلقائي للجلسة.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.getAccessToken,
    this.onUnauthorized,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Future<String?> Function()? getAccessToken;
  final UnauthorizedHandler? onUnauthorized;

  static const _connectionError =
      'تعذّر الاتصال بالخادم. تأكد أن الـ API يعمل وأن العنوان صحيح.';

  Uri _uri(String path, [Map<String, String?>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('${ApiConfig.baseUrl}$normalized');
    if (query == null) return base;
    final cleaned = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };
    if (cleaned.isEmpty) return base;
    return base.replace(queryParameters: {...base.queryParameters, ...cleaned});
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

  /// GET يعيد JSON كائناً (`{}`). القوائم المرقّمة تأتي داخل `{ data, meta }`.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?>? query,
    bool auth = true,
  }) {
    return _send(
      auth: auth,
      request: (headers) => _http.get(_uri(path, query), headers: headers),
    );
  }

  /// GET يعيد JSON قائمةً (مثل `/lookups/*`).
  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String?>? query,
    bool auth = true,
  }) async {
    final response = await _sendRaw(
      auth: auth,
      request: (headers) => _http.get(_uri(path, query), headers: headers),
    );
    final decoded = _decodeBody(response);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List;
    }
    return const [];
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _send(
      auth: auth,
      request: (headers) => _http.post(
        _uri(path),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  /// GET يعيد ملفاً خاماً (PDF/صورة) مع نوعه واسمه من ترويسات الاستجابة.
  Future<ApiBinary> getBytes(
    String path, {
    Map<String, String?>? query,
    bool auth = true,
  }) async {
    final response = await _sendRaw(
      auth: auth,
      request: (headers) => _http.get(
        _uri(path, query),
        headers: {...headers, 'Accept': '*/*'}..remove('Content-Type'),
      ),
    );
    return ApiBinary(
      bytes: response.bodyBytes,
      contentType: _mediaType(response.headers['content-type']),
      fileName: _dispositionFileName(response.headers['content-disposition']),
    );
  }

  static String? _mediaType(String? header) {
    if (header == null) return null;
    final semi = header.indexOf(';');
    final type = (semi < 0 ? header : header.substring(0, semi)).trim();
    return type.isEmpty ? null : type.toLowerCase();
  }

  /// `filename*=UTF-8''...` أولاً (يدعم العربية) ثم `filename="..."`.
  static String? _dispositionFileName(String? header) {
    if (header == null) return null;
    final star = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
        .firstMatch(header);
    if (star != null) {
      try {
        return Uri.decodeComponent(star.group(1)!.trim());
      } catch (_) {/* fall through */}
    }
    final plain = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
        .firstMatch(header);
    return plain?.group(1)?.trim();
  }

  Future<void> postNoContent(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await _sendRaw(
      auth: auth,
      request: (headers) => _http.post(
        _uri(path),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    if (response.statusCode == 204 || response.statusCode == 200) return;
    _throwFor(response);
  }

  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _send({
    required bool auth,
    required Future<http.Response> Function(Map<String, String> headers)
        request,
  }) async {
    final response = await _sendRaw(auth: auth, request: request);
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  /// يرسل الطلب، ويعالج 401 بتجديد الجلسة مرة واحدة، ويحوّل الأخطاء إلى
  /// [ApiException]. يعيد الاستجابة الناجحة (2xx) فقط.
  Future<http.Response> _sendRaw({
    required bool auth,
    required Future<http.Response> Function(Map<String, String> headers)
        request,
    bool allowRefresh = true,
  }) async {
    http.Response response;
    try {
      response = await request(await _headers(auth: auth))
          .timeout(ApiConfig.receiveTimeout);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        message: _connectionError,
        details: {
          'cause':
              'انتهت المهلة (${ApiConfig.receiveTimeout.inSeconds}s) دون رد من ${ApiConfig.baseUrl}',
        },
      );
    } catch (error) {
      // نحتفظ بالسبب الأصلي (Connection refused / cleartext / unreachable…)
      // ليظهر في شاشة الدخول ويسهّل تشخيص مشاكل الشبكة.
      throw ApiException(
        message: _connectionError,
        details: {'cause': error.toString(), 'url': ApiConfig.baseUrl},
      );
    }

    if (response.statusCode == 401 &&
        auth &&
        allowRefresh &&
        onUnauthorized != null) {
      final refreshed = await onUnauthorized!();
      if (refreshed) {
        return _sendRaw(auth: auth, request: request, allowRefresh: false);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    _throwFor(response);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  Never _throwFor(http.Response response) {
    final status = response.statusCode;
    final decoded = _decodeBody(response);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
    throw ApiException(
      message: _extractMessage(json, status),
      statusCode: status,
      code: json['code'] as String?,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : null,
    );
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

/// استجابة ثنائية (ملف) من الـ API.
class ApiBinary {
  const ApiBinary({required this.bytes, this.contentType, this.fileName});

  final Uint8List bytes;
  final String? contentType;
  final String? fileName;
}
