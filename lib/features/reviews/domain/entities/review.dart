import 'package:pooja_pasal/core/network/json_reader.dart';

class Review {
  final String id;
  final String productId;
  final String orderId;
  final String buyerId;
  final String buyerName;
  final int rating;
  final String text;
  final List<String> images;
  final bool verifiedPurchase;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.buyerId,
    this.buyerName = '',
    required this.rating,
    required this.text,
    this.images = const [],
    this.verifiedPurchase = false,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> map) {
    return Review(
      id: map.str('id'),
      productId: map.str('productId'),
      orderId: map.str('orderId'),
      buyerId: map.str('buyerId'),
      buyerName: map.str('buyerName'),
      rating: map.integer('rating'),
      text: map.str('text'),
      images: map.strings('images'),
      verifiedPurchase: map.flag('verifiedPurchase'),
      createdAt: map.date('createdAt'),
    );
  }
}
