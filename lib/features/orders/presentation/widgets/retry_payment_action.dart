import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/payments/presentation/khalti_checkout.dart';

/// True when a buyer abandoned/lost an online-payment attempt (backed out
/// of the Khalti screen, closed the app mid-eSewa-redirect, network drop
/// before `onSuccess` fired, a declined payment, etc.) and the order is
/// still unpaid. COD orders are intentionally excluded — "pending" is
/// their normal, expected state until delivery, not a stuck payment.
bool isStuckOnlinePayment(PoojaOrder order) {
  return (order.paymentMethod == 'khalti' || order.paymentMethod == 'esewa') &&
      const {'pending', 'processing', 'failed'}.contains(order.paymentStatus) &&
      !const {'cancelled', 'returned', 'refunded'}.contains(order.status);
}

/// Relaunches payment for an already-created order — never creates a new
/// order (that would defeat the idempotency key checkout already used).
/// Khalti: starts a fresh Khalti payment for the order's existing total
/// and verifies it exactly like checkout does ([payWithKhalti]). eSewa: pushes the same WebView
/// payment page checkout uses, keyed to the existing orderId.
class RetryPaymentButton extends ConsumerStatefulWidget {
  final PoojaOrder order;
  const RetryPaymentButton({super.key, required this.order});

  @override
  ConsumerState<RetryPaymentButton> createState() => _RetryPaymentButtonState();
}

class _RetryPaymentButtonState extends ConsumerState<RetryPaymentButton> {
  bool _busy = false;

  Future<void> _retryKhalti() async {
    setState(() => _busy = true);
    try {
      final paid = await payWithKhalti(context, ref, widget.order.id);
      if (!mounted || !paid) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment confirmed!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retryEsewa() async {
    setState(() => _busy = true);
    final paid =
        await context.push<bool>(RouteNames.esewaPaymentPath(widget.order.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (paid == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment confirmed!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _busy
            ? null
            : (widget.order.paymentMethod == 'khalti'
                ? _retryKhalti
                : _retryEsewa),
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.payment),
        label: Text(_busy ? 'Confirming...' : 'Complete Payment'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
      ),
    );
  }
}
