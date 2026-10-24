import 'package:pooja_pasal/features/admin/dashboard/data/datasources/admin_dashboard_data_source.dart';
import 'package:pooja_pasal/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';
import 'package:pooja_pasal/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminDashboardDataSource _dataSource;

  AdminDashboardRepositoryImpl(this._dataSource);

  @override
  Future<AdminDashboardStats> fetchStats() => _dataSource.fetchStats();
}
