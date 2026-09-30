import '../../core/network/api_client.dart';
import '../models/healthcare_provider.dart';
import '../static/static_healthcare.dart';

/// المؤسسات الطبية المتعاقد معها (بديل `Contracted_Healthcare_Providers.php`
/// و`details.php`).
///
/// - `categories()` → `GET /lookups/healthcare-providers/categories`
/// - `list()`       → `GET /lookups/healthcare-providers?category=&q=&page=&limit=`
///   (البحث بالاسم/العنوان يجريه الخادم مع توحيد الهمزة والتاء المربوطة…).
abstract class HealthcareRepository {
  /// الحد الأقصى لنص البحث في الـ API.
  static const searchMaxLength = 100;

  Future<List<HealthcareCategory>> categories();

  Future<HealthcareProvidersPage> list({
    int? category,
    String? query,
    int page = 1,
    int limit = 10,
  });
}

class ApiHealthcareRepository implements HealthcareRepository {
  const ApiHealthcareRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<HealthcareCategory>> categories() async {
    final list = await _client.getJsonList('/lookups/healthcare-providers/categories');
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) HealthcareCategory.fromApi(item),
    ];
  }

  @override
  Future<HealthcareProvidersPage> list({
    int? category,
    String? query,
    int page = 1,
    int limit = 10,
  }) async {
    final q = query?.trim();
    final json = await _client.getJson(
      '/lookups/healthcare-providers',
      query: {
        if (category != null) 'category': '$category',
        if (q != null && q.isNotEmpty)
          'q': q.length > HealthcareRepository.searchMaxLength
              ? q.substring(0, HealthcareRepository.searchMaxLength)
              : q,
        'page': '$page',
        'limit': '${limit.clamp(1, 200)}',
      },
    );
    return HealthcareProvidersPage.fromApi(json);
  }
}

/// نسخة تجريبية فوق [StaticHealthcare.providers].
class StaticHealthcareRepository implements HealthcareRepository {
  const StaticHealthcareRepository({
    this.latency = const Duration(milliseconds: 300),
  });

  final Duration latency;

  @override
  Future<List<HealthcareCategory>> categories() async {
    await Future<void>.delayed(latency);
    return [
      for (final s in StaticHealthcare.specialties)
        HealthcareCategory(
          id: s.id,
          name: s.title,
          count: StaticHealthcare.providers.where((p) => p.category == s.id).length,
        ),
    ];
  }

  @override
  Future<HealthcareProvidersPage> list({
    int? category,
    String? query,
    int page = 1,
    int limit = 10,
  }) async {
    await Future<void>.delayed(latency);
    final q = (query ?? '').trim();
    final all = [
      for (final p in StaticHealthcare.providers)
        if ((category == null || p.category == category) &&
            (q.isEmpty || p.details.contains(q)))
          HealthcareProvider(
            id: p.id,
            category: p.category,
            categoryName: StaticHealthcare.specialtyById(p.category).title,
            details: p.details,
            mapUrl: p.mapUrl,
          ),
    ];
    final start = (page - 1) * limit;
    final slice = start >= all.length
        ? const <HealthcareProvider>[]
        : all.sublist(start, (start + limit).clamp(0, all.length));
    return HealthcareProvidersPage(
      items: slice,
      page: page,
      hasNext: start + limit < all.length,
      total: all.length,
    );
  }
}
