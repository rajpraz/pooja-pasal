import 'package:shared_preferences/shared_preferences.dart';

/// Recent-searches list. Kept device-local (SharedPreferences) rather than
/// stored on the server — unlike wishlist/addresses, search history isn't
/// account data that needs to follow the buyer across devices.
class SearchHistoryLocalDataSource {
  static const _key = 'recent_searches';
  static const _maxEntries = 10;

  Future<List<String>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];
    current.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > _maxEntries)
      current.removeRange(_maxEntries, current.length);
    await prefs.setStringList(_key, current);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
