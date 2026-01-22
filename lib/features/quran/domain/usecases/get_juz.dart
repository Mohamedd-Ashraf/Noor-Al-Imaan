import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/juz.dart';
import '../repositories/quran_repository.dart';

class GetJuz implements UseCase<Juz, GetJuzParams> {
  final QuranRepository repository;

  GetJuz(this.repository);

  @override
  Future<Either<Failure, Juz>> call(GetJuzParams params) async {
    return await repository.getJuz(params.juzNumber, edition: params.edition);
  }
}

class GetJuzParams extends Equatable {
  final int juzNumber;
  final String? edition;

  const GetJuzParams({required this.juzNumber, this.edition});

  @override
  List<Object?> get props => [juzNumber, edition];
}
