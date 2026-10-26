import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/app_bottom_nav.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:pooja_pasal/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  Future<void> _remove(
      BuildContext context, WidgetRef ref, String uid, String productId) async {
    try {
      await ref
          .read(wishlistControllerProvider.notifier)
          .remove(uid, productId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Wishlist')),
        body: EmptyView(
          icon: Icons.favorite_border,
          title: 'Sign in to save items',
          subtitle:
              'Your wishlist syncs across devices once you\'re signed in.',
          action: ElevatedButton(
            onPressed: () => context.go('${RouteNames.login}?role=buyer'),
            child: const Text('Sign In'),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      );
    }

    final wishlistAsync = ref.watch(wishlistProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite, color: AppColors.accent),
          ),
        ],
      ),
      body: wishlistAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) =>
            Center(child: Text('Could not load wishlist: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Tap the heart icon on any item to save it here.',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Favorites',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      return _WishlistTile(
                        item: items[index],
                        onRemove: () =>
                            _remove(context, ref, uid, items[index].productId),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

/// Resolves the live product for a saved [item] and renders it — handles
/// the product having since been deleted (removed by the seller) or gone
/// out of stock, rather than trusting whatever data was true at save time.
class _WishlistTile extends ConsumerWidget {
  final WishlistItem item;
  final VoidCallback onRemove;

  const _WishlistTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(item.productId));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 8,
              spreadRadius: 1),
        ],
      ),
      child: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _unavailableTile('Could not load this item'),
        data: (product) {
          if (product == null) return _unavailableTile('No longer available');
          return _productTile(context, product);
        },
      ),
    );
  }

  Widget _unavailableTile(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(Icons.remove_shopping_cart_outlined,
                color: AppColors.muted, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(message,
            maxLines: 2,
            style:
                TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child:
              OutlinedButton(onPressed: onRemove, child: const Text('Remove')),
        ),
      ],
    );
  }

  Widget _productTile(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.productDetailPath(product.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ProductImage(
                        url: product.image,
                        category: product.category,
                        name: product.name,
                        borderRadius: BorderRadius.zero),
                  ),
                ),
                if (product.stock == 0)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Out of stock',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: onRemove,
                      tooltip: 'Remove from wishlist',
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          minimumSize: const Size(44, 44)),
                      icon: Icon(Icons.favorite,
                          size: 16, color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Rs.${product.price.toStringAsFixed(0)}',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
