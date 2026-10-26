import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_filter_providers.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_list_controller.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/product_card.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/product_filter_sheet.dart';

/// Full, paginated product browse — reached from Home's "View All". Backed
/// by `productListControllerProvider` (server-paginated, 20/page) rather
/// than the unbounded `activeProductsProvider` stream; category/price/
/// rating/stock filters are applied client-side on top of loaded pages
/// (see `ProductFilter.matches`), sort is a server-side `orderBy`.
class AllProductsPage extends ConsumerStatefulWidget {
  const AllProductsPage({super.key});

  @override
  ConsumerState<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends ConsumerState<AllProductsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(productListControllerProvider);
    final filter = ref.watch(productFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Products'),
        actions: [
          IconButton(
            tooltip: 'Filter & sort',
            onPressed: () => showProductFilterSheet(context),
            icon: Badge(
              isLabelVisible: !filter.isDefault,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) =>
            Center(child: Text('Could not load products: $err')),
        data: (list) {
          final visible = list.rawItems.where(filter.matches).toList();

          if (visible.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 56, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('No products match your filters.',
                      style: TextStyle(color: AppColors.muted)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              controller: _scrollController,
              itemCount: visible.length + (list.hasMore ? 1 : 0),
              gridDelegate: const ProductGridDelegate(),
              itemBuilder: (context, index) {
                if (index >= visible.length) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator()));
                }
                final Product product = visible[index];
                return ProductCard(product: product);
              },
            ),
          );
        },
      ),
    );
  }
}
