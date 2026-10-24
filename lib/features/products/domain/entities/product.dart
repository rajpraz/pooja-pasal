import 'package:pooja_pasal/core/network/json_reader.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final int stock;
  final String sellerId;
  final String sellerName;
  final DateTime? createdAt;
  final bool isActive;
  final String festivalTag;
  final double ratingAverage;
  final int ratingCount;
  final int lowStockThreshold;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.stock,
    required this.sellerId,
    this.sellerName = '',
    required this.isActive,
    this.createdAt,
    this.festivalTag = '',
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.lowStockThreshold = 5,
  });

  /// Same threshold check as the API's low-stock notification
  /// (`NotificationService::stockChanged`), so the seller-facing badge
  /// agrees with when the alert is sent.
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  String get image => images.isNotEmpty ? images.first : '';

  factory Product.fromJson(Map<String, dynamic> map) {
    return Product(
      id: map.str('id'),
      name: map.str('name'),
      description: map.str('description'),
      price: map.dbl('price'),
      category: map.str('category', 'Pooja Kits'),
      images: map.strings('images'),
      stock: map.integer('stock'),
      sellerId: map.str('sellerId'),
      // The seller's approved shop name (or their name), from the API.
      sellerName: map.str('sellerName'),
      isActive: map.flag('isActive', true),
      createdAt: map.date('createdAt'),
      festivalTag: map.str('festivalTag'),
      // Maintained by the API as reviews come in.
      ratingAverage: map.dbl('ratingAverage'),
      ratingCount: map.integer('ratingCount'),
      lowStockThreshold: map.integer('lowStockThreshold', 5),
    );
  }

  /// Body for `POST/PUT /seller/products`. Seller and ratings are set by
  /// the server, never sent.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'stock': stock,
      'isActive': isActive,
      'festivalTag': festivalTag,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  /// Widget-friendly map shape used by the existing ProductCard/DetailPage widgets.
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'image': image,
      'images': images,
      'name': name,
      'price': price,
      'oldPrice': null,
      'description': description,
      'category': category,
      'stock': stock,
      'sellerId': sellerId,
      'festivalTag': festivalTag,
    };
  }
}
