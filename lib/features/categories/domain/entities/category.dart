import 'package:pooja_pasal/core/network/json_reader.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> map) {
    return Category(
      id: map.str('id'),
      name: map.str('name'),
      imageUrl: map.str('imageUrl'),
      isActive: map.flag('isActive', true),
      sortOrder: map.integer('sortOrder'),
    );
  }
}
