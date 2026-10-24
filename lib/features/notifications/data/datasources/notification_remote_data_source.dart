import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/notifications/domain/entities/app_notification.dart';

/// The signed-in user's in-app notifications (`/notifications`), polled so
/// new order and payment updates show up without a restart.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._api);

  final ApiClient _api;

  Stream<List<AppNotification>> streamNotifications(String uid) => _api.watch(
        {ApiTopics.notifications},
        () async =>
            asJsonList(await _api.get('/notifications')).map(AppNotification.fromJson).toList(),
        pollEvery: const Duration(seconds: 30),
      );

  Future<void> markRead(String uid, String notificationId) async {
    await _api.post('/notifications/$notificationId/read');
    _api.notifyChanged(const [ApiTopics.notifications]);
  }

  /// Registers this install's FCM token so the API pushes to it.
  Future<void> registerDevice({required String token, required String platform}) async {
    await _api.post('/devices', {'token': token, 'platform': platform});
  }

  Future<void> unregisterDevice(String token) async {
    await _api.delete('/devices', {'token': token});
  }
}
