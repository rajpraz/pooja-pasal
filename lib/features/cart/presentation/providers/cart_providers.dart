import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:pooja_pasal/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_line_validation.dart';
import 'package:pooja_pasal/features/cart/domain/repositories/cart_repository.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(CartRemoteDataSource(ref.watch(apiClientProvider)));
});

final cartProvider = StreamProvider.family<List<CartItem>, String>((ref, uid) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(cartRepositoryProvider).streamCart(uid);
});

/// Re-checks every cart line against its *current* product document
/// (existence, active flag, stock, price) whenever the cart changes — a
/// point-in-time check, not a live subscription to every product doc, so
/// it won't notice a product going out of stock while this screen sits
/// open without the cart itself changing. That's fine: this is purely a
/// UX nicety to warn the buyer *before* they hit checkout — the actual
/// safety net is `createOrder` re-reading every product fresh inside a
/// transaction, which still runs even if this client-side check is stale.
final cartValidationProvider =
    FutureProvider.autoDispose.family<List<CartLineValidation>, String>((ref, uid) async {
  final items = await ref.watch(cartProvider(uid).future);
  if (items.isEmpty) return const [];
  final productRepository = ref.watch(productRepositoryProvider);
  return Future.wait(items.map((item) async {
    final Product? product = await productRepository.getProduct(item.productId);
    return CartLineValidation(item: item, product: product);
  }));
});

/// Wraps cart mutations so widgets (home, product detail, cart page) never
/// call the API directly — only through this controller.
class CartController extends AsyncNotifier<void> {
  late final CartRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(cartRepositoryProvider);
  }

  Future<void> addToCart(String uid, Product product, {int qty = 1}) async {
    state = const AsyncLoading();
    try {
      await _repository.addToCart(uid, product, qty: qty);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateQty(String uid, String productId, int qty) async {
    state = const AsyncLoading();
    try {
      await _repository.updateQty(uid, productId, qty);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> removeItem(String uid, String productId) async {
    state = const AsyncLoading();
    try {
      await _repository.removeItem(uid, productId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> clearCart(String uid) async {
    state = const AsyncLoading();
    try {
      await _repository.clearCart(uid);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final cartControllerProvider = AsyncNotifierProvider<CartController, void>(CartController.new);
