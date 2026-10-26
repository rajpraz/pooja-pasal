import 'package:pooja_pasal/core/network/json_reader.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int qty;
  final String sellerId;
  final String sellerName;
  final String image;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.sellerId,
    this.sellerName = '',
    this.image = '',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map.str('productId'),
      name: map.str('name'),
      price: map.dbl('price'),
      qty: map.integer('qty', 1),
      sellerId: map.str('sellerId'),
      sellerName: map.str('sellerName'),
      image: map.str('image'),
    );
  }
}

/// Fulfillment status of the order itself. Kept strictly separate from
/// [paymentStatuses] — an order can be `confirmed` while still
/// `paymentStatus: pending` (e.g. Cash on Delivery), and payment can be
/// `paid` while the order is still `processing`.
const List<String> orderStatuses = [
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
  'returned',
  'refunded',
];

/// Payment lifecycle, independent of [orderStatuses]. Mirrors
/// `Order::PAYMENT_STATUSES` in the Laravel API — keep both in sync.
const List<String> paymentStatuses = [
  'pending',
  'processing',
  'paid',
  'failed',
  'refunded',
  'partially_refunded',
];

class StatusHistoryEntry {
  final String status;
  final DateTime? timestamp;
  final String changedBy;
  final String note;

  const StatusHistoryEntry({
    required this.status,
    required this.changedBy,
    this.timestamp,
    this.note = '',
  });

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: map.str('status'),
      changedBy: map.str('changedBy'),
      note: map.str('note'),
      timestamp: map.date('timestamp'),
    );
  }
}

class PoojaOrder {
  final String id;
  final String buyerId;
  final List<String> sellerIds;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentRef;
  final String shippingAddress;
  final List<StatusHistoryEntry> statusHistory;
  final DateTime? createdAt;
  final String? couponCode;

  const PoojaOrder({
    required this.id,
    required this.buyerId,
    required this.sellerIds,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discount = 0,
    this.tax = 0,
    this.paymentStatus = 'pending',
    this.paymentMethod = 'cod',
    this.paymentRef,
    this.statusHistory = const [],
    this.createdAt,
    this.couponCode,
  });

  factory PoojaOrder.fromJson(Map<String, dynamic> map) {
    return PoojaOrder(
      id: map.str('id'),
      buyerId: map.str('buyerId'),
      sellerIds: map.strings('sellerIds'),
      items: map.objects('items').map(OrderItem.fromMap).toList(),
      subtotal: map.dbl('subtotal'),
      deliveryFee: map.dbl('deliveryFee'),
      discount: map.dbl('discount'),
      tax: map.dbl('tax'),
      totalAmount: map.dbl('totalAmount'),
      status: map.str('status', 'pending'),
      paymentStatus: map.str('paymentStatus', 'pending'),
      paymentMethod: map.str('paymentMethod', 'cod'),
      paymentRef: map.strOrNull('paymentRef'),
      shippingAddress: map.str('shippingAddress'),
      statusHistory:
          map.objects('statusHistory').map(StatusHistoryEntry.fromMap).toList(),
      createdAt: map.date('createdAt'),
      couponCode: map.strOrNull('couponCode'),
    );
  }
}

/// Result of `POST /orders` — carries the server-computed authoritative
/// total back to the client (e.g. so checkout can show what COD will cost).
class CreateOrderResult {
  final String orderId;
  final double totalAmount;
  final bool deduplicated;

  const CreateOrderResult({
    required this.orderId,
    required this.totalAmount,
    required this.deduplicated,
  });
}
