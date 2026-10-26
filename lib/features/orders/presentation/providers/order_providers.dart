import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:pooja_pasal/features/orders/data/repositories/order_repository_impl.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(OrderRemoteDataSource(
    ref.watch(apiClientProvider),
    currentUid: () => ref.read(authRepositoryProvider).currentUser?.uid,
  ));
});

final buyerOrdersProvider =
    StreamProvider.family<List<PoojaOrder>, String>((ref, buyerId) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).streamBuyerOrders(buyerId);
});

final sellerOrdersProvider =
    StreamProvider.family<List<PoojaOrder>, String>((ref, sellerId) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).streamSellerOrders(sellerId);
});

/// autoDispose: unlike buyer/seller order *lists* (one stable key per
/// session — the user's own uid), this is keyed per order *viewed*. Over a
/// session a buyer may open many different orders from history/
/// notifications; without autoDispose each one would keep polling the API
/// for the rest of the app's lifetime instead of stopping when the
/// track-order page is no longer watched.
final orderProvider =
    StreamProvider.autoDispose.family<PoojaOrder?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).streamOrder(orderId);
});

/// Admin-only: all orders (bounded), for the admin order-oversight list.
final adminAllOrdersProvider = StreamProvider<List<PoojaOrder>>((ref) {
  if (!watchSignedIn(ref)) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).streamAllOrders();
});

/// Riverpod-first order actions: UI calls this controller, which delegates
/// to [OrderRepository] (the API data source) — no order-total/stock logic
/// lives here or in any widget. [state] tracks the loading/error status of
/// the in-flight action so the UI can disable buttons and show errors via
/// [AsyncValue.when]; the actual result of a call is also returned directly
/// from the method so callers that need the value (e.g. checkout needing
/// the new orderId) don't have to thread it through provider state.
class OrderController extends AsyncNotifier<void> {
  late final OrderRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(orderRepositoryProvider);
  }

  Future<CreateOrderResult> placeOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
    String? couponCode,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.createOrder(
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        idempotencyKey: idempotencyKey,
        couponCode: couponCode,
      );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateOrderStatus(
          orderId: orderId, status: status, note: note);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePaymentStatus(
      {required String orderId, required String paymentStatus}) async {
    state = const AsyncLoading();
    try {
      await _repository.updatePaymentStatus(
          orderId: orderId, paymentStatus: paymentStatus);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, {String? note}) =>
      updateStatus(orderId: orderId, status: 'cancelled', note: note);
}

final orderControllerProvider =
    AsyncNotifierProvider<OrderController, void>(OrderController.new);
