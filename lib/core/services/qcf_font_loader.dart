import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads, caches, and registers QCF page fonts at runtime so the APK
/// does not need to bundle the 51 MB of QCF WOFF files.
///
/// **Usage — set the base URL once at app start (e.g. in main.dart):**
/// ```dart
/// QcfFontLoader.instance.fontsBaseUrl =
///     'https://your-project.web.app/qcf_fonts';
/// ```
///
/// Then call `ensurePageFont(pageNumber)` before rendering a [QcfPage].
///
/// **Font naming convention:**
///   - File on server : `QCF4{page:03d}_X-Regular.woff`
///   - Flutter family : `packages/qcf_quran/QCF_P{page:03d}`
///
/// The qualified family name (`packages/qcf_quran/…`) matches what Flutter
/// resolves when a TextStyle specifies `package: 'qcf_quran'` — so the page
/// widget picks up the dynamically registered font transparently.
class QcfFontLoader {
  QcfFontLoader._();

  static final QcfFontLoader instance = QcfFontLoader._();

  /// Base URL where the 604 WOFF font files are hosted (no trailing slash).
  ///
  /// Examples:
  ///   `"https://your-project.web.app/qcf_fonts"`
  ///   `"https://raw.githubusercontent.com/you/repo/main/qcf_fonts"`
  ///   `"https://storage.googleapis.com/your-bucket/qcf_fonts"`
  String fontsBaseUrl = '';

  final _dio = Dio(BaseOptions(responseType: ResponseType.bytes));

  /// Pages whose font is successfully registered with the Flutter engine.
  final Set<int> _loadedPages = {};

  /// In-flight loads — ensures we never download the same font twice.
  final Map<int, Future<void>> _pendingLoads = {};

  Directory? _cacheDir;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns true if the font for [page] is already in the Flutter registry.
  bool isLoaded(int page) => _loadedPages.contains(page);

  /// Ensures the font for [page] is registered.  Safe to call many times for
  /// the same page — subsequent calls return immediately (no download).
  Future<void> ensurePageFont(int page) {
    assert(page >= 1 && page <= 604, 'page must be 1..604');
    if (_loadedPages.contains(page)) return Future.value();
    return _pendingLoads.putIfAbsent(page, () => _loadAndRegister(page));
  }

  /// Fire-and-forget pre-fetch for adjacent pages.
  void prefetchPages(List<int> pages) {
    for (final p in pages) {
      if (p >= 1 && p <= 604) ensurePageFont(p).ignore();
    }
  }

  /// Number of WOFF files currently cached on disk.
  Future<int> cachedPagesCount() async {
    final dir = await _getCacheDir();
    if (!await dir.exists()) return 0;
    int count = 0;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.woff')) count++;
    }
    return count;
  }

  /// `true` when all 604 page fonts are cached.
  Future<bool> isFullyDownloaded() async => (await cachedPagesCount()) >= 604;

  /// Downloads every missing font sequentially.
  /// [onProgress] receives (pagesDownloaded, total=604).
  Future<void> downloadAll({
    void Function(int downloaded, int total)? onProgress,
  }) async {
    for (int page = 1; page <= 604; page++) {
      await ensurePageFont(page);
      onProgress?.call(page, 604);
    }
  }

  /// Deletes all cached WOFF files and clears the in-memory registry.
  /// Call only when freeing storage — pages will re-download on next access.
  Future<void> clearCache() async {
    _loadedPages.clear();
    _pendingLoads.clear();
    final dir = await _getCacheDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    _cacheDir = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Directory> _getCacheDir() async {
    _cacheDir ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/qcf_fonts',
    );
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<void> _loadAndRegister(int page) async {
    try {
      final bytes = await _getFontBytes(page);
      // This is the qualified name Flutter uses when a TextStyle has
      //   fontFamily: 'QCF_P001', package: 'qcf_quran'
      final family =
          'packages/qcf_quran/QCF_P${page.toString().padLeft(3, '0')}';
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      _loadedPages.add(page);
    } finally {
      _pendingLoads.remove(page);
    }
  }

  Future<Uint8List> _getFontBytes(int page) async {
    final fileName = 'QCF4${page.toString().padLeft(3, '0')}_X-Regular.woff';
    final cacheFile = File('${(await _getCacheDir()).path}/$fileName');

    if (await cacheFile.exists()) {
      return cacheFile.readAsBytes();
    }

    if (fontsBaseUrl.isEmpty) {
      throw StateError(
        'QcfFontLoader.fontsBaseUrl must be set before loading fonts.\n'
        'Set it in main.dart: QcfFontLoader.instance.fontsBaseUrl = "https://...";',
      );
    }

    // Download (validated range: 1-604, file name is deterministic).
    final url = '$fontsBaseUrl/$fileName';
    final response = await _dio.get<List<int>>(url);
    final data = Uint8List.fromList(response.data!);

    // Persist to disk cache.
    await cacheFile.writeAsBytes(data, flush: true);
    return data;
  }
}
