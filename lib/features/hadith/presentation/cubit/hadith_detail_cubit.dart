import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/hadith_repository.dart';
import 'hadith_detail_state.dart';

/// Manages on-demand loading of hadith details.
/// Loads full content first, then sanad/explanation on demand when their tabs open.
/// Automatically prefetches adjacent hadiths in the background.
class HadithDetailCubit extends Cubit<HadithDetailState> {
  final HadithRepository _repository;
  final String hadithId;
  final String? categoryId;
  final int? currentSortOrder;

  HadithDetailCubit({
    required HadithRepository repository,
    required this.hadithId,
    this.categoryId,
    this.currentSortOrder,
  }) : _repository = repository,
       super(const HadithDetailState());

  /// Loads the full hadith and triggers background prefetching.
  Future<void> load() async {
    if (state.status == HadithDetailStatus.loading) return;
    emit(state.copyWith(status: HadithDetailStatus.loading));

    try {
      final hadith = await _repository.getHadithDetail(hadithId);
      if (hadith == null) {
        emit(
          state.copyWith(
            status: HadithDetailStatus.error,
            errorMessage: 'Hadith not found',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: HadithDetailStatus.loaded,
          hadith: hadith,
          sanadLoaded: true,
          explanationLoaded: true,
        ),
      );

      // Background prefetch next hadiths
      _prefetchAdjacent();
    } catch (e) {
      emit(
        state.copyWith(
          status: HadithDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Retry loading after an error.
  Future<void> retry() => load();

  void _prefetchAdjacent() {
    if (categoryId == null || currentSortOrder == null) return;
    // Fire and forget — don't await, don't emit state changes
    _repository.prefetchNext(
      categoryId: categoryId!,
      currentSortOrder: currentSortOrder!,
      count: 3,
    );
  }
}
