import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_all_surahs.dart';
import '../../../domain/usecases/get_surah.dart';
import '../../../../../core/usecases/usecase.dart';
import 'surah_event.dart';
import 'surah_state.dart';

class SurahBloc extends Bloc<SurahEvent, SurahState> {
  final GetAllSurahs getAllSurahs;
  final GetSurah getSurah;

  SurahBloc({
    required this.getAllSurahs,
    required this.getSurah,
  }) : super(SurahInitial()) {
    on<GetAllSurahsEvent>(_onGetAllSurahs);
    on<GetSurahDetailEvent>(_onGetSurahDetail);
  }

  Future<void> _onGetAllSurahs(
    GetAllSurahsEvent event,
    Emitter<SurahState> emit,
  ) async {
    emit(SurahLoading());
    final result = await getAllSurahs(NoParams());
    result.fold(
      (failure) => emit(SurahError(failure.message)),
      (surahs) => emit(SurahListLoaded(surahs)),
    );
  }

  Future<void> _onGetSurahDetail(
    GetSurahDetailEvent event,
    Emitter<SurahState> emit,
  ) async {
    emit(SurahLoading());
    final result = await getSurah(
      GetSurahParams(surahNumber: event.surahNumber, edition: event.edition),
    );
    result.fold(
      (failure) => emit(SurahError(failure.message)),
      (surah) => emit(SurahDetailLoaded(surah)),
    );
  }
}
