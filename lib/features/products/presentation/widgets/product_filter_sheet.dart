import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/categories/presentation/providers/category_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_filter.dart';
import 'package:pooja_pasal/features/products/domain/entities/product_sort.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_filter_providers.dart';

Future<void> showProductFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ProductFilterSheet(),
  );
}

String _sortLabel(ProductSort sort) => switch (sort) {
      ProductSort.newest => 'Newest',
      ProductSort.priceLowToHigh => 'Price: Low to High',
      ProductSort.priceHighToLow => 'Price: High to Low',
      ProductSort.popularity => 'Most Rated',
    };

class _ProductFilterSheet extends ConsumerStatefulWidget {
  const _ProductFilterSheet();

  @override
  ConsumerState<_ProductFilterSheet> createState() =>
      _ProductFilterSheetState();
}

class _ProductFilterSheetState extends ConsumerState<_ProductFilterSheet> {
  late ProductFilter _draft;
  late RangeValues _priceRange;

  static const _maxPrice = 10000.0;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(productFilterProvider);
    _priceRange =
        RangeValues(_draft.minPrice ?? 0, _draft.maxPrice ?? _maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter & Sort',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() {
                    _draft = const ProductFilter();
                    _priceRange = const RangeValues(0, _maxPrice);
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Sort by',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: ProductSort.values
                  .map((sort) => ChoiceChip(
                        label: Text(_sortLabel(sort)),
                        selected: _draft.sort == sort,
                        onSelected: (_) => setState(
                            () => _draft = _draft.copyWith(sort: sort)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => const SizedBox.shrink(),
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _draft.category == null,
                    onSelected: (_) => setState(
                        () => _draft = _draft.copyWith(clearCategory: true)),
                  ),
                  ...categories.map((c) => ChoiceChip(
                        label: Text(c.name),
                        selected: _draft.category == c.name,
                        onSelected: (_) => setState(
                            () => _draft = _draft.copyWith(category: c.name)),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Price range',
                style: TextStyle(fontWeight: FontWeight.w600)),
            RangeSlider(
              values: _priceRange,
              max: _maxPrice,
              divisions: 20,
              labels: RangeLabels('Rs.${_priceRange.start.round()}',
                  'Rs.${_priceRange.end.round()}'),
              onChanged: (values) => setState(() {
                _priceRange = values;
                _draft = _draft.copyWith(
                    minPrice: values.start, maxPrice: values.end);
              }),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In stock only'),
              value: _draft.inStockOnly,
              activeThumbColor: AppColors.accent,
              onChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(inStockOnly: value)),
            ),
            const Text('Minimum rating',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                for (int stars = 1; stars <= 5; stars++)
                  IconButton(
                    onPressed: () => setState(() => _draft = _draft.copyWith(
                        minRating:
                            _draft.minRating == stars ? null : stars.toDouble(),
                        clearMinRating: _draft.minRating == stars)),
                    icon: Icon(
                      stars <= (_draft.minRating ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(productFilterProvider.notifier)
                      .update((_) => _draft);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
