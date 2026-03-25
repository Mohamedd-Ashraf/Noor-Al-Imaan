import 'package:equatable/equatable.dart';

class HadithState extends Equatable {
  /// Set of bookmarked hadith IDs.
  final Set<String> bookmarkedIds;

  /// Currently selected category ID (null = show categories list).
  final String? selectedCategoryId;

  /// Search query.
  final String searchQuery;

  const HadithState({
    this.bookmarkedIds = const {},
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  HadithState copyWith({
    Set<String>? bookmarkedIds,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
  }) {
    return HadithState(
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool isBookmarked(String hadithId) => bookmarkedIds.contains(hadithId);

  @override
  List<Object?> get props => [bookmarkedIds, selectedCategoryId, searchQuery];
}
