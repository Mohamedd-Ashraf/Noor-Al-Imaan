import 'package:sqflite/sqflite.dart';

import '../models/hadith_item.dart';
import '../models/hadith_list_item.dart';
import 'hadith_database.dart';

/// Performs all SQLite queries for the hadith feature.
/// Uses lightweight projections for list views and full projections for details.
class HadithLocalDataSource {
  final HadithDatabase _hadithDatabase;

  /// Preview text length for list items (characters).
  static const int _previewLength = 150;

  /// Default page size for paginated queries.
  static const int defaultPageSize = 15;

  HadithLocalDataSource(this._hadithDatabase);

  Future<Database> get _db => _hadithDatabase.database;

  // ── Pagination (cursor-based) ──────────────────────────────────────────

  /// Fetches a page of lightweight hadith items for a category.
  /// Uses cursor-based pagination on [sort_order] for stable results.
  /// [afterSortOrder] is the sort_order of the last item in the previous page
  /// (use -1 or null for the first page).
  Future<List<HadithListItem>> getHadithsPaginated({
    required String categoryId,
    int limit = defaultPageSize,
    int? afterSortOrder,
  }) async {
    final db = await _db;
    final cursor = afterSortOrder ?? -1;

    final rows = await db.rawQuery(
      '''
      SELECT id, category_id,
             SUBSTR(arabic_text, 1, $_previewLength) AS arabic_preview,
             topic_ar, topic_en, narrator, reference, grade, sort_order
      FROM hadiths
      WHERE category_id = ? AND sort_order > ?
      ORDER BY sort_order ASC
      LIMIT ?
    ''',
      [categoryId, cursor, limit],
    );

    return rows.map(HadithListItem.fromMap).toList();
  }

  // ── Full detail ────────────────────────────────────────────────────────

  /// Fetches the complete hadith for the detail screen.
  Future<HadithItem?> getHadithDetail(String id) async {
    final db = await _db;
    final rows = await db.query('hadiths', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return HadithItem.fromMap(rows.first);
  }

  /// Fetches multiple hadith details by IDs (for prefetching).
  Future<List<HadithItem>> getHadithDetails(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM hadiths WHERE id IN ($placeholders)',
      ids,
    );
    return rows.map(HadithItem.fromMap).toList();
  }

  // ── On-demand fields ──────────────────────────────────────────────────

  /// Loads only the sanad for a hadith (lazy tab loading).
  Future<String?> getSanad(String id) async {
    final db = await _db;
    final rows = await db.query(
      'hadiths',
      columns: ['sanad'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return rows.first['sanad'] as String?;
  }

  /// Loads only the explanation for a hadith.
  Future<String?> getExplanation(String id) async {
    final db = await _db;
    final rows = await db.query(
      'hadiths',
      columns: ['explanation'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return rows.first['explanation'] as String?;
  }

  // ── Search ─────────────────────────────────────────────────────────────

  /// Searches hadiths across all categories with pagination.
  Future<List<HadithListItem>> searchHadiths({
    required String query,
    int limit = defaultPageSize,
    int offset = 0,
  }) async {
    final db = await _db;
    final pattern = '%$query%';

    final rows = await db.rawQuery(
      '''
      SELECT id, category_id,
             SUBSTR(arabic_text, 1, $_previewLength) AS arabic_preview,
             topic_ar, topic_en, narrator, reference, grade, sort_order
      FROM hadiths
      WHERE arabic_text LIKE ?
         OR topic_ar LIKE ?
         OR topic_en LIKE ?
         OR narrator LIKE ?
         OR reference LIKE ?
      ORDER BY category_id, sort_order
      LIMIT ? OFFSET ?
    ''',
      [pattern, pattern, pattern, pattern, pattern, limit, offset],
    );

    return rows.map(HadithListItem.fromMap).toList();
  }

  // ── Category counts ────────────────────────────────────────────────────

  /// Returns a map of category_id → hadith count.
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT category_id, COUNT(*) as cnt FROM hadiths GROUP BY category_id',
    );
    return {
      for (final row in rows) row['category_id'] as String: row['cnt'] as int,
    };
  }

  /// Returns total hadith count.
  Future<int> getTotalCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM hadiths');
    return result.first['cnt'] as int;
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────

  Future<Set<String>> getBookmarks() async {
    final db = await _db;
    final rows = await db.query('hadith_bookmarks', columns: ['hadith_id']);
    return rows.map((r) => r['hadith_id'] as String).toSet();
  }

  Future<void> addBookmark(String hadithId) async {
    final db = await _db;
    await db.insert('hadith_bookmarks', {
      'hadith_id': hadithId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeBookmark(String hadithId) async {
    final db = await _db;
    await db.delete(
      'hadith_bookmarks',
      where: 'hadith_id = ?',
      whereArgs: [hadithId],
    );
  }

  Future<bool> isBookmarked(String hadithId) async {
    final db = await _db;
    final rows = await db.query(
      'hadith_bookmarks',
      where: 'hadith_id = ?',
      whereArgs: [hadithId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
