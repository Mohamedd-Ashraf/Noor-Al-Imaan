import 'package:sqflite/sqflite.dart';

import '../hadith_data.dart';

/// Manages the SQLite database lifecycle for hadiths.
/// Seeds data from the embedded static source on first creation.
class HadithDatabase {
  static const _dbName = 'hadiths.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_dbName';

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Enable WAL mode for better concurrent read performance
        await db.rawQuery('PRAGMA journal_mode=WAL');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE hadiths (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        arabic_text TEXT NOT NULL,
        reference TEXT NOT NULL,
        book_reference TEXT NOT NULL,
        sanad TEXT NOT NULL,
        narrator TEXT NOT NULL,
        grade TEXT NOT NULL,
        graded_by TEXT NOT NULL,
        topic_ar TEXT NOT NULL,
        topic_en TEXT NOT NULL,
        explanation TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE hadith_bookmarks (
        hadith_id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');

    // Indexes for common queries
    await db.execute(
      'CREATE INDEX idx_hadiths_category ON hadiths(category_id, sort_order)',
    );
    await db.execute(
      'CREATE INDEX idx_hadiths_search ON hadiths(topic_ar, topic_en, narrator)',
    );

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final batch = db.batch();
    final categories = HadithData.categories;

    for (final category in categories) {
      for (var i = 0; i < category.items.length; i++) {
        final hadith = category.items[i];
        batch.insert('hadiths', hadith.toMap(category.id, i));
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
