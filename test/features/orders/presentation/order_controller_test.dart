import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/domain/repositories/order_repository.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';

/// Fake standing in for the Cloud-Functions-backed OrderRepository, so
/// these tests exercise OrderController's own logic (state transitions,
/// error propagation) without ever touching Firebase — the trusted backend
/// logic itself (price/stock validation, state machine) is functions/'s
/// responsibility and out of scope for a Dart-side controller test.
class _FakeOrderRepository implements OrderRepository {
  final calls = <String>[];
  Object? errorToThrow;
  CreateOrderResult createOrderResult = const CreateOrderResult(
      orderId: 'order-1', totalAmount: 180, deduplicated: false);

  @override
  Future<CreateOrderResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
    String? couponCode,
  }) async {
    calls.add('createOrder(items: ${items.length}, address: $shippingAddress, '
        'method: $paymentMethod, key: $idempotencyKey)');
    if (errorToThrow != null) throw errorToThrow!;
    return createOrderResult;
  }

  @override
  Future<void> updateOrderStatus(
      {required String orderId, required String status, String? note}) async {
    calls.add('updateOrderStatus($orderId, $status, note: $note)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> updatePaymentStatus(
      {required String orderId, required String paymentStatus}) async {
    calls.add('updatePaymentStatus($orderId, $paymentStatus)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> cancelOrder(String orderId, {String? note}) async {
    calls.add('cancelOrder($orderId, note: $note)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId) =>
      const Stream.empty();
  @override
  Stream<List<PoojaOrder>> streamSellerOrders(String sellerId) =>
      const Stream.empty();
  @override
  Stream<PoojaOrder?> streamOrder(String orderId) => const Stream.empty();
  @override
  Stream<List<PoojaOrder>> streamAllOrders({int limit = 200}) =>
      const Stream.empty();
}

CartItem _cartItem() => const CartItem(
      productId: 'p1',
      name: 'Diya Set',
      price: 100,
      qty: 2,
      image: '',
      sellerId: 's1',
    );

void main() {
  late _FakeOrderRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeOrderRepository();
    container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
  });

  group('OrderController.placeOrder', () {
    test('delegates to the repository and returns its server-computed result',
        () async {
      final result =
          await container.read(orderControllerProvider.notifier).placeOrder(
        items: [_cartItem()],
        shippingAddress: 'Kathmandu',
        paymentMethod: 'khalti',
        idempotencyKey: 'key-123',
      );

      expect(fakeRepo.calls, [
        'createOrder(items: 1, address: Kathmandu, method: khalti, key: key-123)',
      ]);
      expect(result.orderId, 'order-1');
      expect(result.totalAmount, 180);
      expect(
          container.read(orderControllerProvider), const AsyncData<void>(null));
    });

    test(
        'never invents its own total — it only ever returns exactly what the repository gave it',
        () async {
      fakeRepo.createOrderResult = const CreateOrderResult(
          orderId: 'order-2', totalAmount: 999.5, deduplicated: true);

      final result =
          await container.read(orderControllerProvider.notifier).placeOrder(
        items: [_cartItem()],
        shippingAddress: 'Pokhara',
        paymentMethod: 'cod',
        idempotencyKey: 'key-456',
      );

      expect(result.totalAmount, 999.5);
      expect(result.deduplicated, isTrue);
    });

    test(
        'propagates repository failure as AsyncError and rethrows to the caller',
        () async {
      fakeRepo.errorToThrow = Exception('out of stock');

      await expectLater(
        () => container.read(orderControllerProvider.notifier).placeOrder(
          items: [_cartItem()],
          shippingAddress: 'Kathmandu',
          paymentMethod: 'khalti',
          idempotencyKey: 'key-789',
        ),
        throwsA(isA<Exception>()),
      );

      expect(container.read(orderControllerProvider).hasError, isTrue);
    });
  });

  group('OrderController.updateStatus / cancelOrder', () {
    test('updateStatus passes orderId/status/note through unchanged', () async {
      await container.read(orderControllerProvider.notifier).updateStatus(
          orderId: 'order-1', status: 'confirmed', note: 'ready to ship');

      expect(fakeRepo.calls,
          ['updateOrderStatus(order-1, confirmed, note: ready to ship)']);
    });

    test(
        'cancelOrder is implemented as updateStatus(status: "cancelled") — never a separate delete',
        () async {
      await container
          .read(orderControllerProvider.notifier)
          .cancelOrder('order-1', note: 'buyer changed mind');

      expect(fakeRepo.calls,
          ['updateOrderStatus(order-1, cancelled, note: buyer changed mind)']);
    });

    test(
        'a rejected status transition (e.g. backend state-machine failure) surfaces as AsyncError',
        () async {
      fakeRepo.errorToThrow =
          Exception('Order cannot move from "delivered" to "cancelled"');

      await expectLater(
        () => container
            .read(orderControllerProvider.notifier)
            .cancelOrder('order-1'),
        throwsA(isA<Exception>()),
      );

      expect(container.read(orderControllerProvider).hasError, isTrue);
    });
  });
}
