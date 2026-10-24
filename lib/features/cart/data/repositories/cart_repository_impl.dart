import 'package:pooja_pasal/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/repositories/cart_repository.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _dataSource;

  CartRepositoryImpl(this._dataSource);

  @override
  Stream<List<CartItem>> streamCart(String uid) => _dataSource.streamCart(uid);

  @override
  Future<void> addToCart(String uid, Product product, {int qty = 1}) =>
      _dataSource.addToCart(uid, product, qty: qty);

  @override
  Future<void> updateQty(String uid, String productId, int qty) =>
      _dataSource.updateQty(uid, productId, qty);

  @override
  Future<void> removeItem(String uid, String productId) => _dataSource.removeItem(uid, productId);

  @override
  Future<void> clearCart(String uid) => _dataSource.clearCart(uid);
}
