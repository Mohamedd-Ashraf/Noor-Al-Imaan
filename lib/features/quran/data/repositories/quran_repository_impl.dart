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

  bool _isCacheableEdition(String? edition) {
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
  Future<Either<Failure, Surah>> getSurah(int surahNumber, {String? edition}) async {
    // Prefer bundled Quran text for Arabic default edition.
    if (_isCacheableEdition(edition)) {
      try {
        final bundled = await bundledDataSource.getBundledSurah(surahNumber);
        return Right(bundled);
      } on CacheException {
        // Assets missing, fall through.
      }
    }

    if (await networkInfo.isConnected) {
      try {
        final surah = await remoteDataSource.getSurah(surahNumber, edition: edition);
        if (_isCacheableEdition(edition)) {
          await localDataSource.cacheSurah(surah, edition: edition);
        }
        return Right(surah);
      } on ServerException {
        // Fallback to cache for Arabic only
        if (_isCacheableEdition(edition)) {
          try {
            final cached = await localDataSource.getCachedSurah(
              surahNumber,
              edition: edition,
            );
            return Right(cached);
          } on CacheException {
            return const Left(ServerFailure('Failed to fetch surah'));
          }
        }

        return const Left(ServerFailure('Failed to fetch surah'));
      }
    }

    // Offline
    if (_isCacheableEdition(edition)) {
      try {
        final cached = await localDataSource.getCachedSurah(
          surahNumber,
          edition: edition,
        );
        return Right(cached);
      } on CacheException {
        return const Left(
          CacheFailure(
            'No internet connection and this Surah is not cached yet. Please open it once while online for offline reading.',
          ),
        );
      }
    }

    // Non-Arabic editions (like translation) are not cached.
    return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, Ayah>> getAyah(String reference, {String? edition}) async {
    if (await networkInfo.isConnected) {
      try {
        final ayah = await remoteDataSource.getAyah(reference, edition: edition);
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
