import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/admin/dashboard/data/datasources/admin_dashboard_data_source.dart';
import 'package:pooja_pasal/features/admin/dashboard/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:pooja_pasal/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';
import 'package:pooja_pasal/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepositoryImpl(
      AdminDashboardDataSource(ref.watch(apiClientProvider)));
});

/// Dashboard counts (computed in SQL by the API). Re-fetched whenever the
/// admin changes something they summarise — approving a seller, moving an
/// order, toggling a product — and on pull-to-refresh.
final adminDashboardStatsProvider =
    StreamProvider.autoDispose<AdminDashboardStats>((ref) {
  final repository = ref.watch(adminDashboardRepositoryProvider);
  return ref.watch(apiClientProvider).watch(
    {
      ApiTopics.orders,
      ApiTopics.users,
      ApiTopics.sellerApplications,
      ApiTopics.products
    },
    repository.fetchStats,
    pollEvery: const Duration(minutes: 1),
  );
});
