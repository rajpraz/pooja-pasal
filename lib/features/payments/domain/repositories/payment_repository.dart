import 'package:pooja_pasal/features/payments/domain/entities/esewa_initiation.dart';
import 'package:pooja_pasal/features/payments/domain/entities/khalti_initiation.dart';

/// No payment is ever considered confirmed on the client — every method
/// here either asks the API to verify with the gateway server-to-server
/// (Khalti/eSewa) or records a seller/admin-confirmed Cash on Delivery
/// collection; only the API ever sets an order's `paymentStatus`.
abstract class PaymentRepository {
  /// Methods the server currently accepts (`cod`, `khalti`, `esewa`).
  Future<List<String>> availableMethods();

  /// Asks the backend to start a Khalti ePayment for this order (for the
  /// order's authoritative total, not a client-supplied amount) and
  /// returns the `pidx`/payment URL the checkout SDK opens.
  Future<KhaltiInitiation> initiateKhalti(String orderId);

  /// Verifies a Khalti payment by its `pidx` against Khalti's server-side
  /// lookup API. Only after this succeeds is the order's paymentStatus
  /// "paid" — the SDK's own payment result is never trusted.
  Future<void> verifyKhalti({required String orderId, required String pidx});

  /// Asks the backend to sign the eSewa checkout fields for this order
  /// (using the order's authoritative total, not a client-supplied
  /// amount), ready to build the redirect form.
  Future<EsewaInitiation> initiateEsewa(String orderId);

  /// Verifies an eSewa payment via eSewa's server-to-server status API
  /// after the buyer returns from the eSewa redirect.
  Future<void> verifyEsewa(String orderId);

  /// Seller/admin-only: marks a Cash on Delivery order's payment collected,
  /// only once it has actually been delivered.
  Future<void> confirmCodPayment(String orderId);
}
