import '../../features/quran/data/datasources/quran_local_data_source.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../network/network_info.dart';
import 'settings_service.dart';

/// Warms up the local Quran cache in the background so that every surah is
/// available offline and is served instantly on first open.
///
/// Behaviour:
/// - Uthmani edition: skipped — always covered by bundled JSON assets.
/// - All other editions: 114 surahs are fetched one by one (with a small
///   inter-request delay) and stored in SharedPreferences.  Already-cached
///   surahs are skipped to avoid redundant network calls.
/// - Safe to call multiple times: only one warm-up runs at a time.
/// - Silently swallows errors per-surah so a single failure doesn't abort the
///   whole process.
class QuranCacheWarmupService {
  final QuranRepository _repository;
  final QuranLocalDataSource _localDataSource;
  final SettingsService _settingsService;
  final NetworkInfo _networkInfo;

  bool _isRunning = false;

  QuranCacheWarmupService({
    required QuranRepository repository,
    required QuranLocalDataSource localDataSource,
    required SettingsService settingsService,
    required NetworkInfo networkInfo,
  })  : _repository = repository,
        _localDataSource = localDataSource,
        _settingsService = settingsService,
        _networkInfo = networkInfo;

  /// Start the background warm-up.  Returns immediately; caching happens
  /// asynchronously.  Call [cancel] to stop early if needed.
  void startInBackground() {
    if (_isRunning) return;
    _doWarmUp(); // intentionally not awaited
  }

  /// Cancel an in-progress warm-up (e.g., when the user changes the edition).
  void cancel() {
    _isRunning = false;
  }

  Future<void> _doWarmUp() async {
    _isRunning = true;

    try {
      final edition = _settingsService.getQuranEdition();

      // Uthmani edition is always available from bundled assets — no network
      // calls needed.
      if (edition == ApiConstants.defaultEdition) return;

      // Don't warm up when there is no connection.
      if (!await _networkInfo.isConnected) return;

      for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
        // Allow external cancellation between iterations.
        if (!_isRunning) break;

        try {
          // Check if this surah is already cached for the current edition.
          await _localDataSource.getCachedSurah(
            surahNumber,
            edition: edition,
          );
          // Cache hit — nothing to do.
        } on CacheException {
          // Cache miss — fetch from network and let the repository cache it.
          try {
            await _repository.getSurah(surahNumber, edition: edition);
          } catch (_) {
            // Ignore individual failures so we continue with the next surah.
          }
        }

        // Small delay between requests to be gentle on the API and battery.
        // ~300 ms × 114 surahs ≈ 34 seconds total for a cold cache.
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      _isRunning = false;
    }
  }

  bool get isRunning => _isRunning;
}
