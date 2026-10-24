import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/related_products_row.dart';
import 'package:pooja_pasal/features/reviews/presentation/widgets/review_list.dart';
import 'package:pooja_pasal/features/wishlist/presentation/providers/wishlist_providers.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int quantity = 1;
  bool _expanded = false;
  int _imageIndex = 0;
  final _imageController = PageController();

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _shareProduct(Product product) {
    Clipboard.setData(
        ClipboardData(text: 'Check out ${product.name} on Pooja Pasal - Rs.${product.price}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product details copied to clipboard')),
    );
  }

  Widget _buildGallery(Product product) {
    final images = product.images.isEmpty ? [''] : product.images;
    return Column(
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 16, spreadRadius: 1)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: _imageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemBuilder: (context, index) => ProductImage(
                  url: images[index],
                  category: product.category,
                  name: product.name,
                  borderRadius: BorderRadius.zero,
                  iconScale: 0.22),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _imageIndex == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _imageIndex == i ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> addToCart(Product product) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(cartControllerProvider.notifier).addToCart(uid, product, qty: quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $quantity ${product.name} to cart')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add to cart: ${friendlyErrorMessage(e)}')),
      );
    }
  }

  Future<void> _toggleWishlist(String productId) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in to save items.')));
      return;
    }
    final isSaved = await ref.read(wishlistControllerProvider.notifier).toggle(uid, productId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isSaved ? 'Added to wishlist' : 'Removed from wishlist')),
    );
  }

  Future<void> buyNow(Product product) async {
    await addToCart(product);
    if (!mounted) return;
    unawaited(context.push(RouteNames.cart));
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Product Details')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load product: $err')),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          return _buildBody(product);
        },
      ),
    );
  }

  Widget _buildBody(Product product) {
    final description =
        product.description.isEmpty ? 'No description available' : product.description;
    final shortDescription =
        description.length > 90 && !_expanded ? '${description.substring(0, 90)}...' : description;

    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final saved = uid == null
        ? false
        : ref.watch(wishlistProvider(uid)
            .select((state) => state.value?.any((e) => e.productId == product.id) ?? false));
    final inStock = product.stock > 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGallery(product),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(product.name,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                ),
                IconButton(
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                        color: saved ? AppColors.accent : null),
                    tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
                    onPressed: () => _toggleWishlist(product.id)),
                IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Share product',
                    onPressed: () => _shareProduct(product)),
              ],
            ),
            const SizedBox(height: 4),
            if (product.ratingCount > 0)
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < product.ratingAverage.round() ? Icons.star : Icons.star_border,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                      '${product.ratingAverage.toStringAsFixed(1)} (${product.ratingCount} reviews)',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            if (product.sellerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Sold by ${product.sellerName}',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
            const SizedBox(height: 8),
            if (product.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(product.category,
                    style: TextStyle(
                        color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Rs.${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Spacer(),
                Text(inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                        color: inStock ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            if (inStock)
              Row(
                children: [
                  Text('Quantity', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () =>
                              setState(() => quantity = quantity > 1 ? quantity - 1 : 1),
                          icon: const Icon(Icons.remove, size: 18),
                          tooltip: 'Decrease quantity',
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.zero)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('$quantity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                          onPressed: quantity >= product.stock
                              ? null
                              : () => setState(() => quantity += 1),
                          icon: const Icon(Icons.add, size: 18),
                          tooltip: 'Increase quantity',
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.zero)),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Text('Product Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(shortDescription,
                style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
            if (description.length > 90)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(_expanded ? 'Show less' : 'Read More',
                      style: TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: inStock ? () => addToCart(product) : null,
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: inStock ? () => buyNow(product) : null,
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Ratings & Reviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 10),
            ReviewList(productId: product.id),
            const SizedBox(height: 20),
            RelatedProductsRow(current: product),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
