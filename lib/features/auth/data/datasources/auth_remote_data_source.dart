import 'dart:async';

import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/auth/data/datasources/google_id_token_source.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';

/// Sanctum token auth against the Laravel API (`/auth/*`). The token lives
/// in [ApiClient.tokenStore]; the session is restored from it on start-up
/// and dropped whenever the API answers 401 (revoked or disabled account).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api, {GoogleIdTokenSource? google})
      : _google = google ?? GoogleIdTokenSource() {
    _api.onUnauthorized = () {
      if (_session != null) unawaited(_clearSession());
    };
    _restored = _restore();
  }

  final ApiClient _api;
  final GoogleIdTokenSource _google;
  final _sessions = StreamController<AuthSession?>.broadcast();
  late final Future<void> _restored;
  AuthSession? _session;

  AuthSession? get currentUser => _session;

  Stream<AuthSession?> authStateChanges() async* {
    await _restored;
    yield _session;
    yield* _sessions.stream;
  }

  Future<void> _restore() async {
    if (await _api.tokenStore.read() == null) return;
    try {
      _session =
          _sessionFrom(AppUser.fromJson(asJsonMap(await _api.get('/auth/me'))));
    } on AppFunctionException catch (e) {
      // Keep the token through a network blip; drop it only if rejected.
      if (e.isAuthError) await _api.tokenStore.clear();
    }
  }

  AuthSession _sessionFrom(AppUser user) =>
      AuthSession(uid: user.uid, email: user.email);

  Future<void> _startSession(dynamic payload, {bool persist = true}) async {
    final map = payload as Map<String, dynamic>;
    await _api.tokenStore.write(map['token'] as String, persist: persist);
    _session =
        _sessionFrom(AppUser.fromJson(map['user'] as Map<String, dynamic>));
    _sessions.add(_session);
  }

  Future<void> _clearSession() async {
    await _api.tokenStore.clear();
    _session = null;
    _sessions.add(null);
  }

  Stream<AppUser?> userDocStream(String uid) => _api.watch(
        {ApiTopics.profile, ApiTopics.users},
        () => getUserDoc(uid),
        // Picks up an admin approving this account as a seller.
        pollEvery: const Duration(minutes: 1),
      );

  Future<AppUser?> getUserDoc(String uid) async {
    try {
      final path = uid == _session?.uid ? '/auth/me' : '/admin/users/$uid';
      return AppUser.fromJson(asJsonMap(await _api.get(path)));
    } on AppFunctionException catch (e) {
      if (e.code == 'not-found') return null;
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
    String? shopName,
  }) async {
    try {
      final wantsToSell = role == 'seller';
      await _startSession(await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
        if (wantsToSell) 'wantsToSell': true,
        if (wantsToSell) 'shopName': shopName,
      }));
    } on AppFunctionException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      await _startSession(
        await _api.post('/auth/login', {'email': email, 'password': password}),
        persist: rememberMe,
      );
      await _api.tokenStore.writeRememberedEmail(rememberMe ? email : null);
    } on AppFunctionException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  /// Signs in (or creates the account) with Google. Returns false if the
  /// user closed the Google sheet without choosing an account.
  Future<bool> signInWithGoogle({bool rememberMe = true}) async {
    final idToken = await _google.idToken();
    if (idToken == null) return false;
    try {
      await _startSession(await _api.post('/auth/google', {'idToken': idToken}),
          persist: rememberMe);
      return true;
    } on AppFunctionException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  /// Texts a 6-digit login code to [phone].
  Future<void> sendOtp(String phone) async {
    try {
      await _api.post('/auth/otp/send', {'phone': phone});
    } on AppFunctionException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  /// Signs in (or creates the account) with the code texted to [phone].
  Future<void> verifyOtp(String phone, String code, {bool rememberMe = true}) async {
    try {
      await _startSession(await _api.post('/auth/otp/verify', {'phone': phone, 'code': code}),
          persist: rememberMe);
    } on AppFunctionException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  Future<String?> rememberedEmail() => _api.tokenStore.readRememberedEmail();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _api.post('/auth/forgot-password', {'email': email});
    } on AppFunctionException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  Future<void> updateUserProfile(
      {String? name, String? phone, String? address, String? photoUrl}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
    if (updates.isEmpty) return;
    await _api.patch('/auth/profile', updates);
    _api.notifyChanged(const [ApiTopics.profile]);
  }

  Future<void> applyToSell(
      {required String shopName, required String phone, String? reason}) async {
    await _api.post('/seller-application', {
      'shopName': shopName,
      'phone': phone,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    _api.notifyChanged(const [ApiTopics.profile]);
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout');
    } on AppFunctionException {
      // Signing out locally still succeeds when the server can't be reached.
    }
    await _clearSession();
  }
}
