import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/seller/dashboard/domain/entities/seller_dashboard_stats.dart';

/// Derives dashboard stats purely from the two streams the dashboard
/// already watches (`sellerProductsProvider`, `sellerOrdersProvider`) — no
/// extra request. Recomputes whenever either source stream emits; cheap,
/// since both lists are already small per-seller sets held in memory by
/// their own providers.
///
/// "Sales" sums only this seller's own line items within each order (an
/// order can span multiple sellers — see OrderItem.sellerId). COD orders
/// count while pending (that revenue is real even before delivery-time
/// collection); khalti/esewa orders only count once `paymentStatus == 'paid'`
/// — an abandoned/failed online payment shouldn't inflate "sales". Any
/// `refunded`/`partially_refunded` paymentStatus is excluded regardless of
/// method, since that revenue was given back.
final sellerDashboardStatsProvider =
    Provider.family<AsyncValue<SellerDashboardStats>, String>((ref, sellerId) {
  final productsAsync = ref.watch(sellerProductsProvider(sellerId));
  final ordersAsync = ref.watch(sellerOrdersProvider(sellerId));

  if (productsAsync.isLoading || ordersAsync.isLoading) {
    return const AsyncLoading();
  }
  final error = productsAsync.error ?? ordersAsync.error;
  if (error != null) {
    return AsyncError(
        error, productsAsync.stackTrace ?? ordersAsync.stackTrace ?? StackTrace.empty);
  }

  final products = productsAsync.value ?? const [];
  final orders = ordersAsync.value ?? const [];
  final today = DateTime.now();

  var todaySales = 0.0;
  var totalSales = 0.0;
  var pending = 0, confirmed = 0, shipped = 0, delivered = 0;

  for (final order in orders) {
    switch (order.status) {
      case 'pending':
        pending++;
        break;
      case 'confirmed':
        confirmed++;
        break;
      case 'shipped':
        shipped++;
        break;
      case 'delivered':
        delivered++;
        break;
    }

    if (order.status == 'cancelled' || order.status == 'returned' || order.status == 'refunded') {
      continue;
    }
    if (order.paymentStatus == 'refunded' || order.paymentStatus == 'partially_refunded') continue;
    final isOnlinePayment = order.paymentMethod == 'khalti' || order.paymentMethod == 'esewa';
    if (isOnlinePayment && order.paymentStatus != 'paid') continue;

    final myTotal = order.items
        .where((item) => item.sellerId == sellerId)
        .fold<double>(0, (sum, item) => sum + item.price * item.qty);
    totalSales += myTotal;

    final createdAt = order.createdAt;
    if (createdAt != null &&
        createdAt.year == today.year &&
        createdAt.month == today.month &&
        createdAt.day == today.day) {
      todaySales += myTotal;
    }
  }

  return AsyncData(SellerDashboardStats(
    totalProducts: products.length,
    lowStockProducts: products.where((p) => p.isLowStock).length,
    pendingOrders: pending,
    confirmedOrders: confirmed,
    shippedOrders: shipped,
    deliveredOrders: delivered,
    todaySales: todaySales,
    totalSales: totalSales,
  ));
});
