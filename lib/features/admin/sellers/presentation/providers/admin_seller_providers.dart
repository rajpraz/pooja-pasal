import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/admin/sellers/data/datasources/admin_seller_remote_data_source.dart';
import 'package:pooja_pasal/features/admin/sellers/data/repositories/admin_seller_repository_impl.dart';
import 'package:pooja_pasal/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:pooja_pasal/features/admin/sellers/domain/repositories/admin_seller_repository.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

final adminSellerRepositoryProvider = Provider<AdminSellerRepository>((ref) {
  return AdminSellerRepositoryImpl(AdminSellerRemoteDataSource(ref.watch(apiClientProvider)));
});

final pendingSellerApplicationsProvider = StreamProvider<List<SellerApplication>>((ref) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(adminSellerRepositoryProvider).streamPendingApplications();
});

final allSellersProvider = StreamProvider<List<AppUser>>((ref) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(adminSellerRepositoryProvider).streamSellers();
});

class AdminSellerController extends AsyncNotifier<void> {
  late final AdminSellerRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(adminSellerRepositoryProvider);
  }

  Future<void> approve(String applicantUid) =>
      _run(() => _repository.approveApplication(applicantUid));

  Future<void> reject(String applicantUid, {String? reason}) =>
      _run(() => _repository.rejectApplication(applicantUid, reason: reason));

  /// Demote/promote a user. See [AdminSellerRepository.setUserRole].
  Future<void> setRole(String uid, String role) => _run(() => _repository.setUserRole(uid, role));

  /// Tracks the action in [state] and rethrows failures, so callers'
  /// try/catch can show the error instead of a false "done" message.
  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final adminSellerControllerProvider =
    AsyncNotifierProvider<AdminSellerController, void>(AdminSellerController.new);
