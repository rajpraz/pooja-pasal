import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/wishlist/data/datasources/wishlist_remote_data_source.dart';
import 'package:pooja_pasal/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:pooja_pasal/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:pooja_pasal/features/wishlist/domain/repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepositoryImpl(WishlistRemoteDataSource(ref.watch(apiClientProvider)));
});

/// Live wishlist for one signed-in user. Mirrors `cartProvider`'s
/// per-uid `StreamProvider.family` shape.
final wishlistProvider = StreamProvider.family<List<WishlistItem>, String>((ref, uid) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(wishlistRepositoryProvider).streamWishlist(uid);
});

/// Wraps wishlist mutations so widgets never call the API directly —
/// mirrors `CartController`'s shape (uid passed per-call rather than the
/// notifier being keyed by uid).
class WishlistController extends AsyncNotifier<void> {
  late final WishlistRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(wishlistRepositoryProvider);
  }

  Future<bool> toggle(String uid, String productId) async {
    state = const AsyncLoading();
    try {
      final saved = await _repository.toggle(uid, productId);
      state = const AsyncData(null);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> remove(String uid, String productId) async {
    state = const AsyncLoading();
    try {
      await _repository.remove(uid, productId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final wishlistControllerProvider =
    AsyncNotifierProvider<WishlistController, void>(WishlistController.new);
