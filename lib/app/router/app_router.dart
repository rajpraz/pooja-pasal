import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_guards.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/features/addresses/presentation/pages/addresses_page.dart';
import 'package:pooja_pasal/features/admin/categories/presentation/pages/admin_categories_page.dart';
import 'package:pooja_pasal/features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:pooja_pasal/features/admin/orders/presentation/pages/admin_order_detail_page.dart';
import 'package:pooja_pasal/features/admin/orders/presentation/pages/admin_orders_page.dart';
import 'package:pooja_pasal/features/admin/products/presentation/pages/admin_products_page.dart';
import 'package:pooja_pasal/features/admin/reviews/presentation/pages/admin_reviews_page.dart';
import 'package:pooja_pasal/features/admin/sellers/presentation/pages/admin_seller_detail_page.dart';
import 'package:pooja_pasal/features/admin/sellers/presentation/pages/admin_sellers_page.dart';
import 'package:pooja_pasal/features/admin/users/presentation/pages/admin_user_detail_page.dart';
import 'package:pooja_pasal/features/admin/users/presentation/pages/admin_users_page.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/login_page.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/onboarding_page.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/otp_login_page.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/signup_page.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/splash_page.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/presentation/pages/cart_page.dart';
import 'package:pooja_pasal/features/categories/presentation/pages/categories_page.dart';
import 'package:pooja_pasal/features/checkout/presentation/pages/checkout_page.dart';
import 'package:pooja_pasal/features/home/presentation/pages/home_page.dart';
import 'package:pooja_pasal/features/notifications/presentation/pages/notification_page.dart';
import 'package:pooja_pasal/features/orders/presentation/pages/order_history_page.dart';
import 'package:pooja_pasal/features/orders/presentation/pages/track_order_page.dart';
import 'package:pooja_pasal/features/payments/presentation/pages/esewa_payment_page.dart';
import 'package:pooja_pasal/features/products/presentation/pages/all_products_page.dart';
import 'package:pooja_pasal/features/products/presentation/pages/festival_collection_page.dart';
import 'package:pooja_pasal/features/products/presentation/pages/product_detail_page.dart';
import 'package:pooja_pasal/features/products/presentation/pages/search_page.dart';
import 'package:pooja_pasal/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:pooja_pasal/features/profile/presentation/pages/help_support_page.dart';
import 'package:pooja_pasal/features/profile/presentation/pages/profile_page.dart';
import 'package:pooja_pasal/features/seller/dashboard/presentation/pages/seller_dashboard_page.dart';
import 'package:pooja_pasal/features/seller/products/presentation/pages/add_product_page.dart';
import 'package:pooja_pasal/features/wishlist/presentation/pages/wishlist_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshStream =
      GoRouterRefreshStream(authRepository.authStateChanges());
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refreshStream,
    redirect: (context, state) => routeGuard(ref, state),
    routes: [
      GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage()),
      GoRoute(
          path: RouteNames.onboarding,
          builder: (context, state) => const OnboardingPage()),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) =>
            LoginPage(role: state.uri.queryParameters['role'] ?? 'buyer'),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) =>
            SignUpPage(role: state.uri.queryParameters['role'] ?? 'buyer'),
      ),
      GoRoute(
          path: RouteNames.otpLogin,
          builder: (context, state) => const OtpLoginPage()),
      GoRoute(
          path: RouteNames.forgotPassword,
          builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(
          path: RouteNames.home, builder: (context, state) => const HomePage()),
      GoRoute(
          path: RouteNames.products,
          builder: (context, state) => const AllProductsPage()),
      GoRoute(
          path: RouteNames.search,
          builder: (context, state) => const SearchPage()),
      GoRoute(
        path: RouteNames.productDetail,
        builder: (context, state) =>
            ProductDetailPage(productId: state.pathParameters['productId']!),
      ),
      GoRoute(
          path: RouteNames.festivals,
          builder: (context, state) => const AllFestivalCollectionsPage()),
      GoRoute(
        path: RouteNames.festivalCollection,
        builder: (context, state) => FestivalCollectionPage(
            festival: Uri.decodeComponent(state.pathParameters['festival']!)),
      ),
      GoRoute(
          path: RouteNames.categories,
          builder: (context, state) => const CategoriesPage()),
      GoRoute(
        path: RouteNames.categoryProducts,
        builder: (context, state) => CategoryProductsPage(
            category: Uri.decodeComponent(state.pathParameters['category']!)),
      ),
      GoRoute(
          path: RouteNames.cart, builder: (context, state) => const CartPage()),
      GoRoute(
          path: RouteNames.wishlist,
          builder: (context, state) => const WishlistPage()),
      GoRoute(
          path: RouteNames.addresses,
          builder: (context, state) => const AddressesPage()),
      GoRoute(
        path: RouteNames.checkout,
        builder: (context, state) => CheckoutPage(
            price:
                double.tryParse(state.uri.queryParameters['price'] ?? '') ?? 0),
      ),
      GoRoute(
        path: RouteNames.esewaPayment,
        builder: (context, state) =>
            EsewaPaymentPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
          path: RouteNames.orders,
          builder: (context, state) => const OrderHistoryPage()),
      GoRoute(
        path: RouteNames.orderTracking,
        builder: (context, state) =>
            TrackOrderPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
          path: RouteNames.notifications,
          builder: (context, state) => const NotificationsPage()),
      GoRoute(
          path: RouteNames.profile,
          builder: (context, state) => const ProfilePage()),
      GoRoute(
          path: RouteNames.editProfile,
          builder: (context, state) => const EditProfilePage()),
      GoRoute(
          path: RouteNames.helpSupport,
          builder: (context, state) => const HelpSupportPage()),
      GoRoute(
          path: RouteNames.sellerDashboard,
          builder: (context, state) => const SellerDashboardPage()),
      GoRoute(
        path: RouteNames.sellerProductNew,
        builder: (context, state) => const AddProductPage(),
      ),
      GoRoute(
        path: RouteNames.sellerProductEdit,
        builder: (context, state) =>
            AddProductPage(productId: state.pathParameters['productId']!),
      ),
      GoRoute(
          path: RouteNames.adminDashboard,
          builder: (context, state) => const AdminDashboardPage()),
      GoRoute(
          path: RouteNames.adminSellers,
          builder: (context, state) => const AdminSellersPage()),
      GoRoute(
        path: RouteNames.adminSellerDetail,
        builder: (context, state) =>
            AdminSellerDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
          path: RouteNames.adminCategories,
          builder: (context, state) => const AdminCategoriesPage()),
      GoRoute(
          path: RouteNames.adminProducts,
          builder: (context, state) => const AdminProductsPage()),
      GoRoute(
          path: RouteNames.adminOrders,
          builder: (context, state) => const AdminOrdersPage()),
      GoRoute(
        path: RouteNames.adminOrderDetail,
        builder: (context, state) =>
            AdminOrderDetailPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
          path: RouteNames.adminUsers,
          builder: (context, state) => const AdminUsersPage()),
      GoRoute(
        path: RouteNames.adminUserDetail,
        builder: (context, state) =>
            AdminUserDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
          path: RouteNames.adminReviews,
          builder: (context, state) => const AdminReviewsPage()),
    ],
  );
});
