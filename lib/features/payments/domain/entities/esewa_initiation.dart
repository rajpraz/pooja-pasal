/// Signed eSewa ePay v2 form fields for one payment attempt, produced by
/// the API from the order's authoritative total (`POST /orders/{id}/pay`).
class EsewaInitiation {
  final String formUrl;
  final String productCode;
  final String totalAmount;
  final String transactionUuid;
  final String signature;
  final String signedFieldNames;
  final String successUrl;
  final String failureUrl;

  const EsewaInitiation({
    required this.formUrl,
    required this.productCode,
    required this.totalAmount,
    required this.transactionUuid,
    required this.signature,
    required this.signedFieldNames,
    required this.successUrl,
    required this.failureUrl,
  });

  factory EsewaInitiation.fromMap(Map<String, dynamic> map) => EsewaInitiation(
        formUrl: map['formUrl'] as String? ?? '',
        productCode: map['productCode'] as String? ?? '',
        totalAmount: map['totalAmount'] as String? ?? '0',
        transactionUuid: map['transactionUuid'] as String? ?? '',
        signature: map['signature'] as String? ?? '',
        signedFieldNames: map['signedFieldNames'] as String? ?? '',
        successUrl: map['successUrl'] as String? ?? '',
        failureUrl: map['failureUrl'] as String? ?? '',
      );
}
