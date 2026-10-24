import 'package:pooja_pasal/features/categories/domain/entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> streamActiveCategories();

  /// Includes inactive categories — for the admin category-management view,
  /// which needs to see (and reactivate) deactivated categories too.
  Stream<List<Category>> streamAllCategories();

  Future<void> createCategory(Category category);

  Future<void> updateCategory(String id, Map<String, dynamic> updates);

  Future<void> setActive(String id, bool isActive);
}
