import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/notifications/domain/entities/app_notification.dart';
import 'package:pooja_pasal/features/notifications/presentation/providers/notification_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  /// Covers every notification `type` the API emits (`NotificationService`:
  /// order_placed, order_<status>, payment_success/failure/refunded,
  /// seller_new_order, low_stock/out_of_stock, seller_application,
  /// refund_needed) — the map is shared since sellers and admins use this
  /// same page.
  IconData _iconFor(String type) {
    switch (type) {
      case 'order_placed':
        return Icons.receipt_long_outlined;
      case 'order_confirmed':
        return Icons.check_circle_outline;
      case 'order_processing':
        return Icons.settings_outlined;
      case 'order_shipped':
        return Icons.local_shipping_outlined;
      case 'order_delivered':
        return Icons.task_alt_outlined;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'order_returned':
        return Icons.assignment_return_outlined;
      case 'order_refunded':
        return Icons.currency_exchange_outlined;
      case 'payment_success':
        return Icons.check_circle_outline;
      case 'payment_failure':
        return Icons.error_outline;
      case 'payment_refunded':
      case 'refund_needed':
        return Icons.currency_exchange_outlined;
      case 'seller_application':
        return Icons.how_to_reg_outlined;
      case 'seller_new_order':
        return Icons.storefront_outlined;
      case 'low_stock':
        return Icons.warning_amber_outlined;
      case 'out_of_stock':
        return Icons.remove_shopping_cart_outlined;
      case 'offer':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'order_cancelled':
      case 'payment_failure':
      case 'out_of_stock':
        return AppColors.error;
      case 'low_stock':
        return AppColors.accent;
      case 'order_delivered':
      case 'payment_success':
      case 'payment_refunded':
        return AppColors.success;
      case 'refund_needed':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _onTap(
      BuildContext context, WidgetRef ref, String uid, AppNotification n) {
    if (!n.read) {
      ref.read(notificationRepositoryProvider).markRead(uid, n.id);
    }
    if (n.orderId != null && n.orderId!.isNotEmpty) {
      context.push(RouteNames.orderTrackingPath(n.orderId!));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: uid == null
          ? const Center(child: Text('Please log in to view notifications'))
          : ref.watch(notificationsProvider(uid)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) =>
                    Center(child: Text('Could not load notifications: $err')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 56, color: AppColors.muted),
                          const SizedBox(height: 12),
                          const Text('No notifications yet',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Order updates and offers will show up here.',
                              style: TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _onTap(context, ref, uid, n),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.read ? AppColors.surface : AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.surface,
                                child: Icon(_iconFor(n.type),
                                    color: _colorFor(n.type), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(n.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        if (!n.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n.body,
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Text(_timeAgo(n.createdAt),
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
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
