import 'package:pooja_pasal/core/network/json_reader.dart';

/// A saved wishlist entry — just the product reference, never a copy of the
/// product's name/price/image. Those go stale the moment the product
/// changes; the UI always resolves the live product via
/// `productProvider(productId)`.
class WishlistItem {
  final String productId;
  final DateTime? addedAt;

  const WishlistItem({required this.productId, this.addedAt});

  factory WishlistItem.fromJson(Map<String, dynamic> map) {
    return WishlistItem(
      productId: map.str('productId'),
      addedAt: map.date('addedAt'),
    );
  }
}
