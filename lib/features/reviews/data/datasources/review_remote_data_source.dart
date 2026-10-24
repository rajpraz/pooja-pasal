import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/reviews/domain/entities/review.dart';

/// Reviews. The API only accepts a review from a buyer whose order with the
/// product was delivered, once per product, and recomputes the product's
/// rating on every create/delete.
class ReviewRemoteDataSource {
  ReviewRemoteDataSource(this._api);

  final ApiClient _api;

  Future<void> createReview({
    required String productId,
    required String orderId,
    required int rating,
    required String text,
    List<String> images = const [],
  }) async {
    await _api.post('/reviews', {
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'text': text,
      'images': images,
    });
    _api.notifyChanged(const [ApiTopics.reviews, ApiTopics.products]);
  }

  Stream<List<Review>> streamReviewsForProduct(String productId) => _api.watch(
        {ApiTopics.reviews},
        () async => asJsonList(await _api.get('/products/$productId/reviews'))
            .map(Review.fromJson)
            .toList(),
      );

  /// Admin moderation list, newest first.
  Future<List<Review>> fetchRecentReviews({int limit = 100}) async {
    final reviews = asJsonList(await _api.get('/admin/reviews')).map(Review.fromJson).toList();
    return reviews.take(limit).toList();
  }

  /// Own review, or any review for admins.
  Future<void> deleteReview(String reviewId) async {
    await _api.delete('/reviews/$reviewId');
    _api.notifyChanged(const [ApiTopics.reviews, ApiTopics.products]);
  }
}
