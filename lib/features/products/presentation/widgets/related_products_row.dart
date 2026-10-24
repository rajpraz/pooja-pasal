import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/product_card.dart';

/// Same-category products, excluding the one being viewed. Reuses whatever
/// `activeProductsProvider` already has loaded elsewhere in the app rather
/// than issuing a new query — this is a small, already-cached list, not
/// worth a dedicated fetch.
class RelatedProductsRow extends ConsumerWidget {
  final Product current;

  const RelatedProductsRow({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);

    return productsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (products) {
        final related = products
            .where((p) => p.category == current.category && p.id != current.id)
            .take(10)
            .toList();
        if (related.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You may also like',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 10),
            SizedBox(
              height: ProductCard.heightFor(150),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    SizedBox(width: 150, child: ProductCard(product: related[index])),
              ),
            ),
          ],
        );
      },
    );
  }
}
