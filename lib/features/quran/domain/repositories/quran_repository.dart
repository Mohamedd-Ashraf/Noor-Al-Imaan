import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/surah.dart';
import '../entities/juz.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getAllSurahs();

  /// Full fetch: bundled → cache → network (may show loading spinner).
  Future<Either<Failure, Surah>> getSurah(int surahNumber, {String? edition});

  /// Instant fetch: bundled → cache only, never network.
  /// Returns bundled Uthmani as a placeholder for non-Uthmani editions when
  /// the cache is empty.  Never shows a loading spinner.
  Future<Either<Failure, Surah>> getInstantSurah(
    int surahNumber, {
    String? edition,
  });

  Future<Either<Failure, Ayah>> getAyah(String reference, {String? edition});
  Future<Either<Failure, Juz>> getJuz(int juzNumber, {String? edition});
}
