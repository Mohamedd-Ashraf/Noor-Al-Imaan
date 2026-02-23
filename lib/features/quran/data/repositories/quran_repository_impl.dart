import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/juz.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_bundled_data_source.dart';
import '../datasources/quran_local_data_source.dart';
import '../datasources/quran_remote_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranRemoteDataSource remoteDataSource;
  final QuranLocalDataSource localDataSource;
  final QuranBundledDataSource bundledDataSource;
  final NetworkInfo networkInfo;

  QuranRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.bundledDataSource,
    required this.networkInfo,
  });

  bool _isUthmaniEdition(String? edition) {
    final normalized = (edition == null || edition.isEmpty)
        ? ApiConstants.defaultEdition
        : edition;
    return normalized == ApiConstants.defaultEdition;
  }

  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async {
    // Prefer bundled Quran text so the app works from first install without internet.
    try {
      final bundled = await bundledDataSource.getBundledAllSurahs();
      return Right(bundled);
    } on CacheException {
      // If assets are missing (e.g., dev build), continue with network/cache strategy.
    }

    if (await networkInfo.isConnected) {
      try {
        final surahs = await remoteDataSource.getAllSurahs();
        await localDataSource.cacheAllSurahs(surahs);
        return Right(surahs);
      } on ServerException {
        // Fallback to cache if available
        try {
          final cached = await localDataSource.getCachedAllSurahs();
          return Right(cached);
        } on CacheException {
          return const Left(ServerFailure('Failed to fetch surahs'));
        }
      }
    }

    try {
      final cached = await localDataSource.getCachedAllSurahs();
      return Right(cached);
    } on CacheException {
      return const Left(
        CacheFailure(
          'No internet connection and no cached Quran data. Please connect once to load Quran for offline use.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Surah>> getSurah(
    int surahNumber, {
    String? edition,
  }) async {
    // ─── Fast path: bundled assets for the default Uthmani edition ──────────
    // The bundled offline JSON is always clean (no API artefacts) and is
    // available even on first install without internet.
    if (_isUthmaniEdition(edition)) {
      try {
        final bundled = await bundledDataSource.getBundledSurah(surahNumber);
        return Right(bundled);
      } on CacheException {
        // Assets missing in dev build; continue below.
      }
    }

    // ─── Cache-first for ALL editions ───────────────────────────────────────
    // Always try the local cache before touching the network.
    // This guarantees that the display is always consistent: once a surah is
    // fetched and cached, the user sees the same clean text whether online or
    // offline, instead of seeing raw API artefacts on every online open.
    try {
      final cached = await localDataSource.getCachedSurah(
        surahNumber,
        edition: edition,
      );
      return Right(cached);
    } on CacheException {
      // Cache miss – need to fetch from the network.
    }

    // ─── Network fetch (only when cache is empty) ────────────────────────────
    if (await networkInfo.isConnected) {
      try {
        final surah = await remoteDataSource.getSurah(
          surahNumber,
          edition: edition,
        );
        // Persist to local cache so every future open (online OR offline)
        // reads the already-normalised, artefact-free cached text.
        await localDataSource.cacheSurah(surah, edition: edition);
        return Right(surah);
      } on ServerException {
        // Network fetch failed; try bundled Uthmani as last resort.
        try {
          final bundled = await bundledDataSource.getBundledSurah(surahNumber);
          return Right(bundled);
        } on CacheException {
          return const Left(ServerFailure('Failed to fetch surah'));
        }
      }
    }

    // ─── Offline fallback ────────────────────────────────────────────────────
    // Cache miss + no internet.  Gracefully degrade to the bundled Uthmani
    // text so the user can still read the Quran.
    try {
      final bundled = await bundledDataSource.getBundledSurah(surahNumber);
      return Right(bundled);
    } on CacheException {
      return const Left(
        CacheFailure(
          'No internet connection and this Surah has not been cached yet. '
          'Please open it once while online to enable offline reading.',
        ),
      );
    }
  }

  // ─── Instant fetch (no network) ─────────────────────────────────────────
  // Returns data as fast as possible for immediate UI display:
  //   1. Bundled assets (Uthmani edition — always available, fastest)
  //   2. Local cache (all editions — fast, already normalised)
  //   3. Bundled Uthmani placeholder (for non-Uthmani editions with empty cache)
  // Never touches the network — caller is responsible for following up with
  // getSurah() to upgrade the content once the real data is available.
  @override
  Future<Either<Failure, Surah>> getInstantSurah(
    int surahNumber, {
    String? edition,
  }) async {
    // 1. Bundled for default Uthmani edition
    if (_isUthmaniEdition(edition)) {
      try {
        final bundled = await bundledDataSource.getBundledSurah(surahNumber);
        return Right(bundled);
      } on CacheException {
        // Dev build missing assets — continue
      }
    }

    // 2. Cache hit for any edition
    try {
      final cached = await localDataSource.getCachedSurah(
        surahNumber,
        edition: edition,
      );
      return Right(cached);
    } on CacheException {
      // Cache miss for this edition
    }

    // 3. Bundled Uthmani as a placeholder even for non-Uthmani editions
    //    so the user sees text immediately rather than a loading spinner.
    try {
      final bundled = await bundledDataSource.getBundledSurah(surahNumber);
      return Right(bundled);
    } on CacheException {
      return const Left(
        CacheFailure('No instant data available — assets missing'),
      );
    }
  }

  @override
  Future<Either<Failure, Ayah>> getAyah(
    String reference, {
    String? edition,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final ayah = await remoteDataSource.getAyah(
          reference,
          edition: edition,
        );
        return Right(ayah);
      } on ServerException {
        return const Left(ServerFailure('Failed to fetch ayah'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Juz>> getJuz(int juzNumber, {String? edition}) async {
    if (await networkInfo.isConnected) {
      try {
        final juz = await remoteDataSource.getJuz(juzNumber, edition: edition);
        return Right(juz);
      } on ServerException {
        return const Left(ServerFailure('Failed to fetch juz'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
