import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/products/presentation/providers/search_providers.dart';
import 'package:pooja_pasal/features/products/presentation/widgets/product_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawQuery = ref.watch(searchQueryProvider);
    final debouncedQuery = ref.watch(debouncedSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                ref.read(searchHistoryProvider.notifier).record(value.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Search for pooja items, brands...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              suffixIcon: rawQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).clear();
                      },
                    ),
            ),
          ),
        ),
      ),
      body:
          debouncedQuery.isEmpty ? _buildHistory(context) : _buildResults(context, debouncedQuery),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final historyAsync = ref.watch(searchHistoryProvider);
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => const SizedBox.shrink(),
      data: (recent) {
        if (recent.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Search for pooja items, idols, incense and more.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent searches',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(
                    onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recent
                    .map((term) => ActionChip(
                          label: Text(term),
                          onPressed: () {
                            _controller.text = term;
                            ref.read(searchQueryProvider.notifier).update(term);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, String query) {
    final resultsAsync = ref.watch(searchResultsProvider);
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Could not search: $err')),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 56, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('No results for "$query"',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Try a different keyword.', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: results.length,
            gridDelegate: const ProductGridDelegate(),
            itemBuilder: (context, index) => ProductCard(product: results[index]),
          ),
        );
      },
    );
  }
}
