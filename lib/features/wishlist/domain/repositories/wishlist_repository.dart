import 'package:pooja_pasal/features/wishlist/domain/entities/wishlist_item.dart';

abstract class WishlistRepository {
  Stream<List<WishlistItem>> streamWishlist(String uid);

  /// Returns true if the item ends up saved, false if it was removed.
  Future<bool> toggle(String uid, String productId);

  Future<void> remove(String uid, String productId);
}
