import 'package:pooja_pasal/core/network/json_reader.dart';

class SellerApplication {
  final String uid;
  final String name;
  final String email;
  final String shopName;
  final String phone;
  final String reason;
  final String status; // pending | approved | rejected
  final String? rejectionReason;
  final DateTime? createdAt;

  const SellerApplication({
    required this.uid,
    this.name = '',
    this.email = '',
    required this.shopName,
    required this.phone,
    required this.reason,
    required this.status,
    this.rejectionReason,
    this.createdAt,
  });

  factory SellerApplication.fromJson(Map<String, dynamic> map) {
    return SellerApplication(
      uid: map.str('uid'),
      name: map.str('name'),
      email: map.str('email'),
      shopName: map.str('shopName'),
      phone: map.str('phone'),
      reason: map.str('reason'),
      status: map.str('status', 'pending'),
      rejectionReason: map.strOrNull('rejectionReason'),
      createdAt: map.date('createdAt'),
    );
  }
}
