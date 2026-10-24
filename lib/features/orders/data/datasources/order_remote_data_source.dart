import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';

/// Orders. Creation and every status change go through the API, which
/// re-prices from live products, reserves and restores stock, and enforces
/// who may make each move (`OrderService` in the Laravel API). Lists are
/// polled so a buyer sees the seller's updates and vice versa.
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._api, {required String? Function() currentUid})
      : _currentUid = currentUid;

  final ApiClient _api;
  final String? Function() _currentUid;

  static const _poll = Duration(seconds: 30);

  List<PoojaOrder> _orders(dynamic payload) =>
      asJsonList(payload).map(PoojaOrder.fromJson).toList();

  /// The signed-in buyer's own orders.
  Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId) => _api
      .watch({ApiTopics.orders}, () async => _orders(await _api.get('/orders')), pollEvery: _poll);

  /// Orders containing [sellerId]'s products, with only that seller's lines.
  /// The seller themselves uses the seller portal; an admin looking at a
  /// seller uses the admin list filtered to them.
  Stream<List<PoojaOrder>> streamSellerOrders(String sellerId) => _api.watch(
        {ApiTopics.orders},
        () async {
          if (sellerId == _currentUid()) return _orders(await _api.get('/seller/orders'));
          return _orders(await _api.get('/admin/orders', query: {'sellerId': sellerId}));
        },
        pollEvery: _poll,
      );

  /// One order as the caller may see it (buyers and admins see all lines,
  /// a seller only theirs); null when it doesn't exist or isn't theirs.
  Stream<PoojaOrder?> streamOrder(String orderId) => _api.watch(
        {ApiTopics.orders},
        () async {
          try {
            return PoojaOrder.fromJson(asJsonMap(await _api.get('/orders/$orderId')));
          } on AppFunctionException catch (e) {
            if (e.code == 'not-found') return null;
            rethrow;
          }
        },
        pollEvery: const Duration(seconds: 15),
      );

  /// Admin: every order, newest first.
  Stream<List<PoojaOrder>> streamAllOrders({int limit = 200}) => _api.watch(
        {ApiTopics.orders},
        () async => _orders(await _api.get('/admin/orders', query: {'limit': limit})),
        pollEvery: _poll,
      );

  Future<CreateOrderResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
    String? couponCode,
  }) async {
    final data = await _api.post('/orders', {
      'items': items.map((e) => {'productId': e.productId, 'qty': e.qty}).toList(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'idempotencyKey': idempotencyKey,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
    }) as Map<String, dynamic>;
    _api.notifyChanged(
        const [ApiTopics.orders, ApiTopics.cart, ApiTopics.products, ApiTopics.notifications]);
    return CreateOrderResult(
      orderId: data['orderId'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deduplicated: data['deduplicated'] as bool? ?? false,
    );
  }

  Future<void> updatePaymentStatus({required String orderId, required String paymentStatus}) async {
    await _api.patch('/admin/orders/$orderId/payment', {'paymentStatus': paymentStatus});
    _api.notifyChanged(const [ApiTopics.orders, ApiTopics.notifications]);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    await _api.patch('/orders/$orderId/status', {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    _api.notifyChanged(const [ApiTopics.orders, ApiTopics.products, ApiTopics.notifications]);
  }
}
