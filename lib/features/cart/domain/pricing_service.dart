import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_line_validation.dart';

/// Client-side preview pricing only — for what the cart screen displays
/// before checkout. The authoritative total that's actually charged is
/// always recomputed by the API (`OrderService`) from live product prices,
/// not from this. Keep the delivery fee here in sync with the API's
/// `config/shop.php` so the preview and the real total don't disagree.
class PricingService {
  static const double deliveryFee = 80;

  /// The cart preview shows no discount; a coupon is validated and applied
  /// at checkout, where the API returns the exact amount it takes off.
  static const double discount = 0;

  static double subtotal(List<CartItem> items) =>
      items.fold<double>(0, (sum, item) => sum + item.subtotal);

  static double total(List<CartItem> items) => subtotal(items) + deliveryFee - discount;

  /// Same idea, but only over lines that are actually purchasable right
  /// now (see `CartLineValidation`) and priced at their *current* value —
  /// used once cart validation data is available so the preview total
  /// matches what checkout will actually attempt to charge for.
  static double subtotalFromValidated(List<CartLineValidation> lines) => lines
      .where((line) => line.isPurchasable)
      .fold<double>(0, (sum, line) => sum + line.effectiveSubtotal);

  static double totalFromValidated(List<CartLineValidation> lines) {
    final purchasable = lines.where((line) => line.isPurchasable);
    if (purchasable.isEmpty) return 0;
    return subtotalFromValidated(lines) + deliveryFee - discount;
  }
}
