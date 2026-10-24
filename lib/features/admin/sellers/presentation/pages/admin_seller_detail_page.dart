import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/admin/sellers/presentation/providers/admin_seller_providers.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// "Deactivate"/"Restore" here is honestly a role demotion/promotion via
/// `setUserRole` — there is no separate suspension flag, and the UI copy
/// says so explicitly rather than implying a dedicated suspension feature.
class AdminSellerDetailPage extends ConsumerWidget {
  final String uid;

  const AdminSellerDetailPage({super.key, required this.uid});

  Future<void> _confirmDemote(BuildContext context, WidgetRef ref, AppUser seller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demote to buyer?'),
        content: Text(
            '"${seller.name.isEmpty ? seller.email : seller.name}" will lose seller access immediately '
            '(their role changes to "buyer"). Their existing products stay in the catalog but they '
            'will no longer be able to manage them until restored to seller. This does not cancel or '
            'affect any of their existing orders.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Demote to Buyer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminSellerControllerProvider.notifier).setRole(uid, 'buyer');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seller access removed.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _confirmRestore(BuildContext context, WidgetRef ref, AppUser user) async {
    try {
      await ref.read(adminSellerControllerProvider.notifier).setRole(uid, 'seller');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seller access restored.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDocProvider(uid));
    final productsAsync = ref.watch(sellerProductsProvider(uid));
    final ordersAsync = ref.watch(sellerOrdersProvider(uid));
    final isBusy = ref.watch(adminSellerControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Seller Details')),
      body: userAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load seller: $err')),
        data: (user) {
          if (user == null) return const Center(child: Text('Seller not found'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(user.name.isEmpty ? user.email : user.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: AppColors.muted)),
                if (user.phone.isNotEmpty)
                  Text(user.phone, style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (user.role == 'seller' ? AppColors.success : AppColors.muted)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      user.role == 'seller'
                          ? 'ACTIVE SELLER'
                          : 'NOT CURRENTLY A SELLER (${user.role.toUpperCase()})',
                      style: TextStyle(
                          color: user.role == 'seller' ? AppColors.success : AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text('${productsAsync.value?.length ?? 0}',
                                  style:
                                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Products',
                                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text('${ordersAsync.value?.length ?? 0}',
                                  style:
                                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Orders',
                                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (user.role == 'seller')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : () => _confirmDemote(context, ref, user),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Demote to Buyer (remove seller access)'),
                    ),
                  )
                else if (user.role == 'buyer')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : () => _confirmRestore(context, ref, user),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: const Text('Restore Seller Access'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
