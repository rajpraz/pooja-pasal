import 'package:pooja_pasal/core/network/json_reader.dart';

class Address {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final bool isDefault;
  final DateTime? createdAt;

  const Address({
    this.id = '',
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    this.isDefault = false,
    this.createdAt,
  });

  /// One-line summary used wherever a plain string address is needed (e.g.
  /// the `shippingAddress` sent to `createOrder`).
  String get formatted => '$recipientName, $fullAddress, $phone';

  factory Address.fromJson(Map<String, dynamic> map) {
    return Address(
      id: map.str('id'),
      label: map.str('label'),
      recipientName: map.str('recipientName'),
      phone: map.str('phone'),
      fullAddress: map.str('fullAddress'),
      isDefault: map.flag('isDefault'),
      createdAt: map.date('createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'recipientName': recipientName,
      'phone': phone,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
    };
  }

  Address copyWith(
      {String? label,
      String? recipientName,
      String? phone,
      String? fullAddress,
      bool? isDefault}) {
    return Address(
      id: id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}
