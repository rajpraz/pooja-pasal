import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/core/network/token_store.dart';

class _MemoryTokenStore extends TokenStore {
  _MemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

ApiClient _client(MockClientHandler handler, {String? token}) => ApiClient(
      baseUrl: 'https://api.test/api',
      tokenStore: _MemoryTokenStore(token),
      httpClient: MockClient(handler),
    );

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  test('sends the bearer token, JSON body and query, and decodes the reply', () async {
    late http.Request seen;
    final api = _client((request) async {
      seen = request;
      return _json({'ok': true});
    }, token: 'secret');

    final result = await api.post('/orders', {'qty': 2});
    expect(result, {'ok': true});
    expect(seen.headers['Authorization'], 'Bearer secret');
    expect(seen.headers['Accept'], 'application/json');
    expect(jsonDecode(seen.body), {'qty': 2});

    await api.get('/products', query: {'page': 2, 'inStock': true, 'skip': false, 'none': null});
    expect(seen.url.toString(), 'https://api.test/api/products?page=2&inStock=1');
  });

  test('maps API errors to AppFunctionException with the API code and message', () async {
    final api =
        _client((_) async => _json({'message': 'Only 2 left.', 'code': 'out-of-stock'}, 409));
    await expectLater(
      api.post('/orders'),
      throwsA(isA<AppFunctionException>()
          .having((e) => e.code, 'code', 'out-of-stock')
          .having((e) => e.message, 'message', 'Only 2 left.')),
    );
  });

  test('validation errors show the first field message', () async {
    final api = _client((_) async => _json({
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['An account already exists with this email.'],
          },
        }, 422));
    await expectLater(
      api.post('/auth/register'),
      throwsA(isA<AppFunctionException>()
          .having((e) => e.code, 'code', 'invalid-argument')
          .having((e) => e.message, 'message', 'An account already exists with this email.')),
    );
  });

  test('server errors never leak their details', () async {
    final api = _client((_) async => _json({'message': 'SQLSTATE[HY000] secret'}, 500));
    await expectLater(
      api.get('/cart'),
      throwsA(isA<AppFunctionException>()
          .having((e) => e.message, 'message', 'Something went wrong. Please try again.')),
    );
  });

  test('a 401 calls onUnauthorized', () async {
    final api = _client((_) async => _json({'message': 'Unauthenticated.'}, 401));
    var called = false;
    api.onUnauthorized = () => called = true;
    await expectLater(api.get('/auth/me'),
        throwsA(isA<AppFunctionException>().having((e) => e.isAuthError, 'isAuthError', true)));
    expect(called, isTrue);
  });

  test('network failures become a friendly "unavailable" error', () async {
    final api = _client((_) async => throw http.ClientException('connection refused'));
    await expectLater(api.get('/products'),
        throwsA(isA<AppFunctionException>().having((e) => e.code, 'code', 'unavailable')));
  });

  test('watch re-fetches when one of its topics changes', () async {
    var calls = 0;
    final api = _client((_) async => _json({'n': ++calls}));
    final values = <int>[];
    final sub = api.watch({ApiTopics.cart},
        () async => (await api.get('/cart') as Map)['n'] as int).listen(values.add);
    await pumpEventQueue();
    api.notifyChanged(const [ApiTopics.orders]); // other topic: ignored
    await pumpEventQueue();
    api.notifyChanged(const [ApiTopics.cart]);
    await pumpEventQueue();
    await sub.cancel();
    expect(values, [1, 2]);
  });

  test('parsing helpers', () {
    expect(
        asJsonList({
          'data': [
            {'id': 'a'},
            'junk',
          ]
        }),
        [
          {'id': 'a'}
        ]);
    expect(
        asJsonMap({
          'data': {'id': 'a'}
        }),
        {'id': 'a'});
    expect(asJsonMap({'token': 't'}), {'token': 't'});
    expect(parseApiDate('2026-10-24T10:00:00+00:00')!.toUtc(), DateTime.utc(2026, 10, 24, 10));
    expect(parseApiDate(null), isNull);
  });
}
