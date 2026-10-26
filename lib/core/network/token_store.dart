import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Sanctum API token between app launches, cached in memory
/// after the first read so requests don't hit platform storage.
class TokenStore {
  static const _key = 'api_token';
  static const _emailKey = 'remembered_email';

  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_key);
    _loaded = true;
    return _cached;
  }

  /// Stores [token]. With [persist] false it lives in memory only, so the
  /// user is signed out when the app is closed.
  Future<void> write(String token, {bool persist = true}) async {
    _cached = token;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (persist) {
      await prefs.setString(_key, token);
    } else {
      await prefs.remove(_key);
    }
  }

  /// The email saved by the last "Remember me" sign-in, if any.
  Future<String?> readRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Saves [email] for pre-filling the login form, or forgets it when null.
  Future<void> writeRememberedEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, email);
    }
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
