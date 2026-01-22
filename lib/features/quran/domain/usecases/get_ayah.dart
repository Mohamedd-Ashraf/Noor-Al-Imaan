import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetAyah implements UseCase<Ayah, GetAyahParams> {
  final QuranRepository repository;

  GetAyah(this.repository);

  @override
  Future<Either<Failure, Ayah>> call(GetAyahParams params) async {
    return await repository.getAyah(params.reference, edition: params.edition);
  }
}

class GetAyahParams extends Equatable {
  final String reference;
  final String? edition;

  const GetAyahParams({required this.reference, this.edition});

  @override
  List<Object?> get props => [reference, edition];
}
