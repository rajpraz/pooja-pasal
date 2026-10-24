import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_line_validation.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

CartItem _item({double price = 100, int qty = 1}) => CartItem(
      productId: 'p1',
      name: 'Diya Set',
      price: price,
      qty: qty,
      image: '',
      sellerId: 's1',
    );

Product _product({double price = 100, int stock = 10, bool isActive = true}) => Product(
      id: 'p1',
      name: 'Diya Set',
      description: '',
      price: price,
      category: 'Diyas',
      images: const [],
      stock: stock,
      sellerId: 's1',
      isActive: isActive,
    );

void main() {
  group('CartLineValidation.isPurchasable', () {
    test('true when product exists, is active, and has enough stock', () {
      final line = CartLineValidation(item: _item(qty: 2), product: _product(stock: 5));
      expect(line.exists, isTrue);
      expect(line.isActive, isTrue);
      expect(line.inStock, isTrue);
      expect(line.isPurchasable, isTrue);
    });

    test('false when the product has been deleted (null)', () {
      final line = CartLineValidation(item: _item(), product: null);
      expect(line.exists, isFalse);
      expect(line.isPurchasable, isFalse);
    });

    test('false when the product has been deactivated', () {
      final line = CartLineValidation(item: _item(), product: _product(isActive: false));
      expect(line.isActive, isFalse);
      expect(line.isPurchasable, isFalse);
    });

    test('false when requested quantity exceeds current stock', () {
      final line = CartLineValidation(item: _item(qty: 10), product: _product(stock: 3));
      expect(line.inStock, isFalse);
      expect(line.isPurchasable, isFalse);
    });

    test('true at the exact stock boundary (qty == stock)', () {
      final line = CartLineValidation(item: _item(qty: 3), product: _product(stock: 3));
      expect(line.inStock, isTrue);
      expect(line.isPurchasable, isTrue);
    });

    test('out-of-stock (stock == 0) is never purchasable regardless of qty', () {
      final line = CartLineValidation(item: _item(), product: _product(stock: 0));
      expect(line.inStock, isFalse);
      expect(line.isPurchasable, isFalse);
    });
  });

  group('CartLineValidation.priceChanged / effectivePrice', () {
    test('false when the live price matches what was captured at add-to-cart time', () {
      final line = CartLineValidation(item: _item(), product: _product());
      expect(line.priceChanged, isFalse);
      expect(line.effectivePrice, 100);
    });

    test('true when the live price has increased since add-to-cart', () {
      final line = CartLineValidation(item: _item(), product: _product(price: 130));
      expect(line.priceChanged, isTrue);
      expect(line.effectivePrice, 130);
    });

    test('true when the live price has decreased since add-to-cart', () {
      final line = CartLineValidation(item: _item(), product: _product(price: 80));
      expect(line.priceChanged, isTrue);
      expect(line.effectivePrice, 80);
    });

    test('priceChanged is false (not a crash) when the product has been deleted', () {
      final line = CartLineValidation(item: _item(), product: null);
      expect(line.priceChanged, isFalse);
      expect(line.effectivePrice, 100); // falls back to the cart item's captured price
    });

    test('effectiveSubtotal uses the live price times quantity', () {
      final line = CartLineValidation(item: _item(qty: 3), product: _product(price: 90));
      expect(line.effectiveSubtotal, 270);
    });
  });
}
