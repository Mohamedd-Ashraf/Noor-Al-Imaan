import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_all_surahs.dart';
import '../../../domain/usecases/get_surah.dart';
import '../../../../../core/usecases/usecase.dart';
import 'surah_event.dart';
import 'surah_state.dart';

class SurahBloc extends Bloc<SurahEvent, SurahState> {
  final GetAllSurahs getAllSurahs;
  final GetSurah getSurah;
  final GetInstantSurah getInstantSurah;

  SurahBloc({
    required this.getAllSurahs,
    required this.getSurah,
    required this.getInstantSurah,
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
    // ── Phase 1: Instant (bundled / cache, never network) ──────────────────
    // Show content immediately without a loading spinner.  For Uthmani edition
    // this returns the bundled asset.  For other editions this returns the
    // local cache when available, or the bundled Uthmani text as a placeholder
    // while the real edition is being fetched in phase 2.
    final instantResult = await getInstantSurah(
      GetSurahParams(surahNumber: event.surahNumber, edition: event.edition),
    );

    bool hadInstant = false;
    instantResult.fold(
      (_) => emit(SurahLoading()), // assets missing (dev build)
      (surah) {
        emit(SurahDetailLoaded(surah));
        hadInstant = true;
      },
    );

    // ── Phase 2: Full fetch (cache → network if needed) ────────────────────
    // If phase 1 already served from cache / bundled-matching-edition, this
    // call returns the same data and BLoC's Equatable deduplication skips the
    // second emit.  When the edition differs from Uthmani and the cache is
    // empty, this triggers a network download and updates the display once
    // the real text arrives.
    final result = await getSurah(
      GetSurahParams(surahNumber: event.surahNumber, edition: event.edition),
    );
    result.fold(
      (failure) {
        // Only surface the error if we had nothing to show in phase 1.
        if (!hadInstant) emit(SurahError(failure.message));
      },
      (surah) => emit(SurahDetailLoaded(surah)),
    );
  }
}
