import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/hadith_repository.dart';
import 'hadith_state.dart';

class HadithCubit extends Cubit<HadithState> {
  static const String _bookmarksKey = 'hadith_bookmarks';
  final SharedPreferences _prefs;
  final HadithRepository _repository;

  HadithCubit(this._prefs, this._repository) : super(const HadithState()) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    // Try loading from DB first; migrate from SharedPreferences if needed.
    var ids = await _repository.getBookmarks();
    if (ids.isEmpty) {
      final legacy = _prefs.getStringList(_bookmarksKey) ?? [];
      if (legacy.isNotEmpty) {
        for (final id in legacy) {
          await _repository.toggleBookmark(id);
        }
        ids = legacy.toSet();
        // Clean up legacy storage
        await _prefs.remove(_bookmarksKey);
      }
    }
    emit(state.copyWith(bookmarkedIds: ids));
  }

  Future<void> toggleBookmark(String hadithId) async {
    final updated = Set<String>.from(state.bookmarkedIds);
    if (updated.contains(hadithId)) {
      updated.remove(hadithId);
    } else {
      updated.add(hadithId);
    }
    emit(state.copyWith(bookmarkedIds: updated));
    await _repository.toggleBookmark(hadithId);
  }

  void selectCategory(String categoryId) {
    emit(state.copyWith(selectedCategoryId: categoryId));
  }

  void clearCategory() {
    emit(state.copyWith(clearCategory: true));
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
