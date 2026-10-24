import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/admin/orders/presentation/pages/admin_orders_page.dart'
    show statusColor;
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Mirrors the API's `Order::TRANSITIONS` exactly — this is a UI hint for
/// which buttons to offer, not the authority; every tap still goes through
/// `OrderController.updateStatus` (`PATCH /orders/{id}/status`), where
/// `OrderService` re-validates the move (admins may make any valid move)
/// and keeps restocking/status history consistent.
const Map<String, List<String>> _adminNextStatuses = {
  'pending': ['confirmed', 'cancelled'],
  'confirmed': ['processing', 'cancelled'],
  'processing': ['shipped', 'cancelled'],
  'shipped': ['delivered', 'returned'],
  'delivered': ['returned'],
  'cancelled': [],
  'returned': ['refunded'],
  'refunded': [],
};

class AdminOrderDetailPage extends ConsumerWidget {
  final String orderId;

  const AdminOrderDetailPage({super.key, required this.orderId});

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, String orderId, String to) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Mark order as $to?'),
        content: Text(to == 'cancelled' || to == 'returned' || to == 'refunded'
            ? 'This may restore reserved stock and cannot be undone.'
            : 'The buyer will be notified of this change.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Confirm', style: TextStyle(color: statusColor(to))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(orderControllerProvider.notifier)
          .updateStatus(orderId: orderId, status: to, note: 'Updated by admin');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked as $to.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  /// Paid, but the order won't be fulfilled: the money has to go back.
  static bool _needsRefundRecord(PoojaOrder order) =>
      order.paymentStatus == 'paid' && (order.status == 'cancelled' || order.status == 'returned');

  Future<void> _markRefunded(BuildContext context, WidgetRef ref, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record refund?'),
        content: const Text(
            'Only do this once the money has been sent back to the buyer. The buyer is notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mark refunded')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(orderControllerProvider.notifier)
          .updatePaymentStatus(orderId: orderId, paymentStatus: 'refunded');
      if (context.mounted) showMessage(context, 'Refund recorded.');
    } catch (e) {
      if (context.mounted) showMessage(context, friendlyErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    final isBusy = ref.watch(orderControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load order: $err')),
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));
          final nextOptions = _adminNextStatuses[order.status] ?? const [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(order.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor(order.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Rs.${order.totalAmount.toStringAsFixed(2)} • ${order.items.length} item(s)',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Payment: ${order.paymentMethod.toUpperCase()} • ${order.paymentStatus.toUpperCase()}',
                          style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Text('Placed: ${order.createdAt?.toString().substring(0, 16) ?? '—'}',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('Shipping to: ${order.shippingAddress}',
                          style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.name} × ${item.qty}'
                            '${item.sellerName.isNotEmpty ? ' (${item.sellerName})' : ''}'),
                      ),
                      Text('Rs.${(item.price * item.qty).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Status history', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (order.statusHistory.isEmpty)
                Text('No history recorded.', style: TextStyle(color: AppColors.muted))
              else
                for (final entry in order.statusHistory)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: statusColor(entry.status)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.status.toUpperCase()),
                              // e.g. the buyer's return reason.
                              if (entry.note.isNotEmpty)
                                Text(entry.note,
                                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(entry.timestamp?.toString().substring(0, 16) ?? '',
                            style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
              if (_needsRefundRecord(order)) ...[
                const SizedBox(height: 20),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    'This order was paid but is ${order.status}. After refunding it from the '
                    '${order.paymentMethod.toUpperCase()} dashboard, record it here.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _markRefunded(context, ref, order.id),
                  icon: const Icon(Icons.currency_exchange, size: 18),
                  label: const Text('Mark payment refunded'),
                ),
              ],
              if (nextOptions.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Change status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in nextOptions)
                      OutlinedButton(
                        onPressed:
                            isBusy ? null : () => _changeStatus(context, ref, order.id, option),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: statusColor(option),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                        child: Text('Mark as ${option[0].toUpperCase()}${option.substring(1)}'),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
