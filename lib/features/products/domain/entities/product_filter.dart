import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_sort.dart';

/// Buyer-facing filter/sort selection, held centrally in Riverpod
/// (`productFilterProvider`) rather than scattered across widget-local
/// booleans — every browsing surface (all-products, search results,
/// category page) reads the same state.
class ProductFilter {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final double? minRating;
  final ProductSort sort;

  const ProductFilter({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.minRating,
    this.sort = ProductSort.newest,
  });

  bool get isDefault =>
      category == null &&
      minPrice == null &&
      maxPrice == null &&
      !inStockOnly &&
      minRating == null &&
      sort == ProductSort.newest;

  ProductFilter copyWith({
    String? category,
    bool clearCategory = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? inStockOnly,
    double? minRating,
    bool clearMinRating = false,
    ProductSort? sort,
  }) {
    return ProductFilter(
      category: clearCategory ? null : (category ?? this.category),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      sort: sort ?? this.sort,
    );
  }

  /// Applied client-side, on top of whatever a page fetch already returned,
  /// while [sort] is applied server-side (`GET /products?sort=`).
  bool matches(Product product) {
    if (category != null && product.category != category) return false;
    if (minPrice != null && product.price < minPrice!) return false;
    if (maxPrice != null && product.price > maxPrice!) return false;
    if (inStockOnly && product.stock <= 0) return false;
    if (minRating != null && product.ratingAverage < minRating!) return false;
    return true;
  }
}
