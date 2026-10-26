import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/domain/repositories/auth_repository.dart';

/// Opens the right start screen for the account that just signed in.
Future<void> goAfterSignIn(BuildContext context, AuthRepository auth) async {
  final user = auth.currentUser;
  final appUser = user == null ? null : await auth.getUserDoc(user.uid);
  if (!context.mounted) return;
  if (appUser == null) {
    showMessage(context, 'Account profile not found. Please sign up again.');
    return;
  }
  switch (appUser.role) {
    case 'admin':
      context.go(RouteNames.adminDashboard);
    case 'seller':
      context.go(RouteNames.sellerDashboard);
    default:
      context.go(RouteNames.home);
  }
}
