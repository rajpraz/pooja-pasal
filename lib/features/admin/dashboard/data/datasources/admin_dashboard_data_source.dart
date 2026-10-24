import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';

/// Admin dashboard counts, computed in SQL by `GET /admin/dashboard`.
class AdminDashboardDataSource {
  AdminDashboardDataSource(this._api);

  final ApiClient _api;

  Future<AdminDashboardStats> fetchStats() async {
    final data = asJsonMap(await _api.get('/admin/dashboard'));
    int count(String key) => (data[key] as num?)?.toInt() ?? 0;
    return AdminDashboardStats(
      totalUsers: count('totalUsers'),
      totalSellers: count('totalSellers'),
      pendingSellerApplications: count('pendingSellerApplications'),
      totalProducts: count('totalProducts'),
      activeProducts: count('activeProducts'),
      lowStockProducts: count('lowStockProducts'),
      totalOrders: count('totalOrders'),
      pendingOrders: count('pendingOrders'),
      confirmedOrders: count('confirmedOrders'),
      processingOrders: count('processingOrders'),
      shippedOrders: count('shippedOrders'),
      deliveredOrders: count('deliveredOrders'),
      cancelledOrders: count('cancelledOrders'),
      recentRevenue: (data['recentRevenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
