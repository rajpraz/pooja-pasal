import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/categories/domain/entities/category.dart';

/// Categories (`/categories`), sorted by `sortOrder` server-side. Writes
/// are admin-only (`/admin/categories`), enforced by the API.
class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._api);

  final ApiClient _api;

  Stream<List<Category>> streamActiveCategories() => _api.watch(
        {ApiTopics.categories},
        () async => asJsonList(await _api.get('/categories')).map(Category.fromJson).toList(),
      );

  /// Includes inactive categories (the API only does so for staff).
  Stream<List<Category>> streamAllCategories() => _api.watch(
        {ApiTopics.categories},
        () async => asJsonList(await _api.get('/categories', query: {'all': true}))
            .map(Category.fromJson)
            .toList(),
      );

  Future<void> createCategory(Category category) async {
    await _api.post('/admin/categories', {
      'name': category.name,
      'imageUrl': category.imageUrl,
      'isActive': category.isActive,
      'sortOrder': category.sortOrder,
    });
    _api.notifyChanged(const [ApiTopics.categories]);
  }

  /// [updates] uses the same keys as the API (`name`, `imageUrl`,
  /// `isActive`, `sortOrder`) and must include `name`.
  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    await _api.put('/admin/categories/$id', updates);
    _api.notifyChanged(const [ApiTopics.categories, ApiTopics.products]);
  }

  Future<void> setActive(String id, bool isActive) async {
    await _api.patch('/admin/categories/$id/active', {'isActive': isActive});
    _api.notifyChanged(const [ApiTopics.categories]);
  }
}
