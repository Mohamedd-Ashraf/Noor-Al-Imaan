import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetSurah implements UseCase<Surah, GetSurahParams> {
  final QuranRepository repository;

  GetSurah(this.repository);

  @override
  Future<Either<Failure, Surah>> call(GetSurahParams params) async {
    return await repository.getSurah(params.surahNumber, edition: params.edition);
  }
}

/// Instant (no-network) use case: bundled → cache → bundled placeholder.
/// Used for the first emit in the two-phase BLoC flow so that content is
/// visible immediately without a loading spinner.
class GetInstantSurah implements UseCase<Surah, GetSurahParams> {
  final QuranRepository repository;

  GetInstantSurah(this.repository);

  @override
  Future<Either<Failure, Surah>> call(GetSurahParams params) async {
    return await repository.getInstantSurah(
      params.surahNumber,
      edition: params.edition,
    );
  }
}

class GetSurahParams extends Equatable {
  final int surahNumber;
  final String? edition;

  const GetSurahParams({required this.surahNumber, this.edition});

  @override
  List<Object?> get props => [surahNumber, edition];
}
