import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pooja_pasal/features/categories/data/repositories/category_repository_impl.dart';
import 'package:pooja_pasal/features/categories/domain/entities/category.dart';
import 'package:pooja_pasal/features/categories/domain/repositories/category_repository.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
      CategoryRemoteDataSource(ref.watch(apiClientProvider)));
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).streamActiveCategories();
});

/// Admin-only: every category (active and inactive), so deactivated ones
/// can still be found and reactivated.
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(categoryRepositoryProvider).streamAllCategories();
});

/// Product count per category name, derived from whatever product list is
/// already being fetched by `activeProductsProvider` — avoids a request per
/// category just to show a count badge.
final productCountByCategoryProvider = Provider<Map<String, int>>((ref) {
  final productsAsync = ref.watch(activeProductsProvider);
  final products = productsAsync.value ?? const [];
  final counts = <String, int>{};
  for (final product in products) {
    counts[product.category] = (counts[product.category] ?? 0) + 1;
  }
  return counts;
});

/// Admin category CRUD actions (the API only accepts them from admins).
class CategoryController extends AsyncNotifier<void> {
  late final CategoryRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(categoryRepositoryProvider);
  }

  Future<void> create(Category category) =>
      _run(() => _repository.createCategory(category));

  Future<void> editCategory(String id, Map<String, dynamic> updates) =>
      _run(() => _repository.updateCategory(id, updates));

  Future<void> setActive(String id, bool isActive) =>
      _run(() => _repository.setActive(id, isActive));

  /// Tracks the action in [state] and rethrows failures, so callers'
  /// try/catch can show the error instead of closing as if it saved.
  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final categoryControllerProvider =
    AsyncNotifierProvider<CategoryController, void>(CategoryController.new);
