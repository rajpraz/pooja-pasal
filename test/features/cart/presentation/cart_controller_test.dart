import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/repositories/cart_repository.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

/// Records every call it receives instead of touching Firestore — the same
/// fake-repository-over-a-real-provider pattern already used in
/// test/widget_test.dart's _FakeAuthRepository.
class _FakeCartRepository implements CartRepository {
  final calls = <String>[];
  Object? errorToThrow;

  @override
  Future<void> addToCart(String uid, Product product, {int qty = 1}) async {
    calls.add('addToCart($uid, ${product.id}, qty: $qty)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> updateQty(String uid, String productId, int qty) async {
    calls.add('updateQty($uid, $productId, $qty)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> removeItem(String uid, String productId) async {
    calls.add('removeItem($uid, $productId)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> clearCart(String uid) async {
    calls.add('clearCart($uid)');
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Stream<List<CartItem>> streamCart(String uid) => const Stream.empty();
}

Product _product({String id = 'p1'}) => Product(
      id: id,
      name: 'Diya Set',
      description: '',
      price: 100,
      category: 'Diyas',
      images: const [],
      stock: 10,
      sellerId: 's1',
      isActive: true,
    );

void main() {
  late _FakeCartRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeCartRepository();
    container = ProviderContainer(
      overrides: [cartRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
  });

  group('CartController', () {
    test('addToCart delegates to the repository with the right arguments', () async {
      await container.read(cartControllerProvider.notifier).addToCart('u1', _product(), qty: 3);
      expect(fakeRepo.calls, ['addToCart(u1, p1, qty: 3)']);
      expect(container.read(cartControllerProvider), const AsyncData<void>(null));
    });

    test('updateQty delegates to the repository', () async {
      await container.read(cartControllerProvider.notifier).updateQty('u1', 'p1', 5);
      expect(fakeRepo.calls, ['updateQty(u1, p1, 5)']);
    });

    test('removeItem delegates to the repository', () async {
      await container.read(cartControllerProvider.notifier).removeItem('u1', 'p1');
      expect(fakeRepo.calls, ['removeItem(u1, p1)']);
    });

    test('clearCart delegates to the repository', () async {
      await container.read(cartControllerProvider.notifier).clearCart('u1');
      expect(fakeRepo.calls, ['clearCart(u1)']);
    });

    test('state becomes AsyncError and rethrows when the repository throws', () async {
      fakeRepo.errorToThrow = Exception('network down');

      await expectLater(
        () => container.read(cartControllerProvider.notifier).addToCart('u1', _product()),
        throwsA(isA<Exception>()),
      );

      final state = container.read(cartControllerProvider);
      expect(state.hasError, isTrue);
    });

    test('a later successful call recovers state back to AsyncData after a prior error', () async {
      fakeRepo.errorToThrow = Exception('boom');
      await expectLater(
        () => container.read(cartControllerProvider.notifier).addToCart('u1', _product()),
        throwsA(isA<Exception>()),
      );
      expect(container.read(cartControllerProvider).hasError, isTrue);

      fakeRepo.errorToThrow = null;
      await container.read(cartControllerProvider.notifier).addToCart('u1', _product());
      expect(container.read(cartControllerProvider), const AsyncData<void>(null));
    });
  });
}
