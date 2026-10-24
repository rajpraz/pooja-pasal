import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/wishlist/domain/entities/wishlist_item.dart';

/// The signed-in user's wishlist (`/wishlist`) — product references only;
/// the UI resolves live products. [uid] is implied by the session.
class WishlistRemoteDataSource {
  WishlistRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<WishlistItem>> _fetch() async =>
      asJsonList(await _api.get('/wishlist')).map(WishlistItem.fromJson).toList();

  Stream<List<WishlistItem>> streamWishlist(String uid) => _api.watch({ApiTopics.wishlist}, _fetch);

  /// Adds or removes [productId]; returns whether it's now saved.
  Future<bool> toggle(String uid, String productId) async {
    final saved = (await _fetch()).any((item) => item.productId == productId);
    if (saved) {
      await _api.delete('/wishlist/$productId');
    } else {
      await _api.post('/wishlist/$productId');
    }
    _api.notifyChanged(const [ApiTopics.wishlist]);
    return !saved;
  }

  Future<void> remove(String uid, String productId) async {
    await _api.delete('/wishlist/$productId');
    _api.notifyChanged(const [ApiTopics.wishlist]);
  }
}
