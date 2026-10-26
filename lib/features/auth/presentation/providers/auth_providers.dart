import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/core/services/push_notification_service.dart';
import 'package:pooja_pasal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pooja_pasal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteDataSource(ref.watch(apiClientProvider)));
});

final authStateProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).userDocStream(user.uid);
});

/// Any user's profile by uid — the caller's own, or (for an admin, which
/// the API enforces) someone else's. A non-admin asking for another uid
/// gets a permission-denied stream error, not silently empty data.
final userDocProvider =
    StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).userDocStream(uid);
});

/// Signs out, first unregistering this device from push so the next
/// account here doesn't get this one's notifications.
final signOutActionProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(pushNotificationServiceProvider).onSigningOut();
    await ref.read(authRepositoryProvider).signOut();
  };
});

/// For providers holding one account's data: watching this makes them
/// restart with the new token whenever someone signs in or out, and returns
/// false once signed out so they stop fetching (and polling) altogether.
///
/// While the saved session is still being restored it returns true: an
/// empty stream then would never emit, leaving anything awaiting the
/// provider's first value (e.g. checkout's saved addresses) stuck. The
/// provider re-runs as soon as the session is known.
bool watchSignedIn(Ref ref) {
  final session = ref.watch(authStateProvider);
  return session.isLoading && !session.hasValue || session.value != null;
}
