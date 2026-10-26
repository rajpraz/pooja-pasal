import 'package:flutter/foundation.dart';

/// Where the Laravel API (../pooja_pasal_backend) lives.
///
/// Override at build time with
/// `flutter run --dart-define=API_BASE_URL=https://shop.example.com/api`.
/// Without an override, builds talk to a local `php artisan serve` (the
/// Android emulator reaches the host machine via 10.0.2.2).
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api';
    }
    return 'http://127.0.0.1:8001/api';
  }
}
