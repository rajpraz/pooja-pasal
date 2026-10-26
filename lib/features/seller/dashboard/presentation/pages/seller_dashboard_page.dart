import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/app/theme/appearance_sheet.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/core/widgets/stat_card.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/seller/dashboard/domain/entities/seller_dashboard_stats.dart';
import 'package:pooja_pasal/features/seller/dashboard/presentation/providers/seller_dashboard_stats_provider.dart';
import 'package:pooja_pasal/features/seller/orders/presentation/pages/seller_orders_page.dart';

class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() =>
      _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> {
  int _tab = 0;

  /// Sellers can't hard-delete a product (that's admin-only, since a
  /// deleted product could still be referenced by historical orders) —
  /// this toggles `isActive` instead.
  Future<void> _confirmToggleActive(Product product) async {
    final activating = !product.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activating ? 'Reactivate product?' : 'Deactivate product?'),
        content: Text(activating
            ? '"${product.name}" will be visible to buyers again.'
            : '"${product.name}" will be hidden from buyers. You can reactivate it any time.'),
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
    if (confirmed != true) return;

    try {
      await ref
          .read(productRepositoryProvider)
          .updateProduct(product.id, {'isActive': activating});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                activating ? 'Product reactivated.' : 'Product deactivated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> logout() async {
    await ref.read(signOutActionProvider)();
    if (!mounted) return;
    context.go('${RouteNames.login}?role=seller');
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final productsAsync = ref.watch(sellerProductsProvider(uid));
    final statsAsync = ref.watch(sellerDashboardStatsProvider(uid));
    final stats = statsAsync.value ?? const SellerDashboardStats();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Sell Pooja Items' : 'Incoming Orders'),
        actions: [
          const AppearanceButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.sellerProductNew),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined), label: 'My Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        ],
      ),
      body: _tab == 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // A fixed tile height (not an aspect ratio) so the value and label
                    // always fit, whatever the screen width.
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: StatCard.height,
                    ),
                    children: [
                      StatCard(
                          icon: Icons.today_outlined,
                          label: "Today's Sales",
                          value: 'Rs.${stats.todaySales.toStringAsFixed(0)}'),
                      StatCard(
                          icon: Icons.payments_outlined,
                          label: 'Total Sales',
                          value: 'Rs.${stats.totalSales.toStringAsFixed(0)}'),
                      StatCard(
                          icon: Icons.storefront_outlined,
                          label: 'Total Products',
                          value: '${stats.totalProducts}'),
                      StatCard(
                          icon: Icons.pending_actions_outlined,
                          label: 'Pending Orders',
                          value: '${stats.pendingOrders}'),
                      StatCard(
                          icon: Icons.local_shipping_outlined,
                          label: 'Shipped Orders',
                          value: '${stats.shippedOrders}'),
                      StatCard(
                          icon: Icons.warning_amber_outlined,
                          label: 'Low Stock',
                          value: '${stats.lowStockProducts}',
                          color: stats.lowStockProducts > 0
                              ? AppColors.error
                              : null),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: productsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) =>
                          Center(child: Text('Could not load products: $err')),
                      data: (products) {
                        if (products.isEmpty) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 70, color: AppColors.primary),
                              const SizedBox(height: 16),
                              const Text('No products yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                'Add your own pooja items and let buyers discover them.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () =>
                                    context.push(RouteNames.sellerProductNew),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                child: const Text('Add your first item'),
                              )
                            ],
                          );
                        }
                        return ListView.builder(
                          // Room for the "+" button over the last row.
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Opacity(
                                opacity: product.isActive ? 1 : 0.6,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  // ListTile caps leading height, so keep it a true square.
                                  leading: ProductImage(
                                    url: product.image,
                                    category: product.category,
                                    name: product.name,
                                    width: 48,
                                    height: 48,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                          child: Text(product.name,
                                              overflow: TextOverflow.ellipsis)),
                                      if (!product.isActive)
                                        _badge('Inactive', AppColors.muted)
                                      else if (product.isOutOfStock)
                                        _badge('Out of stock', AppColors.error)
                                      else if (product.isLowStock)
                                        _badge('Low stock', AppColors.accent),
                                    ],
                                  ),
                                  subtitle: Text(
                                      'Rs.${product.price.toStringAsFixed(0)} • Stock: ${product.stock} • ${product.category}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined,
                                            color: AppColors.primary),
                                        tooltip: 'Edit product',
                                        onPressed: () => context.push(
                                            RouteNames.sellerProductEditPath(
                                                product.id)),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            product.isActive
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: product.isActive
                                                ? AppColors.error
                                                : AppColors.success),
                                        tooltip: product.isActive
                                            ? 'Deactivate'
                                            : 'Reactivate',
                                        onPressed: () =>
                                            _confirmToggleActive(product),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : const SellerOrdersPage(),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
