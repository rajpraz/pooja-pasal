import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/reviews/presentation/providers/review_providers.dart';

/// Review list for a product's detail page — average rating + count comes
/// from `Product.ratingAverage`/`ratingCount` (maintained by the API), this
/// widget just lists the reviews themselves below it.
class ReviewList extends ConsumerWidget {
  final String productId;

  const ReviewList({super.key, required this.productId});

  String _timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsForProductProvider(productId));

    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Could not load reviews: $err', style: TextStyle(color: AppColors.muted)),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No reviews yet. Be the first to review this product.',
                style: TextStyle(color: AppColors.muted)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reviews
              .map((review) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating ? Icons.star : Icons.star_border,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
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
                            const Spacer(),
                            Text(_timeAgo(review.createdAt),
                                style: TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(review.text, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
