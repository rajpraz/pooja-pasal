import 'package:pooja_pasal/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';

abstract class AdminDashboardRepository {
  Future<AdminDashboardStats> fetchStats();
}
