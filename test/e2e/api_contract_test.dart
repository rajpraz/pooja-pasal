// End-to-end contract test: drives the app's real data sources against a
// running Laravel API seeded with `php artisan migrate:fresh --seed`.
//
// Skipped unless API_E2E_BASE_URL is set, e.g.
//   API_E2E_BASE_URL=http://127.0.0.1:8000/api flutter test test/e2e
//
// It mutates data (orders, cart, applications), so point it at a throwaway
// database, never production.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/core/network/token_store.dart';
import 'package:pooja_pasal/features/addresses/data/datasources/address_remote_data_source.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/admin/dashboard/data/datasources/admin_dashboard_data_source.dart';
import 'package:pooja_pasal/features/admin/sellers/data/datasources/admin_seller_remote_data_source.dart';
import 'package:pooja_pasal/features/admin/users/data/datasources/admin_user_remote_data_source.dart';
import 'package:pooja_pasal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pooja_pasal/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pooja_pasal/features/coupons/data/coupon_remote_data_source.dart';
import 'package:pooja_pasal/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:pooja_pasal/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:pooja_pasal/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:pooja_pasal/features/products/data/datasources/product_remote_data_source.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_sort.dart';
import 'package:pooja_pasal/features/reviews/data/datasources/review_remote_data_source.dart';
import 'package:pooja_pasal/features/wishlist/data/datasources/wishlist_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _baseUrl = Platform.environment['API_E2E_BASE_URL'] ?? '';

/// One signed-in user with their own token.
class _Actor {
  _Actor._(this.api, this.auth);

  final ApiClient api;
  final AuthRemoteDataSource auth;

  String get uid => auth.currentUser!.uid;

  static Future<_Actor> signIn(String email) async {
    final api = ApiClient(baseUrl: _baseUrl, tokenStore: _MemoryTokenStore());
    final auth = AuthRemoteDataSource(api);
    await auth.signIn(email: email, password: 'password123');
    return _Actor._(api, auth);
  }
}

/// Keeps each actor's token separate (the real store is one per device).
class _MemoryTokenStore extends TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  test('buyer, seller and admin flows against the live API', () async {
    final buyer = await _Actor.signIn('buyer@poojapasal.test');
    final seller = await _Actor.signIn('seller@poojapasal.test');
    final admin = await _Actor.signIn('admin@poojapasal.test');

    // Profiles parse with the right roles.
    expect((await buyer.auth.getUserDoc(buyer.uid))!.role, 'buyer');
    expect((await seller.auth.getUserDoc(seller.uid))!.isSeller, isTrue);
    expect((await admin.auth.getUserDoc(buyer.uid))!.email, 'buyer@poojapasal.test');

    // Catalog.
    final categories = await CategoryRemoteDataSource(buyer.api).streamActiveCategories().first;
    expect(categories, isNotEmpty);
    final products = ProductRemoteDataSource(buyer.api);
    final page = await products.fetchActiveProductsPage(limit: 5, sort: ProductSort.priceLowToHigh);
    expect(page.items, hasLength(5));
    expect(page.items.first.price, lessThanOrEqualTo(page.items.last.price));
    expect(page.cursor, 2);
    final all = await products.streamActiveProducts().first;
    expect(all.length, greaterThanOrEqualTo(page.items.length));
    final sellerProducts =
        await ProductRemoteDataSource(seller.api).streamSellerProducts(seller.uid).first;
    final product = sellerProducts.firstWhere((p) => p.isActive && p.stock >= 3);
    expect((await products.getProduct(product.id))!.sellerName, isNotEmpty);
    expect(await products.getProduct('00000000-0000-0000-0000-000000000000'), isNull);
    expect(await products.search(product.name.split(' ').first), isNotEmpty);

    // Wishlist toggles.
    final wishlist = WishlistRemoteDataSource(buyer.api);
    final saved = await wishlist.toggle(buyer.uid, product.id);
    expect((await wishlist.streamWishlist(buyer.uid).first).any((w) => w.productId == product.id),
        saved);
    await wishlist.toggle(buyer.uid, product.id);

    // Cart and address.
    final cart = CartRemoteDataSource(buyer.api);
    await cart.clearCart(buyer.uid);
    await cart.addToCart(buyer.uid, product, qty: 2);
    final lines = await cart.streamCart(buyer.uid).first;
    expect(lines.single.qty, 2);
    expect(lines.single.price, product.price);
    final addresses = AddressRemoteDataSource(buyer.api);
    await addresses.add(
        buyer.uid,
        const Address(
            label: 'Home', recipientName: 'E2E Buyer', phone: '9800000000', fullAddress: 'Thamel'));
    final address = (await addresses.streamAddresses(buyer.uid).first).first;

    // Coupon preview (seeded DASHAIN10).
    final quote = await CouponRemoteDataSource(buyer.api).validate('dashain10', 2000);
    expect(quote.discount, greaterThan(0));

    // Checkout with COD; the server prices the order.
    final orders = OrderRemoteDataSource(buyer.api, currentUid: () => buyer.uid);
    final created = await orders.createOrder(
      items: lines,
      shippingAddress: address.formatted,
      paymentMethod: 'cod',
      idempotencyKey: 'e2e-${DateTime.now().microsecondsSinceEpoch}',
    );
    expect(created.totalAmount, product.price * 2 + 80);
    expect(await cart.streamCart(buyer.uid).first, isEmpty);
    final placed = (await orders.streamOrder(created.orderId).first)!;
    expect(placed.status, 'pending');
    expect(placed.items.single.qty, 2);
    expect((await orders.streamBuyerOrders(buyer.uid).first).first.id, created.orderId);

    // A buyer can't move their order forward.
    await expectLater(
      orders.updateOrderStatus(orderId: created.orderId, status: 'confirmed'),
      throwsA(isA<AppFunctionException>()),
    );

    // The seller fulfils it and confirms the cash.
    final sellerOrders = OrderRemoteDataSource(seller.api, currentUid: () => seller.uid);
    expect((await sellerOrders.streamSellerOrders(seller.uid).first).map((o) => o.id),
        contains(created.orderId));
    for (final status in ['confirmed', 'processing', 'shipped', 'delivered']) {
      await sellerOrders.updateOrderStatus(orderId: created.orderId, status: status);
    }
    await PaymentRemoteDataSource(seller.api).confirmCodPayment(created.orderId);
    final delivered = (await orders.streamOrder(created.orderId).first)!;
    expect(delivered.status, 'delivered');
    expect(delivered.paymentStatus, 'paid');
    expect(delivered.statusHistory.map((e) => e.status), containsAll(['pending', 'delivered']));

    // The buyer reviews it once.
    final reviews = ReviewRemoteDataSource(buyer.api);
    final existing = await reviews.streamReviewsForProduct(product.id).first;
    if (!existing.any((r) => r.buyerId == buyer.uid)) {
      await reviews.createReview(
          productId: product.id, orderId: created.orderId, rating: 5, text: 'Lovely');
      expect((await reviews.streamReviewsForProduct(product.id).first).first.buyerName, isNotEmpty);
    }

    // The buyer returns it; the admin records the refund and the buyer
    // hears about it.
    await orders.updateOrderStatus(
        orderId: created.orderId, status: 'returned', note: 'Arrived damaged');
    final returned = (await orders.streamOrder(created.orderId).first)!;
    expect(returned.status, 'returned');
    expect(returned.statusHistory.last.note, 'Arrived damaged');
    await OrderRemoteDataSource(admin.api, currentUid: () => admin.uid)
        .updatePaymentStatus(orderId: created.orderId, paymentStatus: 'refunded');
    expect((await orders.streamOrder(created.orderId).first)!.paymentStatus, 'refunded');
    final refundNotes =
        await NotificationRemoteDataSource(buyer.api).streamNotifications(buyer.uid).first;
    expect(refundNotes.map((n) => n.type), contains('payment_refunded'));

    // Notifications reached both sides.
    final buyerNotes =
        await NotificationRemoteDataSource(buyer.api).streamNotifications(buyer.uid).first;
    expect(buyerNotes.map((n) => n.type), contains('order_placed'));
    final sellerNotes =
        await NotificationRemoteDataSource(seller.api).streamNotifications(seller.uid).first;
    expect(sellerNotes.map((n) => n.type), contains('seller_new_order'));

    // Admin views.
    final stats = await AdminDashboardDataSource(admin.api).fetchStats();
    expect(stats.totalOrders, greaterThan(0));
    expect(await AdminUserRemoteDataSource(admin.api).streamUsers().first, isNotEmpty);
    final allOrders =
        await OrderRemoteDataSource(admin.api, currentUid: () => admin.uid).streamAllOrders().first;
    expect(allOrders.map((o) => o.id), contains(created.orderId));
    final adminSellers = AdminSellerRemoteDataSource(admin.api);
    expect(await adminSellers.streamSellers().first, isNotEmpty);

    // A pending seller application can be approved once.
    final pending = await adminSellers.streamPendingApplications().first;
    if (pending.isNotEmpty) {
      await adminSellers.approveApplication(pending.first.uid);
      await expectLater(
          adminSellers.approveApplication(pending.first.uid), throwsA(isA<AppFunctionException>()));
    }

    // Non-admins are refused admin data.
    await expectLater(AdminDashboardDataSource(buyer.api).fetchStats(),
        throwsA(isA<AppFunctionException>().having((e) => e.code, 'code', 'permission-denied')));

    // Signing out revokes the token.
    await buyer.auth.signOut();
    expect(buyer.auth.currentUser, isNull);
  }, skip: _baseUrl.isEmpty ? 'Set API_E2E_BASE_URL to run against a live API' : false);

  test('eSewa checkout gets signed form fields from the API', () async {
    final buyer = await _Actor.signIn('buyer@poojapasal.test');
    final product = (await ProductRemoteDataSource(buyer.api).streamActiveProducts().first)
        .firstWhere((p) => p.stock > 0);
    final payments = PaymentRemoteDataSource(buyer.api);
    if (!(await payments.availableMethods()).contains('esewa')) return;

    final created = await OrderRemoteDataSource(buyer.api, currentUid: () => buyer.uid).createOrder(
      items: [
        CartItem(
            productId: product.id,
            name: product.name,
            price: product.price,
            qty: 1,
            image: '',
            sellerId: product.sellerId)
      ],
      shippingAddress: 'E2E, Kathmandu, 9800000000',
      paymentMethod: 'esewa',
      idempotencyKey: 'e2e-esewa-${DateTime.now().microsecondsSinceEpoch}',
    );
    final fields = await payments.initiateEsewa(created.orderId);
    expect(fields.formUrl, startsWith('https://'));
    expect(fields.totalAmount, created.totalAmount.toStringAsFixed(2));
    expect(fields.signature, isNotEmpty);
    expect(fields.successUrl, contains('/payments/esewa/success'));
    expect(fields.failureUrl, contains('/failure'));
  }, skip: _baseUrl.isEmpty ? 'Set API_E2E_BASE_URL to run against a live API' : false);
}
