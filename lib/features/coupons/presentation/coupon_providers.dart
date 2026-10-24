import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/coupons/data/coupon_remote_data_source.dart';

final couponDataSourceProvider = Provider<CouponRemoteDataSource>((ref) {
  return CouponRemoteDataSource(ref.watch(apiClientProvider));
});
