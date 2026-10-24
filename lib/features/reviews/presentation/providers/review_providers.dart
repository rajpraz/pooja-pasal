import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/network/api_client.dart';
import 'package:pooja_pasal/features/reviews/data/datasources/review_remote_data_source.dart';
import 'package:pooja_pasal/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:pooja_pasal/features/reviews/domain/entities/review.dart';
import 'package:pooja_pasal/features/reviews/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ReviewRemoteDataSource(ref.watch(apiClientProvider)));
});

final reviewsForProductProvider =
    StreamProvider.autoDispose.family<List<Review>, String>((ref, productId) {
  return ref.watch(reviewRepositoryProvider).streamReviewsForProduct(productId);
});

/// Admin moderation list — bounded fetch, not the whole collection.
final adminRecentReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) {
  return ref.watch(reviewRepositoryProvider).fetchRecentReviews();
});

class ReviewController extends AsyncNotifier<void> {
  late final ReviewRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(reviewRepositoryProvider);
  }

  Future<void> submitReview({
    required String productId,
    required String orderId,
    required int rating,
    required String text,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.createReview(
        productId: productId,
        orderId: orderId,
        rating: rating,
        text: text,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Admin-only — enforced server-side by `deleteReview`'s
  /// `requireRole(request, ["admin"])`, not by anything here.
  Future<void> deleteReview(String reviewId) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteReview(reviewId);
      state = const AsyncData(null);
      ref.invalidate(adminRecentReviewsProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final reviewControllerProvider =
    AsyncNotifierProvider<ReviewController, void>(ReviewController.new);
