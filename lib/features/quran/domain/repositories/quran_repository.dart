import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/surah.dart';
import '../entities/juz.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getAllSurahs();
  Future<Either<Failure, Surah>> getSurah(int surahNumber, {String? edition});
  Future<Either<Failure, Ayah>> getAyah(String reference, {String? edition});
  Future<Either<Failure, Juz>> getJuz(int juzNumber, {String? edition});
}
