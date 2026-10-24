import 'package:pooja_pasal/core/network/api_client.dart';

/// Typed, forgiving reads from an API JSON object. Every entity's
/// `fromJson` goes through these, so a missing key or an unexpected type
/// from the server becomes a sensible default instead of a runtime cast
/// error somewhere in the UI.
extension JsonRead on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    if (value is String) return value;
    return value == null ? fallback : value.toString();
  }

  String? strOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    return value is String ? value : value.toString();
  }

  double dbl(String key, [double fallback = 0]) {
    final value = this[key];
    if (value is num) return value.toDouble();
    return value is String ? double.tryParse(value) ?? fallback : fallback;
  }

  int integer(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is num) return value.toInt();
    return value is String ? int.tryParse(value) ?? fallback : fallback;
  }

  int? intOrNull(String key) {
    final value = this[key];
    if (value is num) return value.toInt();
    return value is String ? int.tryParse(value) : null;
  }

  bool flag(String key, [bool fallback = false]) {
    final value = this[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return fallback;
  }

  List<String> strings(String key) {
    final value = this[key];
    return value is List ? value.whereType<String>().toList() : const [];
  }

  /// A list of nested objects, skipping anything that isn't one.
  List<Map<String, dynamic>> objects(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  DateTime? date(String key) => parseApiDate(this[key]);
}
