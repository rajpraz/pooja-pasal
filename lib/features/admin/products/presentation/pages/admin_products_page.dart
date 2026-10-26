import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/admin/products/presentation/providers/admin_product_filter_provider.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Product moderation: view/filter every product (active + inactive, all
/// sellers) and activate/deactivate, via the same
/// `ProductRepository.updateProduct` sellers use on their own products —
/// the API lets admins manage any product. Deliberately does NOT support
/// reassigning a product's seller.
class AdminProductsPage extends ConsumerWidget {
  const AdminProductsPage({super.key});

  bool _matches(Product p, AdminProductFilter filter) {
    switch (filter) {
      case AdminProductFilter.all:
        return true;
      case AdminProductFilter.active:
        return p.isActive;
      case AdminProductFilter.inactive:
        return !p.isActive;
      case AdminProductFilter.lowStock:
        return p.isLowStock || p.isOutOfStock;
    }
  }

  String _label(AdminProductFilter f) => switch (f) {
        AdminProductFilter.all => 'All',
        AdminProductFilter.active => 'Active',
        AdminProductFilter.inactive => 'Inactive',
        AdminProductFilter.lowStock => 'Low stock',
      };

  Future<void> _toggleActive(
      BuildContext context, WidgetRef ref, Product product) async {
    final activating = !product.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activating ? 'Reactivate product?' : 'Deactivate product?'),
        content: Text(activating
            ? '"${product.name}" will be visible to buyers again.'
            : '"${product.name}" will be hidden from buyers immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(activating ? 'Reactivate' : 'Deactivate',
                style: TextStyle(
                    color: activating ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(productRepositoryProvider)
          .updateProduct(product.id, {'isActive': activating});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                activating ? 'Product reactivated.' : 'Product deactivated.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  void _showDetail(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
                'Rs.${product.price.toStringAsFixed(0)} • Stock: ${product.stock} • ${product.category}',
                style: TextStyle(color: AppColors.muted)),
            if (product.sellerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Sold by ${product.sellerName}',
                  style: TextStyle(color: AppColors.muted)),
            ],
            const SizedBox(height: 10),
            Text(product.description.isEmpty
                ? 'No description.'
                : product.description),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _toggleActive(context, ref, product);
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor:
                        product.isActive ? AppColors.error : AppColors.success),
                child: Text(product.isActive ? 'Deactivate' : 'Reactivate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminAllProductsProvider);
    final filter = ref.watch(adminProductFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) =>
            Center(child: Text('Could not load products: $err')),
        data: (allProducts) {
          final filtered =
              allProducts.where((p) => _matches(p, filter)).toList();
          return Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: AdminProductFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = AdminProductFilter.values[index];
                    final selected = f == filter;
                    final count =
                        allProducts.where((p) => _matches(p, f)).length;
                    return ChoiceChip(
                      label: Text('${_label(f)} ($count)'),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(adminProductFilterProvider.notifier).set(f),
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                          color: selected ? AppColors.accent : AppColors.muted,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12),
                    );
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyView(
                        icon: Icons.inventory_2_outlined,
                        title: 'No ${_label(filter).toLowerCase()} products',
                        subtitle: 'Try a different filter.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: ProductImage(
                                      url: product.image,
                                      category: product.category,
                                      name: product.name),
                                ),
                              ),
                              title: Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Rs.${product.price.toStringAsFixed(0)} • Stock: ${product.stock}${product.isOutOfStock ? " (out)" : product.isLowStock ? " (low)" : ""}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (product.isActive
                                          ? AppColors.success
                                          : AppColors.muted)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    product.isActive ? 'ACTIVE' : 'INACTIVE',
                                    style: TextStyle(
                                        color: product.isActive
                                            ? AppColors.success
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10)),
                              ),
                              onTap: () => _showDetail(context, ref, product),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
