import 'package:pooja_pasal/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:pooja_pasal/features/notifications/domain/entities/app_notification.dart';
import 'package:pooja_pasal/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Stream<List<AppNotification>> streamNotifications(String uid) =>
      _dataSource.streamNotifications(uid);

  @override
  Future<void> markRead(String uid, String notificationId) =>
      _dataSource.markRead(uid, notificationId);

  @override
  Future<void> registerDevice({required String token, required String platform}) =>
      _dataSource.registerDevice(token: token, platform: platform);

  @override
  Future<void> unregisterDevice(String token) => _dataSource.unregisterDevice(token);
}
