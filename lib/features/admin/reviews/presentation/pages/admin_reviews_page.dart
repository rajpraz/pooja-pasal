import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';
import 'package:pooja_pasal/features/reviews/domain/entities/review.dart';
import 'package:pooja_pasal/features/reviews/presentation/providers/review_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Admin review moderation — a bounded (most-recent-100) list, not the
/// whole `reviews` collection. Reviewer identity is never resolved beyond
/// the "Verified Purchase" badge already used on the buyer-facing product
/// review list, matching that page's choice not to expose buyer PII.
class AdminReviewsPage extends ConsumerWidget {
  const AdminReviewsPage({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this review?'),
        content: const Text(
            'The review will be permanently removed and the product\'s average rating will be '
            'recalculated. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(reviewControllerProvider.notifier).deleteReview(review.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review deleted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(adminRecentReviewsProvider);
    final isBusy = ref.watch(reviewControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Review Moderation')),
      body: reviewsAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load reviews: $err')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyView(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              subtitle: 'Buyer reviews will show up here for moderation.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminRecentReviewsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final productAsync = ref.watch(productProvider(review.productId));
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                productAsync.value?.name ?? review.productId,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.error),
                              tooltip: 'Delete review',
                              onPressed: isBusy ? null : () => _confirmDelete(context, ref, review),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < review.rating ? Icons.star : Icons.star_border,
                                size: 14,
                                color: AppColors.accent,
                              ),
                            ),
                            if (review.verifiedPurchase) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('Verified Purchase',
                                    style: TextStyle(fontSize: 10, color: AppColors.success)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(review.text, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
