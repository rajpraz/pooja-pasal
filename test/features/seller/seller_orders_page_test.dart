import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/app/theme/app_theme.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/seller/orders/presentation/pages/seller_orders_page.dart';

import '../../support/fakes.dart';

PoojaOrder _order(
  String id, {
  String status = 'pending',
  String method = 'cod',
  String payment = 'pending',
}) =>
    PoojaOrder(
      id: id,
      buyerId: 'b1',
      sellerIds: const ['s1', 's2'],
      items: const [
        OrderItem(productId: 'p1', name: 'Brass Diya', price: 500, qty: 2, sellerId: 's1'),
        OrderItem(productId: 'p2', name: "Someone else's item", price: 99, qty: 1, sellerId: 's2'),
      ],
      totalAmount: 1179,
      status: status,
      shippingAddress: 'Sita, Thamel, 9800000000',
      paymentMethod: method,
      paymentStatus: payment,
    );

void main() {
  late FakeOrderRepository orders;

  Future<void> pump(WidgetTester tester, List<PoojaOrder> sellerOrders) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    orders = FakeOrderRepository()..sellerOrders = sellerOrders;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(const AuthSession(uid: 's1', email: 's@example.com'))),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: SellerOrdersPage())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows only this seller\'s lines, with the address to ship to', (tester) async {
    await pump(tester, [_order('o1aaaaaaaa')]);
    expect(find.textContaining('Brass Diya × 2'), findsOneWidget);
    expect(find.textContaining("Someone else's item"), findsNothing);
    expect(find.textContaining('Sita, Thamel, 9800000000'), findsOneWidget);
  });

  testWidgets('moves a COD order forward', (tester) async {
    await pump(tester, [_order('o1aaaaaaaa')]);
    await tester.tap(find.text('Mark as Confirmed'));
    await tester.pumpAndSettle();
    expect(orders.statusChanges, ['o1aaaaaaaa→confirmed']);
  });

  testWidgets('an unpaid Khalti order is confirmed by its payment, not by hand', (tester) async {
    await pump(tester, [_order('o2bbbbbbbb', method: 'khalti')]);
    expect(find.text('Mark as Confirmed'), findsNothing);
    expect(find.text('Cancel Order'), findsOneWidget, reason: 'the seller can still cancel');
  });

  testWidgets('asks to confirm cash only once a COD order is delivered', (tester) async {
    await pump(tester, [_order('o3cccccccc', status: 'delivered')]);
    expect(find.text('Confirm Cash Payment Collected'), findsOneWidget);
    expect(find.text('Cancel Order'), findsNothing, reason: 'too late to cancel');
  });
}
