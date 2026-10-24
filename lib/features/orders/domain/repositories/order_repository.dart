import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';

abstract class OrderRepository {
  Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId);

  Stream<List<PoojaOrder>> streamSellerOrders(String sellerId);

  Stream<PoojaOrder?> streamOrder(String orderId);

  /// Admin-only: every order across every buyer, most recent first,
  /// bounded (not the whole table).
  Stream<List<PoojaOrder>> streamAllOrders({int limit});

  /// Creates an order through the API — the server re-reads product
  /// price/stock/seller and computes the authoritative total; nothing here
  /// decides pricing. [idempotencyKey] should be generated once per
  /// checkout attempt (not per network call) by the caller, so a retry
  /// after a timeout reuses the same key and can't create a duplicate.
  Future<CreateOrderResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
    String? couponCode,
  });

  /// Requests a status change; the backend validates whether the
  /// transition is allowed for the caller's role and the order's current
  /// status and throws if it isn't.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  });

  Future<void> cancelOrder(String orderId, {String? note});

  /// Admin: records a payment's state — typically `refunded` once money for
  /// a cancelled or returned order was sent back from the gateway's
  /// dashboard.
  Future<void> updatePaymentStatus({required String orderId, required String paymentStatus});
}
