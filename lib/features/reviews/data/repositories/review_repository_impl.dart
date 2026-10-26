import 'package:pooja_pasal/features/reviews/data/datasources/review_remote_data_source.dart';
import 'package:pooja_pasal/features/reviews/domain/entities/review.dart';
import 'package:pooja_pasal/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _dataSource;

  ReviewRepositoryImpl(this._dataSource);

  @override
  Future<void> createReview({
    required String productId,
    required String orderId,
    required int rating,
    required String text,
    List<String> images = const [],
  }) {
    return _dataSource.createReview(
      productId: productId,
      orderId: orderId,
      rating: rating,
      text: text,
      images: images,
    );
  }

  @override
  Stream<List<Review>> streamReviewsForProduct(String productId) =>
      _dataSource.streamReviewsForProduct(productId);

  @override
  Future<List<Review>> fetchRecentReviews({int limit = 100}) =>
      _dataSource.fetchRecentReviews(limit: limit);

  @override
  Future<void> deleteReview(String reviewId) =>
      _dataSource.deleteReview(reviewId);
}
