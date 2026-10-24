class AdminDashboardStats {
  final int totalUsers;
  final int totalSellers;
  final int pendingSellerApplications;
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;

  /// Revenue from paid orders placed in the last 30 days.
  final double recentRevenue;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.totalSellers = 0,
    this.pendingSellerApplications = 0,
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.lowStockProducts = 0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.confirmedOrders = 0,
    this.processingOrders = 0,
    this.shippedOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.recentRevenue = 0,
  });
}
