import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/reviews/presentation/providers/review_providers.dart';

/// Shows a star-rating + text review dialog for [item] on [orderId], and
/// submits it via [ReviewController] on confirm. Extracted out of
/// TrackOrderPage so the dialog itself is reusable and the page doesn't
/// carry review business logic.
Future<void> showReviewDialog(
  BuildContext context,
  WidgetRef ref, {
  required String orderId,
  required OrderItem item,
}) async {
  int rating = 5;
  final textController = TextEditingController();

  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Review ${item.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setDialogState(() => rating = i),
                        icon: Icon(
                          i <= rating ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Share your experience with this product'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );

  if (submitted != true || !context.mounted) return;
  if (textController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review.')));
    return;
  }

  try {
    await ref.read(reviewControllerProvider.notifier).submitReview(
          productId: item.productId,
          orderId: orderId,
          rating: rating,
          text: textController.text.trim(),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
  }
}
