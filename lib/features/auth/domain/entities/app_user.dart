import 'package:pooja_pasal/core/network/json_reader.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'buyer' | 'seller' | 'admin'
  final String address;
  final String photoUrl;
  final DateTime? createdAt;

  /// Status of this account's seller application (`pending`, `approved`,
  /// `rejected`), or null when it never applied.
  final String? sellerStatus;
  final String? shopName;
  final bool isActive;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.address,
    this.photoUrl = '',
    this.createdAt,
    this.sellerStatus,
    this.shopName,
    this.isActive = true,
    this.emailVerified = false,
  });

  bool get isSeller => role == 'seller';
  bool get isAdmin => role == 'admin';
  bool get hasPendingSellerApplication => sellerStatus == 'pending';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json.str('id'),
      name: json.str('name'),
      email: json.str('email'),
      phone: json.str('phone'),
      role: json.str('role', 'buyer'),
      address: json.str('address'),
      photoUrl: json.str('photoUrl'),
      createdAt: json.date('createdAt'),
      sellerStatus: json.strOrNull('sellerStatus'),
      shopName: json.strOrNull('shopName'),
      isActive: json.flag('isActive', true),
      emailVerified: json.flag('emailVerified'),
    );
  }
}
