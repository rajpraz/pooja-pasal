/// Centralized route *paths* (not widget references) for the whole app.
/// Every page navigates by pushing/going to one of these strings — never by
/// importing another feature's page class directly. Resource-specific
/// pages take a stable ID path parameter rather than a whole object; see
/// `app_router.dart` for how each path parameter is read back out.
class RouteNames {
  RouteNames._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';

  /// Full unfiltered product grid (Home's "View All"). Self-fetches via
  /// `activeProductsProvider` rather than receiving the list through the
  /// constructor.
  static const products = '/products';

  /// Debounced prefix search over the active product catalog — see the
  /// batch-2 report for the documented scale limitation of this
  /// implementation.
  static const search = '/search';

  /// Product detail is reached by ID; the page fetches the product itself
  /// via `productProvider(productId)` rather than receiving a whole
  /// `Product`/display-map through the constructor.
  static const productDetail = '/products/:productId';
  static String productDetailPath(String productId) => '/products/$productId';

  static const festivals = '/festivals';
  static const festivalCollection = '/festivals/:festival';
  static String festivalCollectionPath(String festival) =>
      '/festivals/${Uri.encodeComponent(festival)}';

  static const categories = '/categories';
  static const categoryProducts = '/categories/:category';
  static String categoryProductsPath(String category) =>
      '/categories/${Uri.encodeComponent(category)}';

  static const cart = '/cart';
  static const wishlist = '/wishlist';
  static const addresses = '/addresses';

  /// `price` is a plain scalar checkout-summary preview (the authoritative
  /// total is recomputed server-side in createOrder), so it travels as a
  /// query parameter rather than needing an entity of its own.
  static const checkout = '/checkout';
  static String checkoutPath(double price) => '/checkout?price=$price';

  /// eSewa's WebView checkout — pushed with `context.push<bool>(...)`, pops
  /// `true` once `verifyEsewaPayment` has independently confirmed payment,
  /// `false` on failure/cancel/back.
  static const esewaPayment = '/payments/esewa/:orderId';
  static String esewaPaymentPath(String orderId) => '/payments/esewa/$orderId';

  static const orders = '/orders';

  /// Order tracking IS the order-detail page in this app — there's no
  /// separate summary-only view, so one route covers both.
  static const orderTracking = '/orders/:orderId';
  static String orderTrackingPath(String orderId) => '/orders/$orderId';

  static const notifications = '/notifications';

  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const helpSupport = '/help-support';

  /// Seller "products" and "orders" are tabs *within* the dashboard widget
  /// (local tab state, not separate pushed pages) — see
  /// seller_dashboard_page.dart — so there is one route for the dashboard
  /// itself. Adding/editing a product is a genuine separate page.
  static const sellerDashboard = '/seller/dashboard';
  static const sellerProductNew = '/seller/products/new';
  static const sellerProductEdit = '/seller/products/:productId/edit';
  static String sellerProductEditPath(String productId) => '/seller/products/$productId/edit';

  static const adminDashboard = '/admin/dashboard';

  static const adminSellers = '/admin/sellers';
  static const adminSellerDetail = '/admin/sellers/:uid';
  static String adminSellerDetailPath(String uid) => '/admin/sellers/$uid';

  static const adminCategories = '/admin/categories';

  static const adminProducts = '/admin/products';

  static const adminOrders = '/admin/orders';
  static const adminOrderDetail = '/admin/orders/:orderId';
  static String adminOrderDetailPath(String orderId) => '/admin/orders/$orderId';

  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/:uid';
  static String adminUserDetailPath(String uid) => '/admin/users/$uid';

  static const adminReviews = '/admin/reviews';
}
