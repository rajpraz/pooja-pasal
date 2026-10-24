import 'package:pooja_pasal/features/reviews/domain/entities/review.dart';

/// Only a buyer who actually purchased and received (status "delivered")
/// the product may review it, and only once per product — verified by the
/// API, which also keeps the product's rating up to date.
abstract class ReviewRepository {
  Future<void> createReview({
    required String productId,
    required String orderId,
    required int rating,
    required String text,
    List<String> images = const [],
  });

  Stream<List<Review>> streamReviewsForProduct(String productId);

  /// Bounded recent-reviews fetch for admin moderation.
  Future<List<Review>> fetchRecentReviews({int limit = 100});

  /// Own review, or any review for admins. The API recomputes the
  /// product's `ratingAverage`/`ratingCount`.
  Future<void> deleteReview(String reviewId);
}
