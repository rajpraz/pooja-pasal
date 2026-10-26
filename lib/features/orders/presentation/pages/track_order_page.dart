import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/orders/presentation/widgets/reorder_action.dart';
import 'package:pooja_pasal/features/orders/presentation/widgets/retry_payment_action.dart';
import 'package:pooja_pasal/features/reviews/presentation/widgets/review_dialog.dart';

class TrackOrderStep {
  final String title;
  final bool done;
  final bool isCurrent;
  final DateTime? timestamp;

  const TrackOrderStep(
      {required this.title,
      this.done = false,
      this.isCurrent = false,
      this.timestamp});
}

/// The API's state machine (`Order::TRANSITIONS`) only supports these
/// statuses — deliberately does NOT include an "out for delivery" step,
/// since the backend has no such status and inventing one client-side
/// would show a step that never really completes.
const _forwardStatuses = [
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'delivered'
];
const _forwardTitles = {
  'pending': 'Order Placed',
  'confirmed': 'Order Confirmed',
  'processing': 'Processing',
  'shipped': 'Order Shipped',
  'delivered': 'Delivered',
};

List<TrackOrderStep> _stepsForOrder(PoojaOrder order) {
  DateTime? timestampFor(String status) {
    for (final entry in order.statusHistory) {
      if (entry.status == status) return entry.timestamp;
    }
    return null;
  }

  if (order.status == 'cancelled') {
    return [
      TrackOrderStep(
          title: 'Order Placed', done: true, timestamp: order.createdAt),
      TrackOrderStep(
          title: 'Cancelled',
          done: true,
          isCurrent: true,
          timestamp: timestampFor('cancelled')),
    ];
  }
  if (order.status == 'returned' || order.status == 'refunded') {
    return [
      TrackOrderStep(
          title: 'Delivered', done: true, timestamp: timestampFor('delivered')),
      TrackOrderStep(
          title: order.status == 'refunded' ? 'Refunded' : 'Return Requested',
          done: true,
          isCurrent: true,
          timestamp: timestampFor(order.status)),
    ];
  }

  final currentIndex = _forwardStatuses
      .indexOf(order.status)
      .clamp(0, _forwardStatuses.length - 1);
  return [
    for (int i = 0; i < _forwardStatuses.length; i++)
      TrackOrderStep(
        title: _forwardTitles[_forwardStatuses[i]]!,
        done: i <= currentIndex,
        isCurrent: i == currentIndex,
        timestamp: i == 0
            ? (timestampFor(_forwardStatuses[i]) ?? order.createdAt)
            : timestampFor(_forwardStatuses[i]),
      ),
  ];
}

class TrackOrderPage extends ConsumerWidget {
  final String orderId;

  const TrackOrderPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Tracking')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load order: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _OrderTrackBody(order: order);
        },
      ),
    );
  }
}

class _OrderTrackBody extends ConsumerWidget {
  final PoojaOrder order;
  const _OrderTrackBody({required this.order});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return time.toString().substring(0, 16);
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
            'This can\'t be undone. Any stock reserved for it will be released.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep Order')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                Text('Cancel Order', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(orderControllerProvider.notifier).cancelOrder(order.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order cancelled.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  /// Asks why, then moves the delivered order to `returned` (the API
  /// restocks it and lets the seller and admin know).
  Future<void> _requestReturn(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request a return?'),
        content: TextField(
          controller: reason,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'What went wrong? (damaged, wrong item…)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Request Return')),
        ],
      ),
    );
    final note = reason.text.trim();
    reason.dispose();
    if (submitted != true || !context.mounted) return;
    try {
      await ref.read(orderControllerProvider.notifier).updateStatus(
            orderId: order.id,
            status: 'returned',
            note: note.isEmpty ? 'Return requested by buyer' : note,
          );
      if (context.mounted)
        showMessage(context, 'Return requested. The seller will be in touch.');
    } catch (e) {
      if (context.mounted) showMessage(context, friendlyErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = _stepsForOrder(order);
    final placedOn = order.createdAt == null
        ? ''
        : 'Placed on ${_formatTime(order.createdAt)}';
    // Matches the API's OrderService: a buyer may only cancel while the
    // order is still pending (before a seller starts fulfilling it) — the
    // backend rejects any other attempt, so the button is hidden rather
    // than offered and failed.
    final canCancel = order.status == 'pending';
    // Returns open once the order is delivered (OrderService allows the
    // buyer `delivered → returned` only).
    final canReturn = order.status == 'delivered';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Text(
              'Order ID: #${order.id.substring(0, order.id.length.clamp(0, 8))}',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          Text(placedOn,
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
              'Rs.${order.totalAmount.toStringAsFixed(2)} • ${order.items.length} item(s)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          // How the total adds up, so a coupon or delivery fee is never a surprise.
          Text(
              [
                'Items Rs.${order.subtotal.toStringAsFixed(2)}',
                if (order.discount > 0)
                  '${order.couponCode == null ? 'Discount' : 'Coupon ${order.couponCode}'} −Rs.${order.discount.toStringAsFixed(2)}',
                'Delivery Rs.${order.deliveryFee.toStringAsFixed(2)}',
              ].join(' • '),
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
              'Payment: ${order.paymentMethod.toUpperCase()} • ${order.paymentStatus.toUpperCase()}',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Shipping to: ${order.shippingAddress}',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 26),
          for (int i = 0; i < steps.length; i++)
            _buildStep(steps[i], i == steps.length - 1),
          const SizedBox(height: 12),
          if (isStuckOnlinePayment(order)) ...[
            RetryPaymentButton(order: order),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (canCancel)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(context, ref),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error),
                    child: const Text('Cancel Order'),
                  ),
                ),
              if (canCancel) const SizedBox(width: 10),
              if (canReturn)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _requestReturn(context, ref),
                    child: const Text('Request Return'),
                  ),
                ),
              if (canReturn) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => reorder(context, ref, order),
                  child: const Text('Reorder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item.name} × ${item.qty}')),
                  Text('Rs.${(item.price * item.qty).toStringAsFixed(2)}'),
                  if (order.status == 'delivered') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => showReviewDialog(context, ref,
                          orderId: order.id, item: item),
                      child: const Text('Review'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  static const _negativeTitles = {'Cancelled', 'Return Requested', 'Refunded'};

  Widget _buildStep(TrackOrderStep step, bool isLast) {
    final isNegative = _negativeTitles.contains(step.title);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? (isNegative ? AppColors.error : AppColors.success)
                      : AppColors.border,
                ),
                child: step.done
                    ? Icon(isNegative ? Icons.close : Icons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: step.done ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 26.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: step.done ? AppColors.text : AppColors.muted,
                  ),
                ),
                if (step.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_formatTime(step.timestamp),
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
