import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/app/app.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/domain/repositories/auth_repository.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real API-backed [AuthRepository] so this test never
/// makes network calls: the app's root widget is pumped with a fake
/// implementation instead of a live backend.
class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthSession?> authStateChanges() => Stream.value(null);

  @override
  AuthSession? get currentUser => null;

  @override
  Stream<AppUser?> userDocStream(String uid) => Stream.value(null);

  @override
  Future<AppUser?> getUserDoc(String uid) async => null;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
    String? shopName,
  }) async {}

  @override
  Future<void> applyToSell(
      {required String shopName,
      required String phone,
      String? reason}) async {}

  @override
  Future<void> signIn(
      {required String email,
      required String password,
      bool rememberMe = true}) async {}

  @override
  Future<String?> rememberedEmail() async => null;

  @override
  Future<bool> signInWithGoogle({bool rememberMe = true}) async => true;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp(String phone, String code, {bool rememberMe = true}) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('shows the pooja store branding on launch',
      (WidgetTester tester) async {
    // SplashPage reads SharedPreferences (for "seen_onboarding") as part of
    // resolving where to navigate after the splash delay.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository())
      ],
      child: const App(),
    ));

    expect(find.text('Pooja Pasal'), findsOneWidget);

    // Let SplashPage's 2-second minimum splash timer (and the navigation
    // it triggers) run to completion so no timer is left pending when the
    // test tears down.
    await tester.pump(const Duration(seconds: 3));
  });
}
