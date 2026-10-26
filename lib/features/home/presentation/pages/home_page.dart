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
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            tile(Icons.person_outline, 'Profile',
                () => context.push(RouteNames.profile)),
            tile(Icons.grid_view_outlined, 'Categories',
                () => context.push(RouteNames.categories)),
            tile(Icons.favorite_border, 'Wishlist',
                () => context.push(RouteNames.wishlist)),
            tile(Icons.receipt_long_outlined, 'Order History',
                () => context.push(RouteNames.orders)),
            tile(Icons.location_on_outlined, 'Addresses',
                () => context.push(RouteNames.addresses)),
            tile(Icons.help_outline, 'Help & Support',
                () => context.push(RouteNames.helpSupport)),
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
    final notificationsAsync =
        uid == null ? null : ref.watch(notificationsProvider(uid));
    final unreadCount =
        notificationsAsync?.value?.where((n) => !n.read).length ?? 0;

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
                // Top bar: menu, brand, bell
                Row(
                  children: [
                    Builder(
                      builder: (context) => _RoundIconButton(
                        icon: Icons.menu,
                        tooltip: 'Menu',
                        onTap: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text('Namaste \u{1F64F}',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                        Text('Pooja Pasal',
                            style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark)),
                      ],
                    ),
                    const Spacer(),
                    _RoundIconButton(
                      icon: Icons.notifications_none,
                      tooltip: 'Notifications',
                      badge: unreadCount,
                      onTap: () => context.push(RouteNames.notifications),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Deliver to
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(RouteNames.addresses),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('Deliver to',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                        const SizedBox(width: 6),
                        const Text('Kathmandu, Nepal',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
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
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Search for pooja items, brands...',
                              style: TextStyle(color: AppColors.muted)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune,
                              size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Offer banner
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.push(RouteNames.products),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.brandDeep, AppColors.brand, AppColors.saffron],
                          stops: [0, 0.55, 1],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            right: -30,
                            top: -30,
                            child: _Ring(size: 150),
                          ),
                          const Positioned(
                            right: 10,
                            bottom: -50,
                            child: _Ring(size: 110),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('LIMITED TIME',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              letterSpacing: 1,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('Dashain\nSpecial Offer',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            height: 1.15,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    const Text('Up to 20% OFF',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Shop Now',
                                              style: TextStyle(
                                                  color: AppColors.brand,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward,
                                              size: 14, color: AppColors.brand),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.temple_hindu,
                                  size: 72, color: Colors.white30),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Categories grid
                _SectionHeader(
                  title: 'Categories',
                  onViewAll: () => context.push(RouteNames.categories),
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
                      onTap: () => context.push(isMore
                          ? RouteNames.categories
                          : RouteNames.categoryProductsPath(name)),
                      child: Column(
                        children: [
                          CategoryBadge(
                              category: name,
                              icon: isMore ? Icons.grid_view_outlined : null),
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
                _SectionHeader(
                  title: 'Festival Collections',
                  onViewAll: () => context.push(RouteNames.festivals),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _festivals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final MapEntry(key: festival, value: color) =
                          _festivals[index];
                      return GestureDetector(
                        onTap: () => context
                            .push(RouteNames.festivalCollectionPath(festival)),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color,
                                Color.lerp(color, Colors.black, 0.28)!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.temple_hindu,
                                      color: Colors.white30, size: 44),
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
                _SectionHeader(
                  title: 'Featured Products',
                  onViewAll: () => context.push(RouteNames.products),
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
                      itemBuilder: (context, index) =>
                          ProductCard(product: page.items[index]),
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

/// "Title ........ View All" row above each home section.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ],
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onViewAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Text('View All',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
                Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round white icon button used in the home top bar; shows an unread badge.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    Widget glyph = Icon(icon, color: AppColors.text, size: 22);
    if (badge > 0) {
      glyph = Badge(
        label: Text('$badge'),
        backgroundColor: AppColors.accent,
        child: glyph,
      );
    }
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: glyph),
        ),
      ),
    );
  }
}

/// Thin decorative ring for the offer banner.
class _Ring extends StatelessWidget {
  const _Ring({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
      ),
    );
  }
}
