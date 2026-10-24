/// How a buyer pays for an order. [apiValue] is what `POST /orders` and
/// `GET /payment-methods` use.
enum PaymentMethod {
  khalti('khalti', 'Khalti'),
  esewa('esewa', 'eSewa'),
  cod('cod', 'Cash on Delivery');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Paid through a gateway before the order is fulfilled.
  bool get isOnline => this != PaymentMethod.cod;
}
