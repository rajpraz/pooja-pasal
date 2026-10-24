/// Friendly, typed failure surfaced to Riverpod controllers and, from
/// there, to the UI. Never let a raw HTTP or socket error reach a widget
/// directly — everything is translated to a short user-facing [message]
/// by core/network/api_client.dart, with the API's machine-readable
/// [code] kept for callers that need to branch on specific failures.
class AppFunctionException implements Exception {
  final String code;
  final String message;
  const AppFunctionException(this.code, this.message);

  bool get isAuthError => code == 'unauthenticated' || code == 'permission-denied';
  bool get isTimeout => code == 'deadline-exceeded' || code == 'unavailable';

  @override
  String toString() => message;
}

/// Same idea as [AppFunctionException], for sign-in / sign-up failures, so
/// auth pages can catch one type.
class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}
