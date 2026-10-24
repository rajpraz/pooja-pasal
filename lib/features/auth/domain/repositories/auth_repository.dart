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

  Future<void> signIn({required String email, required String password});

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
  Future<void> applyToSell({required String shopName, required String phone, String? reason});

  Future<void> signOut();
}
