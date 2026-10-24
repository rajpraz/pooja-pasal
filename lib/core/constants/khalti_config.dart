import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';

/// Khalti merchant *public* key (safe to ship in the app; the secret key
/// lives only on the server as `KHALTI_SECRET_KEY`). Test keys only work
/// with the sandbox, so the environment follows the key — keep it in step
/// with the API's `KHALTI_BASE_URL` (sandbox by default).
class KhaltiKeys {
  static const String publicKey = 'test_public_key_5c5fa086bb704a54b1efd924a2acb036';

  static Environment get environment =>
      publicKey.startsWith('test_') ? Environment.test : Environment.prod;
}
