import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/widgets/app_bottom_nav.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/categories/domain/entities/category.dart';
import 'package:pooja_pasal/features/categories/presentation/providers/category_providers.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Category grid (active categories, admin-managed). Product counts are
/// derived client-side from `activeProductsProvider` (see
/// `productCountByCategoryProvider`) rather than a request per category.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  /// The category's own photo when an admin uploaded one, else its badge.
  Widget _buildImage(Category category) {
    final badge = CategoryBadge(category: category.name, size: 52);
    if (category.imageUrl.isEmpty) return badge;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(category.imageUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => badge),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final counts = ref.watch(productCountByCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) =>
            Center(child: Text('Could not load categories: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyView(
              icon: Icons.grid_view_outlined,
              title: 'No categories yet',
              subtitle: 'Check back soon — we\'re still setting these up.',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final Category category = categories[index];
                final count = counts[category.name] ?? 0;
                return GestureDetector(
                  onTap: () => context
                      .push(RouteNames.categoryProductsPath(category.name)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.05 * 255).round()),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImage(category),
                        const SizedBox(height: 10),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(height: 2),
                          Text('$count item${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.muted)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class CategoryProductsPage extends ConsumerWidget {
  final String category;

  const CategoryProductsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(category),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            Center(child: Text('Could not load products: $err')),
        data: (products) {
          final items = products.where((p) => p.category == category).toList();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 58, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('No items found for this category',
                      style: TextStyle(color: AppColors.muted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              return GestureDetector(
                onTap: () =>
                    context.push(RouteNames.productDetailPath(product.id)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.06 * 255).round()),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                        child: product.image.isEmpty
                            ? Container(
                                width: 110,
                                height: 110,
                                color: AppColors.card,
                                child: Icon(Icons.temple_hindu,
                                    color: AppColors.primary),
                              )
                            : Image.network(
                                product.image,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 110,
                                  height: 110,
                                  color: AppColors.card,
                                  child: Icon(Icons.temple_hindu,
                                      color: AppColors.primary),
                                ),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 8),
                              Text(product.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text('Rs.${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
