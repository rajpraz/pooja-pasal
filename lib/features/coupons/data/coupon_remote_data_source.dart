import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/coupons/domain/coupon_quote.dart';

/// Checks a coupon code against a subtotal (`POST /coupons/validate`). The
/// API re-validates and applies it again when the order is placed, so this
/// is only a preview of the discount.
class CouponRemoteDataSource {
  CouponRemoteDataSource(this._api);

  final ApiClient _api;

  Future<CouponQuote> validate(String code, double subtotal) async {
    final data = await _api.post('/coupons/validate', {'code': code, 'subtotal': subtotal})
        as Map<String, dynamic>;
    return CouponQuote(
      code: data['code'] as String? ?? code.toUpperCase(),
      discount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
