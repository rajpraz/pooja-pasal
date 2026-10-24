import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';

/// Adds every item from a past [order] back to the cart. Each product is
/// re-checked against its *current* state (it may have changed price, gone
/// out of stock, or been deleted since the order was placed) — items that
/// are no longer purchasable are skipped and reported back to the buyer by
/// name rather than silently dropped. The API still re-validates
/// everything again at checkout regardless.
Future<void> reorder(BuildContext context, WidgetRef ref, PoojaOrder order) async {
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return;

  final productRepository = ref.read(productRepositoryProvider);
  final cartController = ref.read(cartControllerProvider.notifier);
  final unavailable = <String>[];
  var addedCount = 0;

  for (final item in order.items) {
    try {
      final product = await productRepository.getProduct(item.productId);
      if (product == null || !product.isActive || product.stock < 1) {
        unavailable.add(item.name);
        continue;
      }
      final qty = item.qty > product.stock ? product.stock : item.qty;
      await cartController.addToCart(uid, product, qty: qty);
      addedCount++;
    } catch (_) {
      unavailable.add(item.name);
    }
  }

  if (!context.mounted) return;
  if (addedCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('None of these items are available to reorder right now.')));
    return;
  }
  final message = unavailable.isEmpty
      ? 'Added $addedCount item(s) to your cart.'
      : 'Added $addedCount item(s) to your cart. Not available: ${unavailable.join(', ')}.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
