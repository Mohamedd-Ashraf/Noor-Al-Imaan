import 'package:equatable/equatable.dart';

enum SearchStatus { initial, loading, loaded, error }

/// A surah that matched the search query (name-level match).
class SurahSearchResult extends Equatable {
  final int number;
  final String arabicName;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahSearchResult({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  @override
  List<Object?> get props => [number];
}

/// An ayah that matched the search query (text-level match).
class AyahSearchResult extends Equatable {
  final int surahNumber;
  final String surahArabicName;
  final String surahEnglishName;
  final int ayahNumberInSurah;
  final int ayahGlobalNumber;
  final String ayahText;

  const AyahSearchResult({
    required this.surahNumber,
    required this.surahArabicName,
    required this.surahEnglishName,
    required this.ayahNumberInSurah,
    required this.ayahGlobalNumber,
    required this.ayahText,
  });

  @override
  List<Object?> get props => [ayahGlobalNumber];
}

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<SurahSearchResult> surahResults;
  final List<AyahSearchResult> ayahResults;
  final bool isSearchingAyahs;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.surahResults = const [],
    this.ayahResults = const [],
    this.isSearchingAyahs = false,
    this.errorMessage,
  });

  bool get hasResults => surahResults.isNotEmpty || ayahResults.isNotEmpty;
  // Only truly empty when fully done scanning AND still nothing found.
  bool get isEmpty =>
      status == SearchStatus.loaded &&
      query.isNotEmpty &&
      !hasResults &&
      !isSearchingAyahs;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SurahSearchResult>? surahResults,
    List<AyahSearchResult>? ayahResults,
    bool? isSearchingAyahs,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      surahResults: surahResults ?? this.surahResults,
      ayahResults: ayahResults ?? this.ayahResults,
      isSearchingAyahs: isSearchingAyahs ?? this.isSearchingAyahs,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        query,
        surahResults,
        ayahResults,
        isSearchingAyahs,
        errorMessage,
      ];
}
