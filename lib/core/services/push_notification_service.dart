import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/router/app_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pooja_pasal/firebase_options.dart';

/// Must match the API's `FCM_ANDROID_CHANNEL_ID` (config/services.php).
const _androidChannel = AndroidNotificationChannel(
  'pooja_pasal_default',
  'Order & shop updates',
  description: 'Order status, payment and stock updates.',
  importance: Importance.high,
);

/// Pushes that arrive in the background or while terminated are shown by
/// the OS from the FCM `notification` payload; FCM still requires a handler.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging push (Android & iOS). Firebase is used for
/// nothing else: the Laravel API creates every notification and pushes it
/// to the tokens registered here.
///
/// - [bootstrap] once before `runApp`;
/// - [onSignedIn] after a sign-in: asks permission, registers the token;
/// - [onSigningOut] before sign-out, so the next account on this device
///   doesn't get the previous account's pushes.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _registeredToken;
  bool _listenersAttached = false;

  static bool _firebaseReady = false;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Never throws: push is optional and must not stop the app starting.
  static Future<void> bootstrap() async {
    if (!isSupported) return;
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Push notifications unavailable: $e');
    }
  }

  Future<void> onSignedIn() async {
    if (!_firebaseReady) return;
    try {
      await _attachListenersOnce();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _getToken(messaging);
      if (token != null) await _register(token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> onSigningOut() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _ref.read(notificationRepositoryProvider).unregisterDevice(token);
    } catch (_) {
      // Best effort: the API also moves a token to whichever account
      // registers it next.
    }
  }

  Future<void> _register(String token) async {
    await _ref
        .read(notificationRepositoryProvider)
        .registerDevice(token: token, platform: _platform);
    _registeredToken = token;
  }

  /// On iOS the FCM token only exists once APNs has issued a device token.
  Future<String?> _getToken(FirebaseMessaging messaging) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      for (var i = 0; i < 10 && await messaging.getAPNSToken() == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (await messaging.getAPNSToken() == null) return null;
    }
    return messaging.getToken();
  }

  Future<void> _attachListenersOnce() async {
    if (_listenersAttached) return;
    _listenersAttached = true;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _openFromData(data.map((k, v) => MapEntry(k, v.toString())));
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);

    final messaging = FirebaseMessaging.instance;
    _subscriptions
      ..add(FirebaseMessaging.onMessage.listen(_onForegroundMessage))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_onOpened))
      ..add(messaging.onTokenRefresh.listen((token) async {
        if (_ref.read(authStateProvider).value == null) return;
        try {
          await _register(token);
        } catch (e) {
          debugPrint('Push token refresh failed: $e');
        }
      }));

    final initial = await messaging.getInitialMessage();
    if (initial != null) _onOpened(initial);
  }

  /// A push means server data changed: refresh open screens now rather
  /// than at the next poll.
  void _refreshInAppData() {
    _ref.read(apiClientProvider).notifyChanged(const [
      ApiTopics.notifications,
      ApiTopics.orders,
      ApiTopics.products,
      ApiTopics.profile,
    ]);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _refreshInAppData();
    final notification = message.notification;
    // iOS shows foreground pushes itself; Android needs a local one.
    if (notification == null || defaultTargetPlatform != TargetPlatform.android)
      return;
    _localNotifications.show(
      id: message.messageId.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onOpened(RemoteMessage message) {
    _refreshInAppData();
    _openFromData(message.data.map((k, v) => MapEntry(k, v.toString())));
  }

  void _openFromData(Map<String, String> data) {
    final uid = _ref.read(authRepositoryProvider).currentUser?.uid;
    final notificationId = data['notificationId'];
    if (uid != null && notificationId != null && notificationId.isNotEmpty) {
      unawaited(_ref
          .read(notificationRepositoryProvider)
          .markRead(uid, notificationId)
          .catchError((_) {}));
    }
    unawaited(_pushWhenRouterReady(
        routeForPush(data['type'] ?? '', data['orderId'] ?? '')));
  }

  /// A tap can cold-start the app; wait until splash/sign-in redirects are
  /// done before navigating.
  Future<void> _pushWhenRouterReady(String route) async {
    const notReady = {
      RouteNames.splash,
      RouteNames.onboarding,
      RouteNames.login,
      RouteNames.signup
    };
    final router = _ref.read(goRouterProvider);
    for (var i = 0; i < 40; i++) {
      final location = router.routerDelegate.currentConfiguration.uri.path;
      if (location.isNotEmpty && !notReady.contains(location)) {
        unawaited(router.push(route));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
  }
}

/// Where tapping a notification of [type] goes.
String routeForPush(String type, String orderId) {
  switch (type) {
    case 'seller_new_order':
    case 'low_stock':
    case 'out_of_stock':
      return RouteNames.sellerDashboard;
    case 'refund_needed':
      return orderId.isEmpty
          ? RouteNames.adminOrders
          : RouteNames.adminOrderDetailPath(orderId);
    case 'seller_application':
      return RouteNames.profile;
    default:
      return orderId.isEmpty
          ? RouteNames.notifications
          : RouteNames.orderTrackingPath(orderId);
  }
}

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
