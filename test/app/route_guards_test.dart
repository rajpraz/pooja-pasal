import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooja_pasal/app/router/route_guards.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';

AppUser _profile(String uid, String role) => AppUser(
    uid: uid,
    name: 'X',
    email: 'x@example.com',
    phone: '',
    role: role,
    address: '');

void main() {
  const seller = AuthSession(uid: 's1', email: 's@example.com');
  const signedIn = AsyncData<AuthSession?>(seller);
  const signedOut = AsyncData<AuthSession?>(null);

  String? go(String path, AsyncValue<AuthSession?> session,
          [AppUser? profile]) =>
      redirectFor(path: path, session: session, profile: profile);

  group('signed out', () {
    test('protected screens go to login; public ones stay', () {
      expect(go(RouteNames.cart, signedOut), RouteNames.login);
      expect(go('/seller/dashboard', signedOut), RouteNames.login);
      expect(go(RouteNames.login, signedOut), isNull);
      expect(go(RouteNames.signup, signedOut), isNull);
    });

    test('nothing moves while the saved session is still being restored', () {
      expect(go(RouteNames.cart, const AsyncLoading()), isNull);
      expect(go(RouteNames.splash, signedOut), isNull,
          reason: 'splash decides for itself');
    });
  });

  group('signed in', () {
    test('auth screens send each role to its own start screen', () {
      expect(go(RouteNames.login, signedIn, _profile('s1', 'seller')),
          RouteNames.sellerDashboard);
      expect(go(RouteNames.login, signedIn, _profile('s1', 'admin')),
          RouteNames.adminDashboard);
      expect(go(RouteNames.signup, signedIn, _profile('s1', 'buyer')),
          RouteNames.home);
    });

    test('until the profile loads, splash works out the role', () {
      expect(go(RouteNames.login, signedIn), RouteNames.splash);
    });

    test("a previous account's profile never decides where the new one goes",
        () {
      // Switching from a buyer to this seller: the buyer's profile is still
      // the loaded one for a moment.
      final stale = _profile('b1', 'buyer');
      expect(go(RouteNames.login, signedIn, stale), RouteNames.splash);
      expect(go('/seller/dashboard', signedIn, stale), isNull,
          reason: 'wait, do not bounce');
    });

    test('role areas are guarded', () {
      expect(
          go('/seller/dashboard', signedIn, _profile('s1', 'seller')), isNull);
      expect(go('/seller/dashboard', signedIn, _profile('s1', 'buyer')),
          RouteNames.home);
      expect(go('/admin/dashboard', signedIn, _profile('s1', 'seller')),
          RouteNames.home);
      expect(go('/admin/dashboard', signedIn, _profile('s1', 'admin')), isNull);
      expect(go(RouteNames.cart, signedIn, _profile('s1', 'buyer')), isNull);
    });
  });

  test('homeForRole', () {
    expect(homeForRole('admin'), RouteNames.adminDashboard);
    expect(homeForRole('seller'), RouteNames.sellerDashboard);
    expect(homeForRole('buyer'), RouteNames.home);
    expect(homeForRole('anything'), RouteNames.home);
  });
}
