/// Pure aggregation over already-fetched seller product/order streams —
/// no extra request.
class SellerDashboardStats {
  final int totalProducts;
  final int lowStockProducts;
  final int pendingOrders;
  final int confirmedOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final double todaySales;
  final double totalSales;

  const SellerDashboardStats({
    this.totalProducts = 0,
    this.lowStockProducts = 0,
    this.pendingOrders = 0,
    this.confirmedOrders = 0,
    this.shippedOrders = 0,
    this.deliveredOrders = 0,
    this.todaySales = 0,
    this.totalSales = 0,
  });
}
