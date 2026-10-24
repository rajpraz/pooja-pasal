/// A Khalti ePayment started server-side by `initiateKhaltiPayment` for an
/// order's authoritative total — what the checkout SDK needs to open.
class KhaltiInitiation {
  final String pidx;
  final String paymentUrl;

  const KhaltiInitiation({required this.pidx, required this.paymentUrl});

  factory KhaltiInitiation.fromMap(Map<String, dynamic> map) => KhaltiInitiation(
        pidx: map['pidx'] as String? ?? '',
        paymentUrl: map['paymentUrl'] as String? ?? '',
      );
}
