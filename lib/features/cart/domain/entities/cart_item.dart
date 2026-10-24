import 'package:pooja_pasal/core/network/json_reader.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final int qty;
  final String image;
  final String sellerId;

  /// Live stock the server reports for this line (0 when the product was
  /// deactivated); null for lines built on the device.
  final int? availableStock;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.image,
    required this.sellerId,
    this.availableStock,
  });

  double get subtotal => price * qty;

  factory CartItem.fromJson(Map<String, dynamic> map) {
    return CartItem(
      productId: map.str('productId'),
      name: map.str('name'),
      price: map.dbl('price'),
      qty: map.integer('qty', 1),
      image: map.str('image'),
      sellerId: map.str('sellerId'),
      availableStock: map.intOrNull('availableStock'),
    );
  }
}
