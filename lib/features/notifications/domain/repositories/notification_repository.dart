import 'package:pooja_pasal/features/notifications/domain/entities/app_notification.dart';

/// Notifications are created only by the API (order, payment, stock and
/// seller-application events); the client reads its own and marks them
/// read, and registers the device for push.
abstract class NotificationRepository {
  Stream<List<AppNotification>> streamNotifications(String uid);

  Future<void> markRead(String uid, String notificationId);

  Future<void> registerDevice({required String token, required String platform});

  Future<void> unregisterDevice(String token);
}
