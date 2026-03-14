import 'package:shared_preferences/shared_preferences.dart';

/// Persists offline tafsir download sessions so users can pause and resume.
class TafsirDownloadStateService {
  static const String _kIsActive = 'tafsir_dl_active';
  static const String _kEdition = 'tafsir_dl_edition';
  static const String _kPending = 'tafsir_dl_pending';
  static const String _kCompleted = 'tafsir_dl_completed';
  static const String _kTotal = 'tafsir_dl_total';
  static const String _kScope = 'tafsir_dl_scope';
  static const String _kStartedAt = 'tafsir_dl_started_at';

  final SharedPreferences _prefs;

  TafsirDownloadStateService(this._prefs);

  bool get isActive => _prefs.getBool(_kIsActive) ?? false;
  String get edition => _prefs.getString(_kEdition) ?? '';
  List<String> get pendingAyahs => _prefs.getStringList(_kPending) ?? const [];
  List<String> get completedAyahs =>
      _prefs.getStringList(_kCompleted) ?? const [];
  int get totalAyahs => _prefs.getInt(_kTotal) ?? 0;
  String get scope => _prefs.getString(_kScope) ?? 'custom';

  DateTime? get startedAt {
    final raw = _prefs.getString(_kStartedAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveSession({
    required String edition,
    required List<String> pendingAyahs,
    required List<String> completedAyahs,
    required int totalAyahs,
    required String scope,
  }) async {
    await Future.wait([
      _prefs.setBool(_kIsActive, true),
      _prefs.setString(_kEdition, edition),
      _prefs.setStringList(_kPending, pendingAyahs),
      _prefs.setStringList(_kCompleted, completedAyahs),
      _prefs.setInt(_kTotal, totalAyahs),
      _prefs.setString(_kScope, scope),
      _prefs.setString(_kStartedAt, DateTime.now().toIso8601String()),
    ]);
  }

  Future<void> onAyahCompleted(String ayahRef) async {
    final pending = List<String>.from(pendingAyahs)..remove(ayahRef);
    final completed = List<String>.from(completedAyahs)..add(ayahRef);
    await Future.wait([
      _prefs.setStringList(_kPending, pending),
      _prefs.setStringList(_kCompleted, completed),
    ]);
  }

  /// Writes current progress in one batched operation.
  Future<void> saveProgressSnapshot({
    required List<String> pendingAyahs,
    required List<String> completedAyahs,
  }) async {
    await Future.wait([
      _prefs.setStringList(_kPending, pendingAyahs),
      _prefs.setStringList(_kCompleted, completedAyahs),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_kIsActive),
      _prefs.remove(_kEdition),
      _prefs.remove(_kPending),
      _prefs.remove(_kCompleted),
      _prefs.remove(_kTotal),
      _prefs.remove(_kScope),
      _prefs.remove(_kStartedAt),
    ]);
  }
}
