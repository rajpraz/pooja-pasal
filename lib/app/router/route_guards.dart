import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/domain/entities/auth_session.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

/// Bridges a plain auth-state [Stream] into a [Listenable] GoRouter can use
/// as `refreshListenable`, so it re-evaluates [routeGuard] whenever
/// sign-in state changes — without recreating the `GoRouter` instance
/// itself (which would blow away the navigation stack).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

const Set<String> _publicPaths = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.signup,
  RouteNames.forgotPassword,
  RouteNames.otpLogin,
};

/// This is a navigation-UX guard ONLY — it decides which screen to *show*,
/// nothing more. It is emphatically not the security boundary: the Laravel
/// API checks the caller's role and ownership on every request
/// (`role:admin,seller` middleware, `OrderService`, …). A buyer who somehow
/// reaches a seller screen still can't do anything a seller could there.
/// This guard just avoids showing them that screen in the first place.
///
/// Loop-prevention: every branch below either returns `null` (stay put) or
/// redirects to a path that itself evaluates to `null` on the next pass —
/// login/signup/onboarding only redirect *away* once actually signed in
/// (never redirect *to* themselves), and the seller check only fires for
/// `/seller/...` paths, which `RouteNames.home` never matches.
String? routeGuard(Ref ref, GoRouterState state) => redirectFor(
      path: state.matchedLocation,
      session: ref.read(authStateProvider),
      profile: ref.read(currentUserDocProvider).value,
    );

/// The guard's decision as a pure function (so it can be unit tested):
/// where to send someone on [path], given the [session] state and their
/// loaded [profile]; null means stay.
String? redirectFor({
  required String path,
  required AsyncValue<AuthSession?> session,
  required AppUser? profile,
}) {
  // Splash owns the very first navigation decision — it already resolves
  // onboarding-seen + auth state + role asynchronously (see
  // splash_page.dart) before choosing where to go. Never redirect away
  // from it here, or splash and this guard could fight over the
  // destination before splash's own resolution finishes.
  if (path == RouteNames.splash) return null;

  // Still resolving the persisted session — don't redirect yet, or a
  // signed-in user would flash through /login for a frame.
  if (!session.hasValue) return null;

  final user = session.value;
  if (user == null) {
    return _publicPaths.contains(path) ? null : RouteNames.login;
  }

  // The loaded profile only counts if it belongs to this session: right
  // after switching accounts it can still be the previous user's, whose
  // role must not decide where the new user goes.
  final role = profile != null && profile.uid == user.uid ? profile.role : null;

  // Signed in: auth screens make no sense any more. Send each role to its
  // own start screen; until the profile has loaded, splash resolves it.
  if (path == RouteNames.login ||
      path == RouteNames.signup ||
      path == RouteNames.otpLogin ||
      path == RouteNames.onboarding) {
    return role == null ? RouteNames.splash : homeForRole(role);
  }

  // UX guards only: the API's role middleware is the real boundary.
  if (path.startsWith('/seller')) {
    if (role == null) return null; // wait for this user's profile
    if (role != 'seller') return RouteNames.home;
  }
  if (path.startsWith('/admin')) {
    if (role == null) return null; // wait for this user's profile
    if (role != 'admin') return RouteNames.home;
  }
  return null;
}

/// Where each role starts after signing in.
String homeForRole(String role) => switch (role) {
      'admin' => RouteNames.adminDashboard,
      'seller' => RouteNames.sellerDashboard,
      _ => RouteNames.home,
    };
