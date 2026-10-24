import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/domain/repositories/address_repository.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/domain/repositories/auth_repository.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/repositories/cart_repository.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/domain/repositories/order_repository.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

/// In-memory stand-ins for the API-backed repositories, for widget tests.

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([this.session]);

  final AuthSession? session;

  @override
  Stream<AuthSession?> authStateChanges() => Stream.value(session);

  @override
  AuthSession? get currentUser => session;

  @override
  Stream<AppUser?> userDocStream(String uid) => Stream.value(null);

  @override
  Future<AppUser?> getUserDoc(String uid) async => null;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
    String? shopName,
  }) async {}

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {}

  @override
  Future<void> applyToSell({required String shopName, required String phone, String? reason}) async {}

  @override
  Future<void> signOut() async {}
}

class FakeCartRepository implements CartRepository {
  FakeCartRepository(this.items);

  List<CartItem> items;
  int clears = 0;

  @override
  Stream<List<CartItem>> streamCart(String uid) => Stream.value(items);

  @override
  Future<void> addToCart(String uid, Product product, {int qty = 1}) async {}

  @override
  Future<void> updateQty(String uid, String productId, int qty) async {}

  @override
  Future<void> removeItem(String uid, String productId) async {}

  @override
  Future<void> clearCart(String uid) async {
    clears++;
    items = [];
  }
}

class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository(this.addresses);

  final List<Address> addresses;

  @override
  Stream<List<Address>> streamAddresses(String uid) => Stream.value(addresses);

  @override
  Future<void> add(String uid, Address address) async {}

  @override
  Future<void> update(String uid, Address address) async {}

  @override
  Future<void> delete(String uid, String addressId) async {}

  @override
  Future<void> setDefault(String uid, String addressId) async {}
}

/// Records each placed order; answers with [result] (or throws [error]).
class FakeOrderRepository implements OrderRepository {
  final placed = <Map<String, Object?>>[];
  final statusChanges = <String>[];
  List<PoojaOrder> sellerOrders = const [];
  CreateOrderResult result =
      const CreateOrderResult(orderId: 'o1', totalAmount: 1080, deduplicated: false);
  Object? error;

  @override
  Future<CreateOrderResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
    String? couponCode,
  }) async {
    if (error != null) throw error!;
    placed.add({
      'items': items.length,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'couponCode': couponCode,
    });
    return result;
  }

  @override
  Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId) => const Stream.empty();

  @override
  Stream<List<PoojaOrder>> streamSellerOrders(String sellerId) => Stream.value(sellerOrders);

  @override
  Stream<PoojaOrder?> streamOrder(String orderId) => const Stream.empty();

  @override
  Stream<List<PoojaOrder>> streamAllOrders({int limit = 200}) => const Stream.empty();

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async =>
      statusChanges.add('$orderId→$status');

  @override
  Future<void> updatePaymentStatus({required String orderId, required String paymentStatus}) async {}

  @override
  Future<void> cancelOrder(String orderId, {String? note}) async {}
}
