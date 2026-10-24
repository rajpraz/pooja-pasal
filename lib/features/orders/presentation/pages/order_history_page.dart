import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  Color _statusColor(String status) {
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

  Color _paymentColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'refunded':
      case 'partially_refunded':
        return AppColors.muted;
      default:
        return AppColors.accent;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view your orders')));
    }
    final ordersAsync = ref.watch(buyerOrdersProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load orders: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders you place will show up here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push(RouteNames.orderTrackingPath(order.id)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(order.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(order.status.toUpperCase(),
                                  style: TextStyle(
                                      color: _statusColor(order.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                            '${order.items.length} item(s) • Rs.${order.totalAmount.toStringAsFixed(2)}'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(_formatDate(order.createdAt),
                                style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            const Spacer(),
                            Icon(Icons.circle, size: 6, color: _paymentColor(order.paymentStatus)),
                            const SizedBox(width: 4),
                            Text(
                                'Payment: ${order.paymentStatus.replaceAll('_', ' ').toUpperCase()}',
                                style: TextStyle(
                                    color: _paymentColor(order.paymentStatus),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
