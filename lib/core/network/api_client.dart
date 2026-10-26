import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pooja_pasal/core/constants/api_config.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/token_store.dart';

/// Resource topics used to tell live [ApiClient.watch] streams their data
/// may have changed.
abstract final class ApiTopics {
  static const String profile = 'profile';
  static const String addresses = 'addresses';
  static const String cart = 'cart';
  static const String wishlist = 'wishlist';
  static const String notifications = 'notifications';
  static const String categories = 'categories';
  static const String products = 'products';
  static const String reviews = 'reviews';
  static const String orders = 'orders';
  static const String users = 'users';
  static const String sellerApplications = 'sellerApplications';
}

/// The one place the app talks HTTP to the Laravel API. Feature data
/// sources call through this; UI never does.
///
/// Every failure is thrown as an [AppFunctionException] carrying the API's
/// machine-readable `code` (e.g. `failed-precondition`, `out-of-stock`) and
/// a message safe to show the user, so presentation keeps using
/// `friendlyErrorMessage` unchanged.
///
/// [watch] turns a fetch into a stream that re-fetches whenever one of its
/// topics is marked changed via [notifyChanged] (and optionally on a
/// polling interval), which keeps the app's stream-based providers working
/// without Firestore's realtime snapshots.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStore tokenStore,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  })  : _tokenStore = tokenStore,
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final TokenStore _tokenStore;
  final http.Client _http;
  final _changes = StreamController<String>.broadcast();

  /// Called when a request is rejected with HTTP 401 — the stored token
  /// was revoked (signed out elsewhere, account disabled) or expired.
  void Function()? onUnauthorized;

  TokenStore get tokenStore => _tokenStore;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        if (value) cleaned[key] = '1';
        return;
      }
      cleaned[key] = value.toString();
    });
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: cleaned.isEmpty ? null : cleaned);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _tokenStore.read();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, [Object? body]) =>
      _send('DELETE', path, body: body);

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? query, Object? body}) async {
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(await _headers());
    if (body != null) request.body = jsonEncode(body);
    return _run(() => _http.send(request).timeout(timeout));
  }

  /// Multipart upload of a single [file] under the `file` field.
  Future<dynamic> upload(String path,
      {required File file, Map<String, String> fields = const {}}) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(await _headers(json: false))
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    return _run(() => _http.send(request).timeout(const Duration(minutes: 2)));
  }

  Future<dynamic> _run(Future<http.StreamedResponse> Function() send) async {
    final http.Response response;
    try {
      response = await http.Response.fromStream(await send());
    } on TimeoutException {
      throw const AppFunctionException('deadline-exceeded',
          'The request timed out. Please check your connection and try again.');
    } on SocketException {
      throw const AppFunctionException('unavailable',
          'Could not connect. Please check your internet connection and try again.');
    } on http.ClientException {
      throw const AppFunctionException('unavailable',
          'Could not connect. Please check your internet connection and try again.');
    }
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic payload;
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        payload = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return payload;

    if (response.statusCode == 401) onUnauthorized?.call();
    throw apiErrorFrom(response.statusCode, payload);
  }

  /// Marks [topics] as changed so every live [watch] stream subscribed to
  /// any of them re-fetches.
  void notifyChanged(Iterable<String> topics) {
    for (final topic in topics) {
      _changes.add(topic);
    }
  }

  /// A stream that emits [fetch]'s result on listen, again whenever one of
  /// [topics] changes, and every [pollEvery] if given (for data other
  /// people change, such as a seller updating an order's status).
  ///
  /// Overlapping re-fetches keep only the newest result, so a slow earlier
  /// response never overwrites a fresher one.
  Stream<T> watch<T>(Set<String> topics, Future<T> Function() fetch,
      {Duration? pollEvery}) {
    late final StreamController<T> controller;
    StreamSubscription<String>? changeSub;
    Timer? timer;
    var latestRequest = 0;

    Future<void> load() async {
      final requestId = ++latestRequest;
      try {
        final value = await fetch();
        if (!controller.isClosed && requestId == latestRequest)
          controller.add(value);
      } catch (e, st) {
        if (!controller.isClosed && requestId == latestRequest)
          controller.addError(e, st);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        unawaited(load());
        changeSub = _changes.stream
            .where(topics.contains)
            .listen((_) => unawaited(load()));
        if (pollEvery != null)
          timer = Timer.periodic(pollEvery, (_) => unawaited(load()));
      },
      // The listener is gone for good (single-subscription stream): stop
      // polling and release the controller.
      onCancel: () async {
        timer?.cancel();
        await changeSub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  void dispose() {
    _changes.close();
    _http.close();
  }
}

/// Builds the [AppFunctionException] for a failed API response. Validation
/// failures (422) show the first field message, which is the most specific.
AppFunctionException apiErrorFrom(int statusCode, dynamic payload) {
  final map =
      payload is Map<String, dynamic> ? payload : const <String, dynamic>{};
  final errors = map['errors'];
  String? message;
  if (errors is Map && errors.isNotEmpty) {
    final first = errors.values.first;
    if (first is List && first.isNotEmpty) message = first.first.toString();
  }
  message ??= map['message'] as String?;
  final code = (map['code'] as String?) ??
      switch (statusCode) {
        401 => 'unauthenticated',
        403 => 'permission-denied',
        404 => 'not-found',
        409 || 412 => 'failed-precondition',
        422 => 'invalid-argument',
        429 => 'resource-exhausted',
        _ => 'internal',
      };
  if (message == null || message.isEmpty || statusCode >= 500) {
    message = statusCode >= 500
        ? 'Something went wrong. Please try again.'
        : 'This request could not be completed.';
  }
  return AppFunctionException(code, message);
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
      baseUrl: ApiConfig.baseUrl, tokenStore: ref.watch(tokenStoreProvider));
  ref.onDispose(client.dispose);
  return client;
});

/// `data` list of a payload (`{data: [...]}` or a bare list).
List<Map<String, dynamic>> asJsonList(dynamic payload) {
  final data = payload is Map<String, dynamic> ? payload['data'] : payload;
  if (data is! List) return const [];
  return data.whereType<Map<String, dynamic>>().toList();
}

/// `data` object of a payload (`{data: {...}}` or a bare object).
Map<String, dynamic> asJsonMap(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    return payload;
  }
  return const {};
}

/// Parses an ISO-8601 timestamp from the API.
DateTime? parseApiDate(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
