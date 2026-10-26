import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_filter_providers.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';

/// Raw, unfiltered page state — client-side filters (category/price/
/// rating/in-stock, see `ProductFilter.matches`) are applied by whoever
/// reads this, not baked into what's fetched, so toggling those filters
/// never needs a refetch. Only `sort` changes what's fetched (it's a
/// different server-side ordering), which is why [build] watches it.
class ProductListState {
  final List<Product> rawItems;
  final Object? cursor;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductListState({
    this.rawItems = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  ProductListState copyWith({
    List<Product>? rawItems,
    Object? cursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProductListState(
      rawItems: rawItems ?? this.rawItems,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Paginated active-product listing (Home's "View All", search/category
/// browsing surfaces that want infinite scroll instead of the unbounded
/// `activeProductsProvider` stream).
class ProductListController extends AsyncNotifier<ProductListState> {
  @override
  FutureOr<ProductListState> build() async {
    final repository = ref.watch(productRepositoryProvider);
    final sort = ref.watch(productFilterProvider.select((f) => f.sort));
    final page = await repository.fetchActiveProductsPage(sort: sort);
    return ProductListState(
        rawItems: page.items, cursor: page.cursor, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final repository = ref.read(productRepositoryProvider);
    final sort = ref.read(productFilterProvider).sort;
    try {
      final page = await repository.fetchActiveProductsPage(
        startAfter: current.cursor,
        sort: sort,
      );
      state = AsyncData(ProductListState(
        rawItems: [...current.rawItems, ...page.items],
        cursor: page.cursor,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      // Keep the already-loaded items visible; just stop showing the
      // load-more spinner so the user can retry by scrolling again.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final productListControllerProvider =
    AsyncNotifierProvider<ProductListController, ProductListState>(
        ProductListController.new);
