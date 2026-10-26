import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/core/network/token_store.dart';
import 'package:pooja_pasal/core/services/push_notification_service.dart';
import 'package:pooja_pasal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:pooja_pasal/features/products/data/datasources/product_remote_data_source.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';

class _MemoryTokenStore extends TokenStore {
  _MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value, {bool persist = true}) async => token = value;

  @override
  Future<String?> readRememberedEmail() async => null;

  @override
  Future<void> writeRememberedEmail(String? email) async {}

  @override
  Future<void> clear() async => token = null;
}

/// Records requests and answers from [routes] (`'METHOD /path'` → body).
class _FakeApi {
  _FakeApi(this.routes, {String? token}) : tokens = _MemoryTokenStore(token);

  final Map<String, Object Function(http.Request)> routes;
  final _MemoryTokenStore tokens;
  final requests = <http.Request>[];

  late final api = ApiClient(
    baseUrl: 'https://api.test/api',
    tokenStore: tokens,
    httpClient: MockClient((request) async {
      requests.add(request);
      final key =
          '${request.method} ${request.url.path.replaceFirst('/api', '')}';
      final handler = routes[key];
      if (handler == null)
        return http.Response(jsonEncode({'message': 'Not found.'}), 404);
      final body = handler(request);
      if (body is http.Response) return body;
      return http.Response(jsonEncode(body), 200);
    }),
  );

  List<String> get calls => requests
      .map((r) => '${r.method} ${r.url.path.replaceFirst('/api', '')}')
      .toList();
}

const _user = {
  'id': 'u1',
  'name': 'Sita',
  'email': 'sita@example.com',
  'role': 'buyer',
  'sellerStatus': 'pending',
  'shopName': 'Sita Samagri',
};

const _order = {
  'id': 'o1',
  'buyerId': 'u1',
  'sellerIds': ['s1'],
  'items': [
    {
      'productId': 'p1',
      'name': 'Brass Diya',
      'price': 500,
      'qty': 2,
      'sellerId': 's1',
      'sellerName': 'Shop',
      'image': 'https://img/1.jpg'
    }
  ],
  'subtotal': 1000,
  'deliveryFee': 80,
  'discount': 100,
  'tax': 0,
  'totalAmount': 980,
  'couponCode': 'DASHAIN10',
  'status': 'confirmed',
  'paymentStatus': 'paid',
  'paymentMethod': 'khalti',
  'shippingAddress': 'Sita, Thamel, 9800000000',
  'statusHistory': [
    {
      'status': 'pending',
      'timestamp': '2026-10-24T10:00:00+00:00',
      'changedBy': 'u1',
      'note': ''
    },
  ],
  'createdAt': '2026-10-24T10:00:00+00:00',
};

void main() {
  group('entities parse the API JSON', () {
    test('order', () {
      final order = PoojaOrder.fromJson(_order);
      expect(order.totalAmount, 980);
      expect(order.items.single.qty, 2);
      expect(order.items.single.image, 'https://img/1.jpg');
      expect(order.couponCode, 'DASHAIN10');
      expect(order.statusHistory.single.timestamp, isNotNull);
    });

    test('product', () {
      final product = Product.fromJson({
        'id': 'p1',
        'name': 'Diya',
        'price': 240,
        'category': 'Diyas',
        'images': ['https://img/1.jpg'],
        'stock': 3,
        'lowStockThreshold': 5,
        'sellerId': 's1',
        'sellerName': 'Shop',
        'isActive': true,
        'ratingAverage': 4.5,
        'ratingCount': 2,
      });
      expect(product.isLowStock, isTrue);
      expect(product.image, 'https://img/1.jpg');
      expect(product.toJson().containsKey('sellerId'), isFalse,
          reason: 'the seller is set by the server, never sent');
    });
  });

  group('auth', () {
    test('sign-in stores the token and starts a session', () async {
      final fake = _FakeApi({
        'POST /auth/login': (_) => {'token': 'tok', 'user': _user},
      });
      final auth = AuthRemoteDataSource(fake.api);
      await auth.signIn(email: 'sita@example.com', password: 'password123');
      expect(fake.tokens.token, 'tok');
      expect(auth.currentUser!.uid, 'u1');
    });

    test('OTP verification posts phone and code, then starts a session', () async {
      Map<String, dynamic>? body;
      final fake = _FakeApi({
        'POST /auth/otp/verify': (req) {
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return {'token': 'otp-tok', 'user': _user};
        },
      });
      final auth = AuthRemoteDataSource(fake.api);
      await auth.verifyOtp('9801234567', '123456');
      expect(body, {'phone': '9801234567', 'code': '123456'});
      expect(fake.tokens.token, 'otp-tok');
      expect(auth.currentUser!.uid, 'u1');
    });

    test('bad credentials surface as AuthException with the API message',
        () async {
      final fake = _FakeApi({
        'POST /auth/login': (_) => http.Response(
            jsonEncode({
              'message': 'Incorrect email or password.',
              'code': 'invalid-credentials'
            }),
            401),
      });
      final auth = AuthRemoteDataSource(fake.api);
      await expectLater(
        auth.signIn(email: 'x@example.com', password: 'nope'),
        throwsA(isA<AuthException>().having(
            (e) => e.message, 'message', 'Incorrect email or password.')),
      );
    });

    test('a saved token is restored at start-up, and dropped when rejected',
        () async {
      final valid = _FakeApi({
        'GET /auth/me': (_) => {'data': _user}
      }, token: 'tok');
      expect(await AuthRemoteDataSource(valid.api).authStateChanges().first,
          isNotNull);

      final revoked = _FakeApi({
        'GET /auth/me': (_) =>
            http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401),
      }, token: 'old');
      expect(await AuthRemoteDataSource(revoked.api).authStateChanges().first,
          isNull);
      expect(revoked.tokens.token, isNull);
    });

    test('seller sign-up files an application with the shop name', () async {
      final fake = _FakeApi({
        'POST /auth/register': (_) => {'token': 'tok', 'user': _user},
      });
      await AuthRemoteDataSource(fake.api).signUp(
        email: 'sita@example.com',
        password: 'password123',
        name: 'Sita',
        phone: '9800000000',
        address: 'Thamel',
        role: 'seller',
        shopName: 'Sita Samagri',
      );
      final body =
          jsonDecode(fake.requests.single.body) as Map<String, dynamic>;
      expect(body['wantsToSell'], isTrue);
      expect(body['shopName'], 'Sita Samagri');
      expect(body.containsKey('role'), isFalse,
          reason: 'the role is never client-chosen');
    });

    test('sign-out clears the session even when the server is unreachable',
        () async {
      final fake = _FakeApi({
        'POST /auth/login': (_) => {'token': 'tok', 'user': _user}
      });
      final auth = AuthRemoteDataSource(fake.api);
      await auth.signIn(email: 'sita@example.com', password: 'password123');
      await auth.signOut(); // POST /auth/logout → 404 here
      expect(auth.currentUser, isNull);
      expect(fake.tokens.token, isNull);
    });
  });

  group('products', () {
    test('toggling isActive alone uses the activate endpoint; edits use PUT',
        () async {
      final fake = _FakeApi({
        'PATCH /seller/products/p1/active': (_) =>
            {'data': <String, dynamic>{}},
        'PUT /seller/products/p1': (_) => {'data': <String, dynamic>{}},
      });
      final products = ProductRemoteDataSource(fake.api);
      await products.updateProduct('p1', {'isActive': false});
      await products.updateProduct(
          'p1', {'name': 'Diya', 'price': 1, 'category': 'Diyas', 'stock': 1});
      expect(fake.calls,
          ['PATCH /seller/products/p1/active', 'PUT /seller/products/p1']);
    });

    test('pages carry the next page number as the cursor', () async {
      final fake = _FakeApi({
        'GET /products': (r) => {
              'data': <Object>[],
              'meta': {'hasMore': r.url.queryParameters['page'] == '1'},
            },
      });
      final first = await ProductRemoteDataSource(fake.api)
          .fetchActiveProductsPage(limit: 5);
      expect(first.cursor, 2);
      expect(first.hasMore, isTrue);
      expect(fake.requests.single.url.queryParameters,
          {'page': '1', 'perPage': '5', 'sort': 'newest'});
    });

    test('a missing product is null, not an error', () async {
      final fake = _FakeApi({});
      expect(
          await ProductRemoteDataSource(fake.api).getProduct('nope'), isNull);
    });
  });

  group('orders', () {
    test(
        'a seller reads the seller portal; an admin viewing a seller reads the admin list',
        () async {
      final fake = _FakeApi({
        'GET /seller/orders': (_) => {
              'data': [_order]
            },
        'GET /admin/orders': (_) => {
              'data': [_order]
            },
      });
      await OrderRemoteDataSource(fake.api, currentUid: () => 's1')
          .streamSellerOrders('s1')
          .first;
      await OrderRemoteDataSource(fake.api, currentUid: () => 'admin')
          .streamSellerOrders('s1')
          .first;
      expect(fake.calls, ['GET /seller/orders', 'GET /admin/orders']);
      expect(fake.requests.last.url.queryParameters['sellerId'], 's1');
    });

    test('checkout sends only intent: product ids, quantities, coupon',
        () async {
      final fake = _FakeApi({
        'POST /orders': (_) =>
            {'orderId': 'o1', 'totalAmount': 980, 'deduplicated': false},
      });
      final result =
          await OrderRemoteDataSource(fake.api, currentUid: () => 'u1')
              .createOrder(
        items: const [
          CartItem(
              productId: 'p1',
              name: 'Brass Diya',
              price: 1,
              qty: 2,
              image: '',
              sellerId: 's1'),
        ],
        shippingAddress: 'Thamel',
        paymentMethod: 'cod',
        idempotencyKey: 'k1',
        couponCode: 'DASHAIN10',
      );
      expect(result.totalAmount, 980);
      final body =
          jsonDecode(fake.requests.single.body) as Map<String, dynamic>;
      expect(body['items'], [
        {'productId': 'p1', 'qty': 2}
      ]);
      expect(body['couponCode'], 'DASHAIN10');
      expect(body.containsKey('totalAmount'), isFalse);
    });
  });

  group('payments', () {
    test('verification only succeeds once the server says paid', () async {
      var status = 'processing';
      final fake = _FakeApi({
        'POST /orders/o1/verify-payment': (_) => {
              'data': {..._order, 'paymentStatus': status}
            },
      });
      final payments = PaymentRemoteDataSource(fake.api);
      await expectLater(payments.verifyKhalti(orderId: 'o1', pidx: 'P1'),
          throwsA(isA<AppFunctionException>()));
      status = 'failed';
      await expectLater(
          payments.verifyEsewa('o1'), throwsA(isA<AppFunctionException>()));
      status = 'paid';
      await payments.verifyKhalti(orderId: 'o1', pidx: 'P1');
      expect(jsonDecode(fake.requests.first.body), {'pidx': 'P1'});
    });

    test('Khalti and eSewa initiation parse the server reply', () async {
      final fake = _FakeApi({
        'POST /orders/o1/pay': (_) => {
              'paymentUrl': 'https://pay.test/start',
              'pidx': 'P1',
              'esewa': {
                'formUrl': 'https://rc-epay.esewa.com.np/api/epay/main/v2/form',
                'totalAmount': '980.00',
                'transactionUuid': 't1',
                'productCode': 'EPAYTEST',
                'signature': 'sig',
                'signedFieldNames':
                    'total_amount,transaction_uuid,product_code',
                'successUrl': 'https://api.test/payments/esewa/success',
                'failureUrl': 'https://api.test/payments/esewa/t1/failure',
              },
            },
      });
      final payments = PaymentRemoteDataSource(fake.api);
      final khalti = await payments.initiateKhalti('o1');
      expect(khalti.pidx, 'P1');
      expect(khalti.paymentUrl, 'https://pay.test/start');
      final esewa = await payments.initiateEsewa('o1');
      expect(esewa.totalAmount, '980.00');
      expect(esewa.failureUrl, endsWith('/failure'));
    });
  });

  test('tapping a push opens the right screen', () {
    expect(routeForPush('order_shipped', 'o1'), '/orders/o1');
    expect(routeForPush('seller_new_order', 'o1'), '/seller/dashboard');
    expect(routeForPush('refund_needed', 'o1'), '/admin/orders/o1');
    expect(routeForPush('seller_application', ''), '/profile');
    expect(routeForPush('general', ''), '/notifications');
  });
}
