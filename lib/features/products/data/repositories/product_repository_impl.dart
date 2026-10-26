import 'package:pooja_pasal/features/products/data/datasources/product_remote_data_source.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_page.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_sort.dart';
import 'package:pooja_pasal/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Stream<List<Product>> streamActiveProducts() =>
      _dataSource.streamActiveProducts();

  @override
  Future<ProductPage> fetchActiveProductsPage({
    Object? startAfter,
    int limit = 20,
    ProductSort sort = ProductSort.newest,
  }) =>
      _dataSource.fetchActiveProductsPage(
          startAfter: startAfter, limit: limit, sort: sort);

  @override
  Stream<List<Product>> streamSellerProducts(String sellerId) =>
      _dataSource.streamSellerProducts(sellerId);

  @override
  Stream<List<Product>> streamAllProductsForAdmin({int limit = 200}) =>
      _dataSource.streamAllProductsForAdmin(limit: limit);

  @override
  Future<Product?> getProduct(String productId) =>
      _dataSource.getProduct(productId);

  @override
  Future<List<Product>> search(String query) => _dataSource.search(query);

  @override
  Future<String> addProduct(Product product) => _dataSource.addProduct(product);

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) =>
      _dataSource.updateProduct(productId, updates);

  @override
  Future<void> deleteProduct(String productId) =>
      _dataSource.deleteProduct(productId);
}
