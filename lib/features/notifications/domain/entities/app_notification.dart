import 'package:pooja_pasal/core/network/json_reader.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'order_placed' | 'order_status' | 'offer'
  final String? orderId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> map) {
    return AppNotification(
      id: map.str('id'),
      title: map.str('title'),
      body: map.str('body'),
      type: map.str('type', 'general'),
      orderId: map.strOrNull('orderId'),
      read: map.flag('read'),
      createdAt: map.date('createdAt'),
    );
  }
}
