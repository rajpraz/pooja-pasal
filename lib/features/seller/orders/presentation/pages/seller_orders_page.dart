import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/payments/presentation/providers/payment_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Local UI-only filter over the already-loaded `sellerOrdersProvider`
/// stream — a seller's order volume doesn't warrant a request per filter
/// tab.
class _SellerOrderStatusFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? status) => state = status;
}

final _sellerOrderStatusFilterProvider =
    NotifierProvider.autoDispose<_SellerOrderStatusFilter, String?>(_SellerOrderStatusFilter.new);

const _filterTabs = <String?>[
  null,
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled'
];

String _filterLabel(String? status) =>
    status == null ? 'All' : status[0].toUpperCase() + status.substring(1);

/// Embeddable body (no own Scaffold/AppBar) showing orders that contain at
/// least one of this seller's products, with the ability to advance status
/// or cancel. Status changes, cancellation, and Cash-on-Delivery payment
/// confirmation go through the API (see order_providers.dart and
/// payment_providers.dart), which validates the transition/ownership in
/// `OrderService` and notifies the buyer itself.
///
/// A seller only ever sees their own line items and the buyer's shipping
/// address for fulfillment purposes — the API's seller order endpoints
/// return only that seller's lines of a multi-seller order (and the
/// `item.sellerId == uid` filter below keeps it that way regardless).
class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

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

  String? _nextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'processing';
      case 'processing':
        return 'shipped';
      case 'shipped':
        return 'delivered';
      default:
        return null;
    }
  }

  /// Mirrors the API's seller cancel window (`OrderService`):
  /// pending/confirmed/processing only, never once shipped.
  bool _canCancel(String status) =>
      status == 'pending' || status == 'confirmed' || status == 'processing';

  Future<void> _advanceStatus(BuildContext context, WidgetRef ref, PoojaOrder order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;
    try {
      await ref
          .read(orderControllerProvider.notifier)
          .updateStatus(orderId: order.id, status: next);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $next')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, PoojaOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Text(
            'Order #${order.id.substring(0, order.id.length.clamp(0, 8))} will be cancelled and the buyer notified. This can\'t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep order')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Cancel order', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(orderControllerProvider.notifier)
          .cancelOrder(order.id, note: 'Cancelled by seller');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _confirmCodPayment(BuildContext context, WidgetRef ref, PoojaOrder order) async {
    try {
      await ref.read(paymentControllerProvider.notifier).confirmCodPayment(order.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment collection confirmed')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }
    final ordersAsync = ref.watch(sellerOrdersProvider(uid));
    final isBusy = ref.watch(orderControllerProvider).isLoading ||
        ref.watch(paymentControllerProvider).isLoading;
    final activeFilter = ref.watch(_sellerOrderStatusFilterProvider);

    return ordersAsync.when(
      loading: () => const LoadingView(),
      error: (err, st) => Center(child: Text('Could not load orders: $err')),
      data: (allOrders) {
        if (allOrders.isEmpty) {
          return const EmptyView(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            subtitle: 'Orders containing your products will show up here.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _filterTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _filterTabs[index];
                  final selected = tab == activeFilter;
                  final count = tab == null
                      ? allOrders.length
                      : allOrders.where((o) => o.status == tab).length;
                  return ChoiceChip(
                    label: Text('${_filterLabel(tab)} ($count)'),
                    selected: selected,
                    onSelected: (_) => ref.read(_sellerOrderStatusFilterProvider.notifier).set(tab),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                        color: selected ? AppColors.accent : AppColors.muted,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12),
                  );
                },
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? EmptyView(
                      icon: Icons.filter_list_off,
                      title: 'No ${_filterLabel(activeFilter).toLowerCase()} orders',
                      subtitle: 'Try a different filter.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final myItems = order.items.where((item) => item.sellerId == uid).toList();
                        // An unpaid Khalti/eSewa order is confirmed by its
                        // payment verification, not by the seller.
                        final awaitingPayment =
                            (order.paymentMethod == 'khalti' || order.paymentMethod == 'esewa') &&
                                order.paymentStatus != 'paid';
                        final next = awaitingPayment && order.status == 'pending'
                            ? null
                            : _nextStatus(order.status);
                        final canCancel = _canCancel(order.status);
                        final needsCodConfirmation = order.paymentMethod == 'cod' &&
                            order.status == 'delivered' &&
                            order.paymentStatus != 'paid';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          'Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                const SizedBox(height: 8),
                                for (final item in myItems)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                        '${item.name} × ${item.qty} — Rs.${(item.price * item.qty).toStringAsFixed(0)}'),
                                  ),
                                const SizedBox(height: 6),
                                Text('Ship to: ${order.shippingAddress}',
                                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                Text(
                                    'Payment: ${order.paymentMethod.toUpperCase()} • ${order.paymentStatus.toUpperCase()}',
                                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                if (next != null) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed:
                                          isBusy ? null : () => _advanceStatus(context, ref, order),
                                      child: Text(
                                          'Mark as ${next[0].toUpperCase()}${next.substring(1)}'),
                                    ),
                                  ),
                                ],
                                if (needsCodConfirmation) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: isBusy
                                          ? null
                                          : () => _confirmCodPayment(context, ref, order),
                                      child: const Text('Confirm Cash Payment Collected'),
                                    ),
                                  ),
                                ],
                                if (canCancel) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed:
                                          isBusy ? null : () => _confirmCancel(context, ref, order),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                      child: const Text('Cancel Order'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
