import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/admin/orders/presentation/providers/admin_order_filter_provider.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

String _filterLabel(String? status) =>
    status == null ? 'All' : status[0].toUpperCase() + status.substring(1);

Color statusColor(String status) {
  switch (status) {
    case 'confirmed':
    case 'processing':
      return AppColors.khaltiPurple;
    case 'shipped':
      return AppColors.fonepayBlue;
    case 'delivered':
      return AppColors.success;
    case 'cancelled':
    case 'returned':
    case 'refunded':
      return AppColors.error;
    default:
      return AppColors.accent;
  }
}

/// Every order across every buyer, most recent 200 (bounded — see
/// `adminAllOrdersProvider`). Tap through to `AdminOrderDetailPage` for
/// full item/buyer/statusHistory detail and status changes.
class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminAllOrdersProvider);
    final activeFilter = ref.watch(adminOrderStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Orders')),
      body: ordersAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load orders: $err')),
        data: (allOrders) {
          if (allOrders.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders placed by buyers will show up here.',
            );
          }
          final orders = activeFilter == null
              ? allOrders
              : allOrders.where((o) => o.status == activeFilter).toList();

          return Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: adminOrderFilterTabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = adminOrderFilterTabs[index];
                    final selected = tab == activeFilter;
                    final count = tab == null
                        ? allOrders.length
                        : allOrders.where((o) => o.status == tab).length;
                    return ChoiceChip(
                      label: Text('${_filterLabel(tab)} ($count)'),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(adminOrderStatusFilterProvider.notifier)
                          .set(tab),
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                          color: selected ? AppColors.accent : AppColors.muted,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12),
                    );
                  },
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? EmptyView(
                        icon: Icons.filter_list_off,
                        title:
                            'No ${_filterLabel(activeFilter).toLowerCase()} orders',
                        subtitle: 'Try a different filter.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final PoojaOrder order = orders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                  'Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${order.items.length} item(s) • Rs.${order.totalAmount.toStringAsFixed(2)} • ${order.paymentStatus.toUpperCase()}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor(order.status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(order.status.toUpperCase(),
                                    style: TextStyle(
                                        color: statusColor(order.status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11)),
                              ),
                              onTap: () => context.push(
                                  RouteNames.adminOrderDetailPath(order.id)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
