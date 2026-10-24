import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_line_validation.dart';
import 'package:pooja_pasal/features/cart/domain/pricing_service.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

CartItem _item({
  String productId = 'p1',
  String name = 'Diya Set',
  double price = 100,
  int qty = 1,
  String sellerId = 's1',
}) {
  return CartItem(
    productId: productId,
    name: name,
    price: price,
    qty: qty,
    image: '',
    sellerId: sellerId,
  );
}

Product _product({
  String id = 'p1',
  double price = 100,
  int stock = 10,
  bool isActive = true,
}) {
  return Product(
    id: id,
    name: 'Diya Set',
    description: '',
    price: price,
    category: 'Diyas',
    images: const [],
    stock: stock,
    sellerId: 's1',
    isActive: isActive,
  );
}

void main() {
  group('PricingService.subtotal / total', () {
    test('empty cart has zero subtotal and total equals delivery fee minus discount', () {
      expect(PricingService.subtotal(const []), 0);
      expect(PricingService.total(const []), PricingService.deliveryFee - PricingService.discount);
    });

    test('single item subtotal is price * qty', () {
      final items = [_item(price: 150, qty: 3)];
      expect(PricingService.subtotal(items), 450);
    });

    test('multiple items sum correctly', () {
      final items = [
        _item(qty: 2), // 200
        _item(productId: 'p2', price: 50), // 50
        _item(productId: 'p3', price: 75.5, qty: 4), // 302
      ];
      expect(PricingService.subtotal(items), 552.0);
      expect(PricingService.total(items),
          552.0 + PricingService.deliveryFee - PricingService.discount);
    });

    test('total always includes delivery fee even for a single low-value item', () {
      final items = [_item(price: 10)];
      expect(
          PricingService.total(items), 10 + PricingService.deliveryFee - PricingService.discount);
    });
  });

  group('PricingService.subtotalFromValidated / totalFromValidated', () {
    test('excludes unpurchasable lines (inactive product) from the total', () {
      final lines = [
        CartLineValidation(item: _item(), product: _product()),
        CartLineValidation(
            item: _item(productId: 'p2', price: 50), product: _product(id: 'p2', isActive: false)),
      ];
      expect(PricingService.subtotalFromValidated(lines), 100);
    });

    test('excludes out-of-stock lines (insufficient stock) from the total', () {
      final lines = [
        CartLineValidation(
            item: _item(qty: 5), product: _product(stock: 2)), // wants 5, only 2 left
      ];
      expect(PricingService.subtotalFromValidated(lines), 0);
      expect(PricingService.totalFromValidated(lines), 0);
    });

    test('excludes deleted product (null product) lines from the total', () {
      final lines = [
        CartLineValidation(item: _item(), product: null),
      ];
      expect(PricingService.subtotalFromValidated(lines), 0);
    });

    test('uses the live product price, not the stale cart-item price, when they differ', () {
      final lines = [
        CartLineValidation(
            item: _item(qty: 2), // stale price captured at add-to-cart time
            product: _product(price: 120)), // price has since gone up
      ];
      expect(lines.first.priceChanged, isTrue);
      expect(lines.first.effectiveSubtotal, 240); // 120 * 2, not 100 * 2
      expect(PricingService.subtotalFromValidated(lines), 240);
    });

    test('totalFromValidated is zero (not just delivery fee) when nothing is purchasable', () {
      final lines = [
        CartLineValidation(item: _item(), product: null),
      ];
      expect(PricingService.totalFromValidated(lines), 0);
    });

    test('totalFromValidated adds delivery fee once purchasable lines exist', () {
      final lines = [
        CartLineValidation(item: _item(price: 200), product: _product(price: 200)),
      ];
      expect(PricingService.totalFromValidated(lines),
          200 + PricingService.deliveryFee - PricingService.discount);
    });
  });
}
