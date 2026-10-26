import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/app_bottom_nav.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_line_validation.dart';
import 'package:pooja_pasal/features/cart/domain/pricing_service.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Future<void> _updateQty(BuildContext context, WidgetRef ref, String uid,
      CartLineValidation line, int delta) async {
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .updateQty(uid, line.item.productId, line.item.qty + delta);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update cart: ${friendlyErrorMessage(e)}')));
    }
  }

  Future<void> _removeItem(
      BuildContext context, WidgetRef ref, String uid, String productId) async {
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .removeItem(uid, productId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not remove item: ${friendlyErrorMessage(e)}')));
    }
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref, String uid) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This will remove all items from your cart.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(cartControllerProvider.notifier).clearCart(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cart cleared')));
            },
            child: Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// Checkout is just the next screen (nothing is placed until "Place
  /// Order" there), so there's no "are you sure?" step here.
  void _checkout(BuildContext context, double totalPrice) {
    context.push(RouteNames.checkoutPath(totalPrice));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
          body: Center(child: Text('Please log in to view your cart')));
    }

    final validationAsync = ref.watch(cartValidationProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (validationAsync.hasValue && validationAsync.value!.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear cart',
                onPressed: () => _confirmClearCart(context, ref, uid))
        ],
      ),
      body: validationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load cart: $err')),
        data: (lines) {
          final totalPrice = PricingService.subtotalFromValidated(lines);
          final hasBlockingIssue = lines.any((line) => !line.isPurchasable);

          return Column(
            children: [
              Expanded(
                child: lines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 60, color: AppColors.accent),
                            const SizedBox(height: 10),
                            const Text('Your cart is empty',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Add puja essentials to start your order.',
                                style: TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.go(RouteNames.home),
                              child: const Text('Browse Products'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          return _CartLineTile(
                            line: line,
                            onIncrease: () =>
                                _updateQty(context, ref, uid, line, 1),
                            onDecrease: () =>
                                _updateQty(context, ref, uid, line, -1),
                            onRemove: () => _removeItem(
                                context, ref, uid, line.item.productId),
                          );
                        },
                      ),
              ),
              if (lines.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Color.fromRGBO(158, 158, 158, 0.4),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, -2))
                    ],
                  ),
                  child: Column(
                    children: [
                      if (hasBlockingIssue)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Some items are unavailable or low on stock. Remove or adjust them to continue.',
                                    style: TextStyle(
                                        color: AppColors.error, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text('Estimated delivery: 2-4 days',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(fontSize: 16)),
                            Text('Rs.${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600))
                          ]),
                      // Coupons are applied at checkout; only show a row here
                      // when there is something to take off.
                      if (PricingService.discount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount',
                                  style: TextStyle(fontSize: 16)),
                              Text(
                                  '- Rs.${PricingService.discount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16))
                            ]),
                      ],
                      const SizedBox(height: 6),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Charge',
                                style: TextStyle(fontSize: 16)),
                            Text(
                                'Rs.${PricingService.deliveryFee.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16))
                          ]),
                      const Divider(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                'Rs.${PricingService.totalFromValidated(lines).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold))
                          ]),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: hasBlockingIssue
                                  ? null
                                  : () => _checkout(context, totalPrice),
                              child: const Text('Proceed to Checkout'))),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

/// Renders a single cart line against the validation already computed by
/// `cartValidationProvider` (its live-product check) rather than each tile
/// re-querying the product itself.
class _CartLineTile extends StatelessWidget {
  final CartLineValidation line;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartLineTile({
    required this.line,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  String? get _issue {
    if (!line.exists) return 'No longer available';
    if (!line.isActive) return 'No longer available';
    final stock = line.product?.stock ?? 0;
    if (stock == 0) return 'Out of stock';
    if (stock < line.item.qty) return 'Only $stock left';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final issue = _issue;
    final stock = line.product?.stock ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: issue != null
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
            : null,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          ProductImage(
              url: line.item.image,
              name: line.item.name,
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(10)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Rs.${line.effectivePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                    if (line.priceChanged) ...[
                      const SizedBox(width: 6),
                      Text('(was Rs.${line.item.price.toStringAsFixed(0)})',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                if (issue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(issue,
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove, size: 16),
                      tooltip: 'Decrease quantity',
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.card,
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${line.item.qty}'),
                    ),
                    IconButton(
                      onPressed: (line.exists && line.item.qty >= stock)
                          ? null
                          : onIncrease,
                      icon: const Icon(Icons.add, size: 16),
                      tooltip: 'Increase quantity',
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.card,
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.primary),
              tooltip: 'Remove item',
              onPressed: onRemove),
        ],
      ),
    );
  }
}
