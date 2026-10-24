import 'package:pooja_pasal/core/errors/app_exception.dart';

/// Single place that turns any caught error into a short, user-facing
/// string. Used by every page that calls a Riverpod controller so error
/// text doesn't drift between features (checkout, seller orders, reviews,
/// etc. previously each had their own near-identical private helper).
String friendlyErrorMessage(Object error) {
  if (error is AppFunctionException) return error.message;
  if (error is AuthException) return error.message;
  return 'Something went wrong. Please try again.';
}
