import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_page.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_sort.dart';

/// Products. The storefront reads `/products` (active only, filtered and
/// sorted in SQL); sellers manage theirs under `/seller/products` (the API
/// scopes a seller to their own products, admins see all).
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._api);

  final ApiClient _api;

  List<Product> _products(dynamic payload) => asJsonList(payload).map(Product.fromJson).toList();

  /// `meta.hasMore` of a paginated `/products` reply.
  bool _hasMore(dynamic payload) {
    if (payload is! Map<String, dynamic>) return false;
    final meta = payload['meta'];
    return meta is Map && meta['hasMore'] == true;
  }

  /// The whole active catalog, for surfaces that filter it on the device
  /// (category/festival pages, related products, search). Everything else
  /// should page with [fetchActiveProductsPage].
  Stream<List<Product>> streamActiveProducts() => _api.watch({ApiTopics.products}, () async {
        final all = <Product>[];
        for (var page = 1;; page++) {
          final payload = await _api.get('/products', query: {'page': page, 'perPage': 50});
          all.addAll(_products(payload));
          if (!_hasMore(payload)) return all;
        }
      });

  /// One page of active products sorted server-side by [sort]. [startAfter]
  /// is the page number returned as the previous page's cursor.
  Future<ProductPage> fetchActiveProductsPage({
    Object? startAfter,
    int limit = 20,
    ProductSort sort = ProductSort.newest,
  }) async {
    final page = startAfter is int ? startAfter : 1;
    final payload =
        await _api.get('/products', query: {'page': page, 'perPage': limit, 'sort': sort.name});
    return ProductPage(items: _products(payload), cursor: page + 1, hasMore: _hasMore(payload));
  }

  /// [sellerId]'s products including inactive ones (a seller always gets
  /// their own; an admin may look at any seller's).
  Stream<List<Product>> streamSellerProducts(String sellerId) => _api.watch(
        {ApiTopics.products},
        () async => _products(await _api.get('/seller/products', query: {'sellerId': sellerId})),
      );

  /// Admin-only unfiltered view, newest first.
  Stream<List<Product>> streamAllProductsForAdmin({int limit = 200}) => _api.watch(
        {ApiTopics.products},
        () async => _products(await _api.get('/seller/products')).take(limit).toList(),
      );

  Future<Product?> getProduct(String productId) async {
    try {
      return Product.fromJson(asJsonMap(await _api.get('/products/$productId')));
    } on AppFunctionException catch (e) {
      if (e.code == 'not-found') return null;
      rethrow;
    }
  }

  Future<List<Product>> search(String query) async =>
      _products(await _api.get('/products/search', query: {'q': query}));

  Future<String> addProduct(Product product) async {
    final created = asJsonMap(await _api.post('/seller/products', product.toJson()));
    _api.notifyChanged(const [ApiTopics.products]);
    return created['id'] as String? ?? '';
  }

  /// `{isActive}` alone toggles the product on/off sale; anything else is a
  /// full edit and must carry name, price, category and stock.
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    if (updates.length == 1 && updates.containsKey('isActive')) {
      await _api.patch('/seller/products/$productId/active', {'isActive': updates['isActive']});
    } else {
      await _api.put('/seller/products/$productId', updates);
    }
    _api.notifyChanged(const [ApiTopics.products]);
  }

  /// Admin only; sellers deactivate instead.
  Future<void> deleteProduct(String productId) async {
    await _api.delete('/admin/products/$productId');
    _api.notifyChanged(const [ApiTopics.products]);
  }
}
