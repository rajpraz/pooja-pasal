import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/payments/domain/entities/esewa_initiation.dart';
import 'package:pooja_pasal/features/payments/domain/entities/khalti_initiation.dart';

/// Online payments through the API (`PaymentService` in Laravel). The
/// server starts each attempt for the order's own total and only marks the
/// order paid after confirming with the gateway itself; nothing the app
/// reports about success is trusted.
class PaymentRemoteDataSource {
  PaymentRemoteDataSource(this._api);

  final ApiClient _api;

  static const _changed = [ApiTopics.orders, ApiTopics.notifications];

  /// Payment methods the server currently accepts, e.g. `[cod, khalti]`.
  Future<List<String>> availableMethods() async {
    final data =
        (await _api.get('/payment-methods') as Map<String, dynamic>)['data'];
    return data is List
        ? data.map((e) => e.toString()).toList()
        : const ['cod'];
  }

  Future<KhaltiInitiation> initiateKhalti(String orderId) async {
    final data =
        await _api.post('/orders/$orderId/pay') as Map<String, dynamic>;
    _api.notifyChanged(_changed);
    return KhaltiInitiation.fromMap(data);
  }

  Future<void> verifyKhalti(
      {required String orderId, required String pidx}) async {
    await _verify(orderId, {'pidx': pidx});
  }

  Future<EsewaInitiation> initiateEsewa(String orderId) async {
    final data =
        await _api.post('/orders/$orderId/pay') as Map<String, dynamic>;
    _api.notifyChanged(_changed);
    return EsewaInitiation.fromMap(
        (data['esewa'] as Map?)?.cast<String, dynamic>() ?? const {});
  }

  Future<void> verifyEsewa(String orderId) => _verify(orderId, const {});

  /// Asks the server to re-check the attempt with the gateway. Throws when
  /// the order still isn't paid, so callers never report success early.
  Future<void> _verify(String orderId, Map<String, dynamic> body) async {
    final order =
        asJsonMap(await _api.post('/orders/$orderId/verify-payment', body));
    _api.notifyChanged(_changed);
    switch (order['paymentStatus']) {
      case 'paid':
        return;
      case 'failed':
        throw const AppFunctionException(
            'failed-precondition', 'The payment was cancelled or failed.');
      default:
        throw const AppFunctionException('failed-precondition',
            "The payment hasn't been confirmed yet. Please try again in a moment.");
    }
  }

  Future<void> confirmCodPayment(String orderId) async {
    await _api.post('/orders/$orderId/confirm-cod');
    _api.notifyChanged(_changed);
  }
}
