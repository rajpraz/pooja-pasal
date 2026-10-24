import 'package:pooja_pasal/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pooja_pasal/features/categories/domain/entities/category.dart';
import 'package:pooja_pasal/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _dataSource;

  CategoryRepositoryImpl(this._dataSource);

  @override
  Stream<List<Category>> streamActiveCategories() => _dataSource.streamActiveCategories();

  @override
  Stream<List<Category>> streamAllCategories() => _dataSource.streamAllCategories();

  @override
  Future<void> createCategory(Category category) => _dataSource.createCategory(category);

  @override
  Future<void> updateCategory(String id, Map<String, dynamic> updates) =>
      _dataSource.updateCategory(id, updates);

  @override
  Future<void> setActive(String id, bool isActive) => _dataSource.setActive(id, isActive);
}
