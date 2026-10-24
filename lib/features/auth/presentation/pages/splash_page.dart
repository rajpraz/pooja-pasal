import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final minSplash = Future<void>.delayed(const Duration(seconds: 2));
    final authRepository = ref.read(authRepositoryProvider);
    // The saved session is restored asynchronously (a `/auth/me` call), so
    // wait for it rather than reading `currentUser` too early.
    final user = await authRepository.authStateChanges().first;

    String destination;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      destination = seenOnboarding ? RouteNames.login : RouteNames.onboarding;
    } else {
      final appUser = await authRepository.getUserDoc(user.uid);
      if (appUser == null) {
        // The saved session no longer resolves to a profile.
        await authRepository.signOut();
        destination = RouteNames.login;
      } else if (appUser.role == 'admin') {
        destination = RouteNames.adminDashboard;
      } else {
        destination = appUser.isSeller ? RouteNames.sellerDashboard : RouteNames.home;
      }
    }

    await minSplash;
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    // A fixed, branded screen (same in light and dark), like a launch image.
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brandDeep, AppColors.brand, AppColors.saffron],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.saffron.withValues(alpha: 0.45),
                        blurRadius: 40,
                        spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.temple_hindu, size: 84, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text('Pooja Pasal',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('Everything for your puja, delivered with devotion',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
              const Spacer(flex: 3),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
