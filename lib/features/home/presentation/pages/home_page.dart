import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/widgets/app_bottom_nav.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pooja_pasal/features/products/presentation/pages/festival_collection_page.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/product_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final int _navIndex = 0;

  /// Category shortcuts (each with its own CategoryBadge look), followed
  /// by a "More" tile that lists every category.
  static const _quickCategories = [
    'Pooja Kits',
    'Flowers',
    'Incense',
    'Idols',
    'Diyas',
    'Prasad',
    'Brass Items',
  ];
  static const _moreLabel = 'More';

  /// Festival collections and their colours, in display order.
  static final _festivals = FestivalCollectionPage.colors.entries.toList();

  Widget _buildDrawer(BuildContext context) {
    final user = ref.read(authRepositoryProvider).currentUser;
    Widget tile(IconData icon, String label, VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      );
    }

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.brand),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.accentLight,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.email ?? 'Welcome',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            tile(Icons.person_outline, 'Profile', () => context.push(RouteNames.profile)),
            tile(Icons.grid_view_outlined, 'Categories', () => context.push(RouteNames.categories)),
            tile(Icons.favorite_border, 'Wishlist', () => context.push(RouteNames.wishlist)),
            tile(Icons.receipt_long_outlined, 'Order History',
                () => context.push(RouteNames.orders)),
            tile(Icons.location_on_outlined, 'Addresses', () => context.push(RouteNames.addresses)),
            tile(Icons.help_outline, 'Help & Support', () => context.push(RouteNames.helpSupport)),
            const Spacer(),
            const Divider(height: 1),
            tile(Icons.logout, 'Log out', () async {
              await ref.read(signOutActionProvider)();
              if (!context.mounted) return;
              context.go(RouteNames.login);
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final featuredAsync = ref.watch(homeFeaturedProductsProvider);
    final cartAsync = uid == null ? null : ref.watch(cartProvider(uid));
    final cartCount = cartAsync?.value?.length ?? 0;
    final notificationsAsync = uid == null ? null : ref.watch(notificationsProvider(uid));
    final unreadCount = notificationsAsync?.value?.where((n) => !n.read).length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar: menu, title, bell
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: Icon(Icons.menu, color: AppColors.text),
                        tooltip: 'Menu',
                      ),
                    ),
                    const Spacer(),
                    Text('Pooja Pasal',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push(RouteNames.notifications),
                      icon: unreadCount > 0
                          ? Badge(
                              label: Text('$unreadCount'),
                              backgroundColor: AppColors.accent,
                              child: Icon(Icons.notifications_none, color: AppColors.text),
                            )
                          : Icon(Icons.notifications_none, color: AppColors.text),
                      tooltip: 'Notifications',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Deliver to
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(RouteNames.addresses),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('Deliver to', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(width: 6),
                        const Text('Kathmandu, Nepal',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Search bar — opens the real search page instead of
                // filtering an already-loaded list inline.
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push(RouteNames.search),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.muted),
                        const SizedBox(width: 10),
                        Text('Search for pooja items, brands...',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Offer banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppColors.brand, AppColors.brandDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dashain\nSpecial Offer',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('Up to 20% OFF',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: const Text('Shop Now',
                                  style: TextStyle(
                                      color: AppColors.brand,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.temple_hindu, size: 64, color: Colors.white24),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Categories grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categories',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text)),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.categories),
                      child:
                          Text('View All', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickCategories.length + 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 84,
                  ),
                  itemBuilder: (context, index) {
                    final isMore = index == _quickCategories.length;
                    final name = isMore ? _moreLabel : _quickCategories[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      // Each tile opens its own category; "More" lists them all.
                      onTap: () => context.push(
                          isMore ? RouteNames.categories : RouteNames.categoryProductsPath(name)),
                      child: Column(
                        children: [
                          CategoryBadge(
                              category: name, icon: isMore ? Icons.grid_view_outlined : null),
                          const SizedBox(height: 6),
                          Text(name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),

                // Festival collections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Festival Collections',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text)),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.festivals),
                      child:
                          Text('View All', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _festivals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final MapEntry(key: festival, value: color) = _festivals[index];
                      return GestureDetector(
                        onTap: () => context.push(RouteNames.festivalCollectionPath(festival)),
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: color,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.temple_hindu,
                                      color: Colors.white24, size: 36),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  '$festival\nCollection',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // Featured products (bounded first page; full paginated
                // browse lives at /products via "View All").
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Featured Products',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text)),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.products),
                      child:
                          Text('View All', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                featuredAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, st) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text('Could not load products: $err',
                            style: TextStyle(color: AppColors.muted))),
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: Text('No products yet. Check back soon!',
                                style: TextStyle(color: AppColors.muted))),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: page.items.length,
                      gridDelegate: const ProductGridDelegate(),
                      itemBuilder: (context, index) => ProductCard(product: page.items[index]),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        cartCount: cartCount,
      ),
    );
  }
}
