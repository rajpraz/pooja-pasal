import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/checkout/domain/checkout_totals.dart';

CartItem _line(double price, int qty) => CartItem(
    productId: 'p$price',
    name: 'Item',
    price: price,
    qty: qty,
    image: '',
    sellerId: 's');

void main() {
  test('prices the server-reported cart and adds delivery', () {
    final totals = CheckoutTotals.compute(
        items: [_line(500, 2), _line(250, 1)],
        fallbackSubtotal: 0,
        deliveryFee: 80);
    expect(totals.subtotal, 1250);
    expect(totals.discount, 0);
    expect(totals.total, 1330);
  });

  test('uses the passed-in subtotal until the cart has loaded', () {
    final totals = CheckoutTotals.compute(
        items: const [], fallbackSubtotal: 600, deliveryFee: 80);
    expect(totals.total, 680);
  });

  test('a coupon never takes off more than the items cost', () {
    final totals = CheckoutTotals.compute(
        items: [_line(100, 1)],
        fallbackSubtotal: 0,
        deliveryFee: 80,
        couponDiscount: 500);
    expect(totals.discount, 100);
    expect(totals.total, 80);
  });

  test('an empty order costs nothing, not just delivery', () {
    final totals = CheckoutTotals.compute(
        items: const [], fallbackSubtotal: 0, deliveryFee: 80);
    expect(totals.total, 0);
  });
}
