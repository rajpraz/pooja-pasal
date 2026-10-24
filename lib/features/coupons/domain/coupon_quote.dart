/// A coupon the API accepted for a given subtotal, and what it takes off.
class CouponQuote {
  final String code;
  final double discount;

  const CouponQuote({required this.code, required this.discount});
}
