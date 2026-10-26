import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:pooja_pasal/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:pooja_pasal/features/notifications/domain/entities/app_notification.dart';
import 'package:pooja_pasal/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
      NotificationRemoteDataSource(ref.watch(apiClientProvider)));
});

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).streamNotifications(uid);
});
