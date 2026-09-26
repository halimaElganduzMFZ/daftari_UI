import '../../core/network/api_client.dart';
import '../models/request_attachment.dart';

typedef ManagerJson = Map<String, dynamic>;

class ManagerPage {
  const ManagerPage(this.items, this.hasNext, this.total);
  final List<ManagerJson> items;
  final bool hasNext;
  final int? total;

  factory ManagerPage.fromJson(ManagerJson json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return ManagerPage(
      (json['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      meta['hasNext'] == true,
      (meta['total'] as num?)?.toInt(),
    );
  }
}

/// Manager endpoints retain the caller's Bearer identity. Employee ids here
/// are employee_card.NumAtou, never auth_users.id or the employee number.
class ManagerRepository {
  const ManagerRepository(this.client);
  final ApiClient client;

  Future<ManagerPage> page(
    String path, {
    int page = 1,
    Map<String, String?> filters = const {},
  }) async => ManagerPage.fromJson(
    await client.getJson(
      path,
      query: {...filters, 'page': '$page', 'limit': '20', 'withTotal': 'true'},
    ),
  );

  Future<ManagerJson> detail(String path, Object id) =>
      client.getJson('$path/$id');

  Future<ManagerJson> counts(String path) => client.getJson('$path/counts');

  /// Active HR cases, including those already confirmed by the manager.
  Future<int> awolCount() async {
    final json = await client.getJson('/manager/awol/count');
    final count = json['count'];
    if (count is! num || count < 0 || count != count.toInt()) {
      throw const FormatException('Invalid AWOL count');
    }
    return count.toInt();
  }

  Future<List<ManagerJson>> requestTypes() async =>
      (await client.getJsonList('/lookups/request-types'))
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<ManagerJson> decide(Object id, {String? reason}) => client.postJson(
    '/manager/requests/$id/${reason == null ? 'approve' : 'reject'}',
    auth: true,
    body: reason == null ? null : {'reason': reason.trim()},
  );

  Future<ManagerJson> confirmAwol(Object id, String notes) => client.postJson(
    '/manager/awol/$id/confirm',
    auth: true,
    body: {'notes': notes.trim()},
  );

  Future<RequestAttachment> attachment(
    String path,
    Object id,
    String name,
  ) async {
    final file = await client.getBytes('$path/$id/attachment');
    return RequestAttachment(
      fileName: file.fileName ?? name,
      bytes: file.bytes,
      fileSizeBytes: file.bytes.length,
    );
  }
}
