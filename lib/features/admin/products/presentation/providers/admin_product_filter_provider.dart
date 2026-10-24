import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AdminProductFilter { all, active, inactive, lowStock }

/// Local UI-only filter over the already-loaded `adminAllProductsProvider`
/// list — no extra request per filter tab, matching the same pattern used
/// by the seller order status filter.
class AdminProductFilterNotifier extends Notifier<AdminProductFilter> {
  @override
  AdminProductFilter build() => AdminProductFilter.all;

  void set(AdminProductFilter value) => state = value;
}

final adminProductFilterProvider =
    NotifierProvider.autoDispose<AdminProductFilterNotifier, AdminProductFilter>(
        AdminProductFilterNotifier.new);
