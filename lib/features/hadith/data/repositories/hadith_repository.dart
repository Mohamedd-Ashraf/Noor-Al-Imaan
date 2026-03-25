import 'dart:collection';

import '../datasources/hadith_local_datasource.dart';
import '../models/hadith_category_info.dart';
import '../models/hadith_item.dart';
import '../models/hadith_list_item.dart';

/// Coordinates data access with an in-memory LRU cache for detail views.
/// Handles prefetching of adjacent hadiths.
class HadithRepository {
  final HadithLocalDataSource _localDataSource;

  /// LRU cache for full hadith details — avoids repeated DB reads.
  final _detailCache = _LruCache<String, HadithItem>(maxSize: 30);

  /// Cached category counts (invalidated only on data change).
  Map<String, int>? _categoryCounts;
  int? _totalCount;

  HadithRepository(this._localDataSource);

  // ── Categories ─────────────────────────────────────────────────────────

  Future<List<HadithCategoryInfo>> getCategories() async {
    final counts = await _getCategoryCounts();
    return HadithCategoryInfo.all
        .map((c) => c.copyWith(count: counts[c.id] ?? 0))
        .toList();
  }

  Future<int> getTotalCount() async {
    _totalCount ??= await _localDataSource.getTotalCount();
    return _totalCount!;
  }

  Future<Map<String, int>> _getCategoryCounts() async {
    _categoryCounts ??= await _localDataSource.getCategoryCounts();
    return _categoryCounts!;
  }

  // ── Paginated list ─────────────────────────────────────────────────────

  Future<List<HadithListItem>> getHadithsPaginated({
    required String categoryId,
    int limit = HadithLocalDataSource.defaultPageSize,
    int? afterSortOrder,
  }) {
    return _localDataSource.getHadithsPaginated(
      categoryId: categoryId,
      limit: limit,
      afterSortOrder: afterSortOrder,
    );
  }

  // ── Detail with caching ────────────────────────────────────────────────

  Future<HadithItem?> getHadithDetail(String id) async {
    final cached = _detailCache.get(id);
    if (cached != null) return cached;

    final item = await _localDataSource.getHadithDetail(id);
    if (item != null) _detailCache.put(id, item);
    return item;
  }

  /// Prefetches the next [count] hadiths after [currentSortOrder] in a category.
  /// Runs in the background; results go into the cache.
  Future<void> prefetchNext({
    required String categoryId,
    required int currentSortOrder,
    int count = 3,
  }) async {
    final items = await _localDataSource.getHadithsPaginated(
      categoryId: categoryId,
      limit: count,
      afterSortOrder: currentSortOrder,
    );
    // Fetch full details and cache them
    for (final listItem in items) {
      if (_detailCache.get(listItem.id) == null) {
        final detail = await _localDataSource.getHadithDetail(listItem.id);
        if (detail != null) _detailCache.put(listItem.id, detail);
      }
    }
  }

  // ── On-demand fields ──────────────────────────────────────────────────

  Future<String?> getSanad(String id) async {
    final cached = _detailCache.get(id);
    if (cached != null) return cached.sanad;
    return _localDataSource.getSanad(id);
  }

  Future<String?> getExplanation(String id) async {
    final cached = _detailCache.get(id);
    if (cached != null) return cached.explanation;
    return _localDataSource.getExplanation(id);
  }

  // ── Search ─────────────────────────────────────────────────────────────

  Future<List<HadithListItem>> searchHadiths({
    required String query,
    int limit = HadithLocalDataSource.defaultPageSize,
    int offset = 0,
  }) {
    return _localDataSource.searchHadiths(
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────

  Future<Set<String>> getBookmarks() => _localDataSource.getBookmarks();

  Future<void> toggleBookmark(String hadithId) async {
    final isBookmarked = await _localDataSource.isBookmarked(hadithId);
    if (isBookmarked) {
      await _localDataSource.removeBookmark(hadithId);
    } else {
      await _localDataSource.addBookmark(hadithId);
    }
  }

  Future<bool> isBookmarked(String hadithId) =>
      _localDataSource.isBookmarked(hadithId);
}

/// Simple LRU (Least Recently Used) cache backed by a [LinkedHashMap].
class _LruCache<K, V> {
  final int maxSize;
  // ignore: prefer_collection_literals
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  _LruCache({required this.maxSize});

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value; // Move to end (most recently used)
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    while (_map.length > maxSize) {
      _map.remove(_map.keys.first);
    }
  }
}
