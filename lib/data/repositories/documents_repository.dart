import 'dart:typed_data';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/employee_clip.dart';
import '../static/demo_pdf_bytes.dart';
import '../static/static_employee_clips.dart';

/// قصاصات ومستندات الموظف (بديل `getYourPdfs.php` / `download.php`).
///
/// - `list()`       → `GET /me/documents?month=YYYY-MM&page=&limit=`
/// - `fetchFile()`  → `GET /me/documents/:id/file?mode=view` (بالتوكن، يعيد الملف)
/// - `signedLink()` → `GET /me/documents/:id/link?mode=` (رابط مؤقت بلا توكن للعارض الخارجي)
abstract class DocumentsRepository {
  Future<EmployeeClipsPage> list({String? month, int page = 1, int limit = 6});

  Future<EmployeeClipFile> fetchFile(EmployeeClip clip);

  Future<EmployeeClipLink> signedLink(EmployeeClip clip, {bool download = false});
}

class ApiDocumentsRepository implements DocumentsRepository {
  const ApiDocumentsRepository(this._client);

  final ApiClient _client;

  @override
  Future<EmployeeClipsPage> list({
    String? month,
    int page = 1,
    int limit = 6,
  }) async {
    final json = await _client.getJson(
      '/me/documents',
      query: {
        'month': month,
        'page': '$page',
        'limit': '${limit.clamp(1, 200)}',
      },
    );
    return EmployeeClipsPage.fromApi(json);
  }

  @override
  Future<EmployeeClipFile> fetchFile(EmployeeClip clip) async {
    final binary = await _client.getBytes(
      clip.filePath,
      query: const {'mode': 'view'},
    );
    return EmployeeClipFile(
      bytes: binary.bytes,
      contentType: binary.contentType ?? clip.contentType,
      fileName: binary.fileName ?? clip.fileName,
    );
  }

  @override
  Future<EmployeeClipLink> signedLink(
    EmployeeClip clip, {
    bool download = false,
  }) async {
    final json = await _client.getJson(
      clip.linkPath,
      query: {'mode': download ? 'download' : 'view'},
    );
    return EmployeeClipLink.fromApi(json);
  }
}

/// تنفيذ ثابت: قائمة تجريبية + PDF حقيقي من `DemoPdfBytes` للمعاينة.
class StaticDocumentsRepository implements DocumentsRepository {
  const StaticDocumentsRepository({
    this.latency = const Duration(milliseconds: 350),
  });

  final Duration latency;

  @override
  Future<EmployeeClipsPage> list({
    String? month,
    int page = 1,
    int limit = 6,
  }) async {
    await Future<void>.delayed(latency);
    final all = StaticEmployeeClips.clips.where((c) {
      if (month == null || c.date == null) return month == null;
      final ym =
          '${c.date!.year}-${c.date!.month.toString().padLeft(2, '0')}';
      return ym == month;
    }).toList()
      ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    final start = (page - 1) * limit;
    final slice = start >= all.length
        ? const <EmployeeClip>[]
        : all.sublist(start, (start + limit).clamp(0, all.length));
    return EmployeeClipsPage(
      available: true,
      items: slice,
      page: page,
      hasNext: start + limit < all.length,
    );
  }

  @override
  Future<EmployeeClipFile> fetchFile(EmployeeClip clip) async {
    await Future<void>.delayed(latency);
    if (!clip.isPdf) {
      // لا توجد صورة تجريبية؛ نحاكي «الملف غير موجود على هذا الخادم».
      throw const ApiException(
        message: 'File not found on this server',
        statusCode: 404,
      );
    }
    return EmployeeClipFile(
      bytes: Uint8List.fromList(DemoPdfBytes.studyAcceptance),
      contentType: 'application/pdf',
      fileName: clip.fileName,
    );
  }

  @override
  Future<EmployeeClipLink> signedLink(
    EmployeeClip clip, {
    bool download = false,
  }) async {
    await Future<void>.delayed(latency ~/ 2);
    final exp = DateTime.now().add(const Duration(hours: 2));
    return EmployeeClipLink(
      url: Uri.parse(
        '${ApiConfig.baseUrl}/documents/${clip.id}/file?eid=1&exp=${exp.millisecondsSinceEpoch ~/ 1000}&mode=${download ? 'download' : 'view'}&sig=demo',
      ),
      expiresAt: exp,
    );
  }
}
