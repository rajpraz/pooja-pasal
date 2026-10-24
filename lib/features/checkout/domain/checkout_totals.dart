import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';

/// What checkout shows the buyer will pay. Only a preview: the API prices
/// the order again from live products when it is placed, and that total is
/// the one charged.
class CheckoutTotals {
  final double subtotal;
  final double discount;
  final double deliveryFee;

  const CheckoutTotals({required this.subtotal, required this.discount, required this.deliveryFee});

  /// [items] priced as the server reported them; [fallbackSubtotal] is used
  /// until they have loaded. A coupon never takes off more than the items
  /// cost, and nothing is charged for delivery on an empty order.
  factory CheckoutTotals.compute({
    required List<CartItem> items,
    required double fallbackSubtotal,
    required double deliveryFee,
    double couponDiscount = 0,
  }) {
    final subtotal = items.isEmpty
        ? fallbackSubtotal
        : items.fold<double>(0, (sum, item) => sum + item.subtotal);
    return CheckoutTotals(
      subtotal: subtotal,
      discount: couponDiscount.clamp(0, subtotal).toDouble(),
      deliveryFee: subtotal > 0 ? deliveryFee : 0,
    );
  }

  double get total => subtotal - discount + deliveryFee;
}
