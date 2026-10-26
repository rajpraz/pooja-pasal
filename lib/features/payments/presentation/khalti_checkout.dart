import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:pooja_pasal/core/constants/khalti_config.dart';
import 'package:pooja_pasal/features/payments/presentation/providers/payment_providers.dart';

/// Pays for an existing order with Khalti: the backend starts the payment
/// (`initiateKhaltiPayment`, for the order's server-side total), the
/// khalti_checkout_flutter page collects it, and the backend then confirms
/// it with Khalti (`verifyKhaltiPayment`). Shared by checkout and the
/// "Complete Payment" retry on an order, so both behave identically.
///
/// Completes `true` once the backend has verified the payment, `false` if
/// the buyer closed the Khalti page without paying, and throws if starting
/// or verifying the payment failed. Nothing the SDK reports is trusted as
/// proof of payment — only the backend's verification.
Future<bool> payWithKhalti(
    BuildContext context, WidgetRef ref, String orderId) async {
  final payments = ref.read(paymentControllerProvider.notifier);
  final initiation = await payments.initiateKhalti(orderId);
  if (!context.mounted) return false;

  final result = Completer<bool>();
  var verifying = false;

  Future<void> verify(Khalti khalti) async {
    if (verifying || result.isCompleted) return;
    verifying = true;
    try {
      await payments.verifyKhalti(orderId: orderId, pidx: initiation.pidx);
      if (!result.isCompleted) result.complete(true);
    } catch (error, stackTrace) {
      if (!result.isCompleted) result.completeError(error, stackTrace);
    } finally {
      if (context.mounted) khalti.close(context);
    }
  }

  final khalti = await Khalti.init(
    payConfig: KhaltiPayConfig(
      publicKey: KhaltiKeys.publicKey,
      pidx: initiation.pidx,
      paymentUrl: initiation.paymentUrl,
      environment: KhaltiKeys.environment,
    ),
    onPaymentResult: (_, khalti) => verify(khalti),
    onMessage: (khalti,
        {description, statusCode, event, needsPaymentConfirmation}) async {
      if (needsPaymentConfirmation == true) {
        // The SDK couldn't confirm the result itself; our backend asks
        // Khalti directly either way.
        await verify(khalti);
        return;
      }
      if (event == KhaltiEvent.kpgDisposed) {
        // Page closed. While a verification is in flight, it decides.
        if (!verifying && !result.isCompleted) result.complete(false);
        return;
      }
      if (context.mounted) khalti.close(context);
      if (!verifying && !result.isCompleted) result.complete(false);
    },
  );
  if (!context.mounted) return false;
  khalti.open(context);
  return result.future;
}
