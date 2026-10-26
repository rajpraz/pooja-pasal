import 'package:google_sign_in/google_sign_in.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';

/// Gets a Google ID token for the API to verify. The token is requested for
/// the OAuth *web/server* client id: the project's Web client by default, or
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=<id>.apps.googleusercontent.com`.
/// The same id must be in the API's `GOOGLE_CLIENT_IDS`.
class GoogleIdTokenSource {
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    // The project's Web OAuth client (a public identifier, not a secret).
    defaultValue: '64467931721-h9qjlnnaldcpdh084235ogi1k61dt094.apps.googleusercontent.com',
  );

  Future<void>? _initialized;

  /// The signed-in Google account's ID token, or null if the user backed out.
  Future<String?> idToken() async {
    if (_serverClientId.isEmpty) {
      throw const AuthException('unavailable', 'Google sign-in is not set up yet.');
    }
    final google = GoogleSignIn.instance;
    await (_initialized ??= google.initialize(serverClientId: _serverClientId));
    try {
      // Forget the previous choice so the account picker shows every time.
      await google.signOut();
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AuthException('invalid-credentials', 'Google sign-in failed. Please try again.');
      }
      return token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AuthException('unavailable', 'Google sign-in failed. Please try again.');
    }
  }
}
