import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  /// Emits the current session once it's known (after restoring a saved
  /// token), then on every sign-in / sign-out.
  Stream<AuthSession?> authStateChanges();

  AuthSession? get currentUser;

  /// A profile kept up to date: the caller's own (`/auth/me`), or — for an
  /// admin — any user's.
  Stream<AppUser?> userDocStream(String uid);

  Future<AppUser?> getUserDoc(String uid);

  /// Creates the account and signs in. A [role] of `seller` files a seller
  /// application (needs [shopName]); the account stays a buyer until an
  /// admin approves it.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
    String? shopName,
  });

  /// With [rememberMe] false the session lasts until the app is closed.
  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  });

  /// The email saved by the last "Remember me" sign-in, to pre-fill the form.
  Future<String?> rememberedEmail();

  /// Signs in with Google, creating the account if new. False if the user
  /// dismissed the Google account chooser.
  Future<bool> signInWithGoogle({bool rememberMe = true});

  /// Texts a one-time login code to [phone].
  Future<void> sendOtp(String phone);

  /// Signs in with the code texted to [phone], creating the account if new.
  Future<void> verifyOtp(String phone, String code, {bool rememberMe = true});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  });

  /// Files (or re-files after a rejection) a seller application for the
  /// signed-in buyer.
  Future<void> applyToSell(
      {required String shopName, required String phone, String? reason});

  Future<void> signOut();
}
