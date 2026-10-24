import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/features/products/data/datasources/search_history_local_data_source.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';

final searchHistoryDataSourceProvider =
    Provider<SearchHistoryLocalDataSource>((ref) => SearchHistoryLocalDataSource());

/// Raw text as the user types; debounces writes into
/// [debouncedSearchQueryProvider] (400ms) so [searchResultsProvider] only
/// re-runs once typing pauses, not on every keystroke.
class SearchQueryController extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void update(String value) {
    state = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(debouncedSearchQueryProvider.notifier).set(value.trim());
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
    ref.read(debouncedSearchQueryProvider.notifier).set('');
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

class DebouncedSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final debouncedSearchQueryProvider =
    NotifierProvider<DebouncedSearchQueryController, String>(DebouncedSearchQueryController.new);

/// Search results from the API (`GET /products/search`), which matches
/// name, category, festival and description in SQL — no need to load the
/// whole catalog onto the device.
final searchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider);
  if (query.isEmpty) return const [];
  return ref.watch(productRepositoryProvider).search(query);
});

class SearchHistoryController extends AsyncNotifier<List<String>> {
  late final SearchHistoryLocalDataSource _dataSource;

  @override
  FutureOr<List<String>> build() {
    _dataSource = ref.watch(searchHistoryDataSourceProvider);
    return _dataSource.getRecent();
  }

  Future<void> record(String query) async {
    await _dataSource.add(query);
    state = AsyncData(await _dataSource.getRecent());
  }

  Future<void> clear() async {
    await _dataSource.clear();
    state = const AsyncData([]);
  }
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryController, List<String>>(SearchHistoryController.new);
