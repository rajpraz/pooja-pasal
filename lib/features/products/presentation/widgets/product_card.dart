import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/wishlist/presentation/providers/wishlist_providers.dart';

/// Lays product cards out in as many columns as fit (2 on a phone, up to 4
/// on wide screens), each exactly as tall as the card needs — no dead space
/// under the button, no overflow.
class ProductGridDelegate extends SliverGridDelegate {
  static const double spacing = 12;

  const ProductGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    final columns = (width / 170).floor().clamp(2, 4);
    final tileWidth = (width - spacing * (columns - 1)) / columns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      mainAxisExtent: ProductCard.heightFor(tileWidth),
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) => false;
}

/// Shared product grid tile — used by Home's featured section, the full
/// product browse, search results, and category listings, so the card
/// (image, badges, wishlist toggle, rating, price, add-to-cart) only exists
/// once.
class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  /// Height of the text block under the image.
  static const double _infoHeight = 98;

  /// Total card height for a tile [width] wide: a near-square image plus
  /// the text block. The image is the flexible part, so larger system
  /// fonts shrink it rather than overflowing the card.
  static double heightFor(double width) => (width - 16) * 0.92 + _infoHeight + 16;

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(cartControllerProvider.notifier).addToCart(uid, product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add to cart: ${friendlyErrorMessage(e)}')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final saved = uid == null
        ? false
        : ref.watch(wishlistProvider(uid)
            .select((state) => state.value?.any((e) => e.productId == product.id) ?? false));
    final soldOut = product.isOutOfStock;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteNames.productDetailPath(product.id)),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(
                        url: product.image, category: product.category, name: product.name),
                    if (soldOut)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: const Center(
                            child: Text('Sold out',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                      ),
                    if (product.festivalTag.isNotEmpty)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _Badge(label: product.festivalTag, color: AppColors.brand),
                      ),
                    if (product.isLowStock)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child:
                            _Badge(label: 'Only ${product.stock} left', color: AppColors.saffron),
                      ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton(
                        onPressed: () {
                          if (uid == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please sign in to save items.')));
                            return;
                          }
                          ref.read(wishlistControllerProvider.notifier).toggle(uid, product.id);
                        },
                        tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface.withValues(alpha: 0.92),
                          minimumSize: const Size(36, 36),
                          fixedSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                            size: 18, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: _infoHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(
                          product.sellerName.isEmpty
                              ? product.category
                              : 'by ${product.sellerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(height: 3),
                      if (product.ratingCount > 0)
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                            const SizedBox(width: 2),
                            Text(
                                '${product.ratingAverage.toStringAsFixed(1)} · ${product.ratingCount}',
                                style: TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        )
                      else
                        const SizedBox(height: 14),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Rs.${product.price.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                          IconButton.filled(
                            onPressed: soldOut ? null : () => _addToCart(context, ref),
                            tooltip: soldOut ? 'Sold out' : 'Add to cart',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.border,
                              minimumSize: const Size(34, 34),
                              fixedSize: const Size(34, 34),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
