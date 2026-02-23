import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists daily adhkar progress in SharedPreferences.
///
/// Data keys:
///   adhkar_progress_date            → ISO date string of the current day (YYYY-MM-DD)
///   adhkar_progress_<categoryId>    → JSON: Map<itemId, count>
///
/// Daily reset: if the stored date differs from today, all counters are wiped
/// automatically on the first [loadAll] call.
class AdhkarProgressService {
  static const String _keyDate = 'adhkar_progress_date';
  static const String _categoryKeyPrefix = 'adhkar_progress_';

  final SharedPreferences _prefs;

  AdhkarProgressService(this._prefs);

  // ── helpers ────────────────────────────────────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _categoryKey(String categoryId) =>
      '$_categoryKeyPrefix$categoryId';

  // ── public API ─────────────────────────────────────────────────────────────

  /// Returns the stored progress for every category.
  /// If the stored date is not today, all data is wiped first (daily reset).
  Map<String, Map<String, int>> loadAll(List<String> categoryIds) {
    final today = _todayString();
    final stored = _prefs.getString(_keyDate);

    if (stored != today) {
      // New day – clear every category's data
      for (final id in categoryIds) {
        _prefs.remove(_categoryKey(id));
      }
      _prefs.setString(_keyDate, today);
    }

    final result = <String, Map<String, int>>{};
    for (final id in categoryIds) {
      result[id] = _loadCategory(id);
    }
    return result;
  }

  /// Returns the stored counters for a single category.
  Map<String, int> _loadCategory(String categoryId) {
    final raw = _prefs.getString(_categoryKey(categoryId));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Persists the counter map for a single category.
  Future<void> saveCategory(
      String categoryId, Map<String, int> counters) async {
    await _prefs.setString(
      _categoryKey(categoryId),
      jsonEncode(counters),
    );
    // Always keep the date fresh on write
    await _prefs.setString(_keyDate, _todayString());
  }

  /// Wipes all progress for all categories immediately.
  Future<void> resetAll(List<String> categoryIds) async {
    for (final id in categoryIds) {
      await _prefs.remove(_categoryKey(id));
    }
    await _prefs.setString(_keyDate, _todayString());
  }
}
