import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';

/// Shared bottom navigation used across the buyer-facing pages
/// (Home / Categories / Cart / Wishlist / Profile). Self-contained: it
/// knows its own tab→route mapping and navigates via GoRouter directly, so
/// every page that hosts it no longer needs to implement its own `onTap`
/// switch statement (and the imports that existed only to support it).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.cartCount = 0,
  });

  static const _routes = [
    RouteNames.home,
    RouteNames.categories,
    RouteNames.cart,
    RouteNames.wishlist,
    RouteNames.profile,
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    Widget cartIcon = const Icon(Icons.shopping_cart_outlined);
    if (cartCount > 0) {
      cartIcon = Badge(
        label: Text('$cartCount'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.shopping_cart_outlined),
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
        BottomNavigationBarItem(icon: cartIcon, label: 'Cart'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), label: 'Wishlist'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
