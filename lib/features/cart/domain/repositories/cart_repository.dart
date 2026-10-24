import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

abstract class CartRepository {
  Stream<List<CartItem>> streamCart(String uid);

  Future<void> addToCart(String uid, Product product, {int qty = 1});

  Future<void> updateQty(String uid, String productId, int qty);

  Future<void> removeItem(String uid, String productId);

  Future<void> clearCart(String uid);
}
