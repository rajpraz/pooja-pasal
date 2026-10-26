import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

/// The signed-in user's server-side cart (`/cart`), one line per product.
/// The API clamps quantities to live stock and reports each line's current
/// price, so the cart never shows a stale price. [uid] is implied by the
/// session.
class CartRemoteDataSource {
  CartRemoteDataSource(this._api);

  final ApiClient _api;

  Stream<List<CartItem>> streamCart(String uid) => _api.watch(
        {ApiTopics.cart},
        () async =>
            asJsonList(await _api.get('/cart')).map(CartItem.fromJson).toList(),
      );

  Future<void> addToCart(String uid, Product product, {int qty = 1}) async {
    await _api.post('/cart', {'productId': product.id, 'qty': qty});
    _api.notifyChanged(const [ApiTopics.cart]);
  }

  Future<void> updateQty(String uid, String productId, int qty) async {
    if (qty < 1) {
      await removeItem(uid, productId);
      return;
    }
    await _api.patch('/cart/$productId', {'qty': qty});
    _api.notifyChanged(const [ApiTopics.cart]);
  }

  Future<void> removeItem(String uid, String productId) async {
    await _api.delete('/cart/$productId');
    _api.notifyChanged(const [ApiTopics.cart]);
  }

  Future<void> clearCart(String uid) async {
    await _api.delete('/cart');
    _api.notifyChanged(const [ApiTopics.cart]);
  }
}
