import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local UI-only status filter over the already-loaded
/// `adminAllOrdersProvider` list (`null` = all) — no extra request per
/// filter tab, matching the seller order filter pattern.
class AdminOrderStatusFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? status) => state = status;
}

final adminOrderStatusFilterProvider =
    NotifierProvider.autoDispose<AdminOrderStatusFilterNotifier, String?>(
        AdminOrderStatusFilterNotifier.new);

const adminOrderFilterTabs = <String?>[
  null,
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
  'returned',
  'refunded',
];
