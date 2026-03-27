import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/mushaf_page_map.dart';

class _BookmarkLocation {
  final int? surahNumber;
  final int? ayahNumber;
  final int? pageNumber;

  const _BookmarkLocation({this.surahNumber, this.ayahNumber, this.pageNumber});

  bool get hasAyah => surahNumber != null && ayahNumber != null;
  bool get hasPage => pageNumber != null;
}

class BookmarkService {
  static const String _keyBookmarks = 'bookmarks';
  static final RegExp _ayahIdPattern = RegExp(r'^surah_(\d+)_ayah_(\d+)$');
  static final RegExp _ayahRefPattern = RegExp(r'^(\d+):(\d+)$');
  static final RegExp _pagePattern = RegExp(r'^(?:(\d+)|mushaf):page:(\d+)$');

  final SharedPreferences _prefs;

  /// Called whenever bookmarks are mutated so cloud sync can be triggered.
  void Function()? onDataChanged;

  BookmarkService(this._prefs);

  // Get all bookmarks
  List<Map<String, dynamic>> getBookmarks() {
    final String? bookmarksJson = _prefs.getString(_keyBookmarks);
    if (bookmarksJson == null || bookmarksJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      final bookmarks = _normalizeBookmarks(
        decoded.cast<Map<String, dynamic>>(),
      );

      // Sort by timestamp (newest first)
      bookmarks.sort((a, b) {
        final timestampA = a['timestamp'] as String?;
        final timestampB = b['timestamp'] as String?;

        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;

        try {
          final dateA = DateTime.parse(timestampA);
          final dateB = DateTime.parse(timestampB);
          return dateB.compareTo(dateA); // Descending order (newest first)
        } catch (e) {
          return 0;
        }
      });

      return bookmarks;
    } catch (e) {
      return [];
    }
  }

  // Add a bookmark
  Future<bool> addBookmark({
    required String id,
    required String reference,
    required String arabicText,
    String? surahName,
    String? note,
    int? surahNumber,
    int? ayahNumber,
    int? pageNumber,
  }) async {
    final bookmarks = getBookmarks();
    final newBookmark = _normalizeBookmark({
      'id': id,
      'reference': reference,
      'arabicText': arabicText,
      'surahName': surahName,
      'note': note,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'pageNumber': pageNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
    final bookmarkId = newBookmark['id'] as String;

    // Check if already bookmarked
    if (bookmarks.any((b) => b['id'] == bookmarkId)) {
      return false;
    }

    bookmarks.add(newBookmark);

    final result = await _saveBookmarks(bookmarks);
    if (result) onDataChanged?.call();
    return result;
  }

  // Remove a bookmark
  Future<bool> removeBookmark(String id) async {
    final bookmarks = getBookmarks();
    final normalizedId = _normalizeBookmark({'id': id})['id'];
    bookmarks.removeWhere((b) => b['id'] == id || b['id'] == normalizedId);
    final result = await _saveBookmarks(bookmarks);
    if (result) onDataChanged?.call();
    return result;
  }

  // Check if an ayah is bookmarked
  bool isBookmarked(String id) {
    final bookmarks = getBookmarks();
    final normalizedId = _normalizeBookmark({'id': id})['id'];
    return bookmarks.any((b) => b['id'] == id || b['id'] == normalizedId);
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    final result = await _prefs.remove(_keyBookmarks);
    if (result) onDataChanged?.call();
    return result;
  }

  // Save bookmarks to SharedPreferences
  Future<bool> _saveBookmarks(List<Map<String, dynamic>> bookmarks) async {
    final String bookmarksJson = json.encode(bookmarks);
    return await _prefs.setString(_keyBookmarks, bookmarksJson);
  }

  List<Map<String, dynamic>> _normalizeBookmarks(
    List<Map<String, dynamic>> bookmarks,
  ) {
    final byId = <String, Map<String, dynamic>>{};

    for (final rawBookmark in bookmarks) {
      final bookmark = _normalizeBookmark(rawBookmark);
      final id = bookmark['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final existing = byId[id];
      if (existing == null || _shouldReplaceBookmark(existing, bookmark)) {
        byId[id] = bookmark;
      }
    }

    return byId.values.toList(growable: true);
  }

  bool _shouldReplaceBookmark(
    Map<String, dynamic> existing,
    Map<String, dynamic> candidate,
  ) {
    final existingScore = _bookmarkQualityScore(existing);
    final candidateScore = _bookmarkQualityScore(candidate);
    if (candidateScore != existingScore) {
      return candidateScore > existingScore;
    }

    final existingTimestamp = _parseTimestamp(existing['timestamp']);
    final candidateTimestamp = _parseTimestamp(candidate['timestamp']);
    if (candidateTimestamp == null) return false;
    if (existingTimestamp == null) return true;
    return candidateTimestamp.isAfter(existingTimestamp);
  }

  int _bookmarkQualityScore(Map<String, dynamic> bookmark) {
    var score = 0;

    if (_positiveInt(bookmark['surahNumber']) != null) score += 2;
    if (_positiveInt(bookmark['ayahNumber']) != null) score += 2;
    if (_positiveInt(bookmark['pageNumber']) != null) score += 2;

    final surahName = bookmark['surahName']?.toString().trim();
    if (surahName != null && surahName.isNotEmpty) score += 1;

    final arabicText = bookmark['arabicText']?.toString().trim();
    if (arabicText != null && arabicText.isNotEmpty) score += 1;

    return score;
  }

  DateTime? _parseTimestamp(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalizeBookmark(Map<String, dynamic> rawBookmark) {
    final bookmark = Map<String, dynamic>.from(rawBookmark);
    final location = _extractLocation(bookmark);

    bookmark['id'] = _canonicalId(bookmark, location);

    if (location.hasAyah) {
      bookmark['reference'] = '${location.surahNumber}:${location.ayahNumber}';
      bookmark['surahNumber'] = location.surahNumber;
      bookmark['ayahNumber'] = location.ayahNumber;
      bookmark.remove('pageNumber');
    } else if (location.hasPage) {
      bookmark['reference'] = _canonicalPageReference(location);
      bookmark['surahNumber'] = location.surahNumber;
      bookmark['ayahNumber'] = null;
      bookmark['pageNumber'] = location.pageNumber;
    } else {
      final surahNumber = _positiveInt(bookmark['surahNumber']);
      final ayahNumber = _positiveInt(bookmark['ayahNumber']);
      final pageNumber = _positiveInt(bookmark['pageNumber']);

      if (surahNumber != null) {
        bookmark['surahNumber'] = surahNumber;
      } else {
        bookmark.remove('surahNumber');
      }

      if (ayahNumber != null) {
        bookmark['ayahNumber'] = ayahNumber;
      } else {
        bookmark['ayahNumber'] = null;
      }

      if (pageNumber != null) {
        bookmark['pageNumber'] = pageNumber;
      } else {
        bookmark.remove('pageNumber');
      }
    }

    return bookmark;
  }

  _BookmarkLocation _extractLocation(Map<String, dynamic> bookmark) {
    int? surahNumber = _positiveInt(bookmark['surahNumber']);
    int? ayahNumber = _positiveInt(bookmark['ayahNumber']);
    int? pageNumber = _positiveInt(bookmark['pageNumber']);

    final idToken = bookmark['id']?.toString().trim();
    final referenceToken = bookmark['reference']?.toString().trim();

    final ayahFromId = _extractAyahLocation(idToken);
    final ayahFromReference = _extractAyahLocation(referenceToken);
    surahNumber ??= ayahFromId?.surahNumber ?? ayahFromReference?.surahNumber;
    ayahNumber ??= ayahFromId?.ayahNumber ?? ayahFromReference?.ayahNumber;

    final pageFromId = _extractPageLocation(idToken);
    final pageFromReference = _extractPageLocation(referenceToken);
    pageNumber ??= pageFromId?.pageNumber ?? pageFromReference?.pageNumber;

    final parsedPageSurah =
        pageFromId?.surahNumber ?? pageFromReference?.surahNumber;
    if (ayahNumber == null) {
      surahNumber ??= parsedPageSurah;
    }

    if (ayahNumber == null && pageNumber != null) {
      surahNumber ??= _inferSurahForPage(pageNumber);
    }

    return _BookmarkLocation(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
    );
  }

  _BookmarkLocation? _extractAyahLocation(String? token) {
    if (token == null || token.isEmpty || token.contains(':page:')) {
      return null;
    }

    final idMatch = _ayahIdPattern.firstMatch(token);
    if (idMatch != null) {
      return _BookmarkLocation(
        surahNumber: int.tryParse(idMatch.group(1)!),
        ayahNumber: int.tryParse(idMatch.group(2)!),
      );
    }

    final referenceMatch = _ayahRefPattern.firstMatch(token);
    if (referenceMatch != null) {
      return _BookmarkLocation(
        surahNumber: int.tryParse(referenceMatch.group(1)!),
        ayahNumber: int.tryParse(referenceMatch.group(2)!),
      );
    }

    return null;
  }

  _BookmarkLocation? _extractPageLocation(String? token) {
    if (token == null || token.isEmpty) return null;

    final match = _pagePattern.firstMatch(token);
    if (match == null) return null;

    return _BookmarkLocation(
      surahNumber: _positiveInt(match.group(1)),
      pageNumber: _positiveInt(match.group(2)),
    );
  }

  String _canonicalId(
    Map<String, dynamic> bookmark,
    _BookmarkLocation location,
  ) {
    if (location.hasAyah) {
      return 'surah_${location.surahNumber}_ayah_${location.ayahNumber}';
    }

    if (location.hasPage) {
      return _canonicalPageReference(location);
    }

    final rawId = bookmark['id']?.toString().trim();
    if (rawId != null && rawId.isNotEmpty) return rawId;

    final rawReference = bookmark['reference']?.toString().trim();
    if (rawReference != null && rawReference.isNotEmpty) return rawReference;

    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _canonicalPageReference(_BookmarkLocation location) {
    final pageNumber = location.pageNumber;
    if (pageNumber == null) return 'mushaf:page:0';

    final surahNumber = location.surahNumber ?? _inferSurahForPage(pageNumber);
    if (surahNumber != null) {
      return '$surahNumber:page:$pageNumber';
    }

    return 'mushaf:page:$pageNumber';
  }

  int? _inferSurahForPage(int pageNumber) {
    final surahs = kMushafPageToSurahs[pageNumber];
    if (surahs == null || surahs.isEmpty) return null;
    return surahs.first;
  }

  int? _positiveInt(dynamic value) {
    final parsed = switch (value) {
      final int intValue => intValue,
      final String stringValue => int.tryParse(stringValue),
      _ => null,
    };

    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}
