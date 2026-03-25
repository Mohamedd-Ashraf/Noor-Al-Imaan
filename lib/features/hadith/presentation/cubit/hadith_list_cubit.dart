import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/hadith_local_datasource.dart';
import '../../data/repositories/hadith_repository.dart';
import 'hadith_list_state.dart';

/// Manages paginated hadith list for a single category.
/// Supports infinite scroll with cursor-based pagination.
class HadithListCubit extends Cubit<HadithListState> {
  final HadithRepository _repository;
  final String categoryId;
  final int _pageSize;

  HadithListCubit({
    required HadithRepository repository,
    required this.categoryId,
    int pageSize = HadithLocalDataSource.defaultPageSize,
  }) : _repository = repository,
       _pageSize = pageSize,
       super(const HadithListState());

  /// Loads the first page.
  Future<void> loadInitial() async {
    if (state.status == HadithListStatus.loading) return;
    emit(state.copyWith(status: HadithListStatus.loading));

    try {
      final items = await _repository.getHadithsPaginated(
        categoryId: categoryId,
        limit: _pageSize,
      );

      emit(
        state.copyWith(
          status: HadithListStatus.loaded,
          items: items,
          hasReachedEnd: items.length < _pageSize,
          lastSortOrder: items.isNotEmpty ? items.last.sortOrder : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HadithListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Loads the next page (called on scroll).
  Future<void> loadMore() async {
    if (state.status == HadithListStatus.loading || state.hasReachedEnd) return;
    emit(state.copyWith(status: HadithListStatus.loading));

    try {
      final items = await _repository.getHadithsPaginated(
        categoryId: categoryId,
        limit: _pageSize,
        afterSortOrder: state.lastSortOrder,
      );

      final allItems = [...state.items, ...items];
      emit(
        state.copyWith(
          status: HadithListStatus.loaded,
          items: allItems,
          hasReachedEnd: items.length < _pageSize,
          lastSortOrder: items.isNotEmpty
              ? items.last.sortOrder
              : state.lastSortOrder,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HadithListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Retry after an error.
  Future<void> retry() async {
    if (state.items.isEmpty) {
      await loadInitial();
    } else {
      await loadMore();
    }
  }
}
