import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/theme/app_theme.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/core/network/token_store.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/presentation/providers/address_providers.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/checkout/presentation/pages/checkout_page.dart';
import 'package:pooja_pasal/features/coupons/data/coupon_remote_data_source.dart';
import 'package:pooja_pasal/features/coupons/domain/coupon_quote.dart';
import 'package:pooja_pasal/features/coupons/presentation/coupon_providers.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/payments/presentation/providers/payment_providers.dart';

import '../../support/fakes.dart';

class _FakeCoupons extends CouponRemoteDataSource {
  _FakeCoupons() : super(ApiClient(baseUrl: 'http://unused', tokenStore: TokenStore()));

  @override
  Future<CouponQuote> validate(String code, double subtotal) async =>
      CouponQuote(code: code.toUpperCase(), discount: 100);
}

const _home = Address(
  id: 'a1',
  label: 'Home',
  recipientName: 'Sita',
  phone: '9800000000',
  fullAddress: 'Thamel, Kathmandu',
  isDefault: true,
);

void main() {
  late FakeOrderRepository orders;
  late FakeCartRepository cart;

  Future<void> pumpCheckout(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    orders = FakeOrderRepository();
    cart = FakeCartRepository(const [
      CartItem(productId: 'p1', name: 'Brass Diya', price: 500, qty: 2, image: '', sellerId: 's1'),
    ]);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const CheckoutPage(price: 1000)),
      GoRoute(path: '/home', builder: (_, __) => const Text('Home')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(const AuthSession(uid: 'u1', email: 'sita@example.com'))),
        cartRepositoryProvider.overrideWithValue(cart),
        addressRepositoryProvider.overrideWithValue(FakeAddressRepository(const [_home])),
        orderRepositoryProvider.overrideWithValue(orders),
        couponDataSourceProvider.overrideWithValue(_FakeCoupons()),
        // The server only offers Cash on Delivery here.
        availablePaymentMethodsProvider.overrideWith((ref) async => ['cod']),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('uses the default saved address and only offers what the server accepts',
      (tester) async {
    await pumpCheckout(tester);

    expect(find.text('Home'), findsOneWidget, reason: 'saved address label');
    expect(find.text('Sita, Thamel, Kathmandu, 9800000000'), findsOneWidget);
    expect(find.text('Khalti (Unavailable)'), findsOneWidget);
    expect(find.text('eSewa (Unavailable)'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(find.textContaining('Rs.1080.00'), findsWidgets, reason: '1000 + 80 delivery');
  });

  testWidgets('asks for a payment method before placing anything', (tester) async {
    await pumpCheckout(tester);

    await tester.tap(find.textContaining('Place Order'));
    await tester.pump();

    expect(find.text('Please choose a delivery address and payment method'), findsOneWidget);
    expect(orders.placed, isEmpty);
  });

  testWidgets('places a cash-on-delivery order and tells the buyer what to pay', (tester) async {
    await pumpCheckout(tester);

    await tester.tap(find.text('Cash on Delivery'));
    await tester.pump();
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(orders.placed.single, {
      'items': 1,
      'shippingAddress': 'Sita, Thamel, Kathmandu, 9800000000',
      'paymentMethod': 'cod',
      'couponCode': null,
    });
    expect(cart.clears, 1);
    expect(find.text('Order placed successfully'), findsOneWidget);
    expect(find.textContaining('Pay Rs.1080.00 on delivery'), findsOneWidget,
        reason: "the server's total, not the preview");
  });

  testWidgets('applies a coupon to the preview and sends it with the order', (tester) async {
    await pumpCheckout(tester);

    await tester.enterText(find.byType(TextField), 'dashain10');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Discount (DASHAIN10)'), findsOneWidget);
    expect(find.textContaining('Rs.980.00'), findsWidgets, reason: '1000 - 100 + 80');
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Cash on Delivery'));
    await tester.pump();
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(orders.placed.single['couponCode'], 'DASHAIN10');
  });

  testWidgets('shows the API refusal and keeps the cart', (tester) async {
    await pumpCheckout(tester);
    orders.error = Exception('out of stock');

    await tester.tap(find.text('Cash on Delivery'));
    await tester.pump();
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Order placed successfully'), findsNothing);
    expect(cart.clears, 0);
  });
}
