import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pages that are bundled inside the APK (local fork of qcf_quran_plus).
/// These are already available from the bundle so we only need to download
/// the remaining 604 − 66 = 538 pages.
class _BundledPages {
  static const Set<int> pages = {
    // Al‑Fatiha + start of Al‑Baqarah (essential opening)
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    // Al‑Kahf region
    293, 294, 295, 296, 297,
    // Yasin region
    440, 441, 442, 443, 444,
    // Al‑Mulk region
    571, 572, 573,
    // Last Juz (Amma wa Baed)
    582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595,
    596, 597, 598, 599, 600, 601, 602, 603, 604,
  };

  static bool isBundled(int page) => pages.contains(page);
}

/// Downloads the remaining QCF tajweed font ZIPs that are NOT bundled in the
/// APK.  Fonts are saved to the same directory that [QcfFontLoader] checks
/// first on disk, so once a font is pre‑saved here the loader skips bundle
/// extraction entirely.
///
/// Font ZIP source: GitHub releases of the qcf_quran_plus package.
class QcfFontDownloadService {
  QcfFontDownloadService._();

  static const String _prefKey = 'qcf_fonts_fully_downloaded';
  static const int _totalPages = 604;

  // GitHub releases URL pattern for the zip files.
  // The fonts are published in a companion release of the qcf_quran_plus repo.
  static const String _baseUrl =
      'https://github.com/hussein12347/qcf_quran_plus/raw/main/assets/fonts/qcf_tajweed';

  // Singleton Dio instance with reasonable timeouts.
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // ── Public helpers ──────────────────────────────────────────────────────────

  /// Returns [true] when all 604 fonts are available on disk (or bundled).
  static Future<bool> isFullyDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return true;
    // Verify by checking disk (handles reinstall / cleared storage).
    final dir = await _getFontDirectory();
    int count = 0;
    for (int i = 1; i <= _totalPages; i++) {
      if (_BundledPages.isBundled(i)) {
        count++;
        continue;
      }
      final file = File('${dir.path}/${_getFontName(i)}.ttf');
      if (file.existsSync() && file.lengthSync() > 1000) count++;
    }
    final done = count == _totalPages;
    if (done) {
      await prefs.setBool(_prefKey, true);
    }
    return done;
  }

  /// Returns the number of pages that still need to be downloaded.
  static Future<int> pendingDownloadCount() async {
    final dir = await _getFontDirectory();
    int pending = 0;
    for (int i = 1; i <= _totalPages; i++) {
      if (_BundledPages.isBundled(i)) continue;
      final file = File('${dir.path}/${_getFontName(i)}.ttf');
      if (!file.existsSync() || file.lengthSync() <= 1000) pending++;
    }
    return pending;
  }

  /// Returns [true] if the font for [pageNumber] is available on disk or is
  /// bundled in the APK.
  static Future<bool> isPageAvailable(int pageNumber) async {
    if (_BundledPages.isBundled(pageNumber)) return true;
    final dir = await _getFontDirectory();
    final file = File('${dir.path}/${_getFontName(pageNumber)}.ttf');
    return file.existsSync() && file.lengthSync() > 1000;
  }

  /// Downloads all pending (non‑bundled, non‑cached) fonts.
  ///
  /// [onProgress] receives a value between 0.0 and 1.0.
  /// [onPageDone] is called after each individual page font is saved.
  /// Returns [true] on full success, [false] if any download failed.
  static Future<bool> downloadAll({
    Function(double progress)? onProgress,
    Function(int page)? onPageDone,
    CancelToken? cancelToken,
  }) async {
    final dir = await _getFontDirectory();

    // Collect pages that still need downloading.
    final List<int> pending = [];
    for (int i = 1; i <= _totalPages; i++) {
      if (_BundledPages.isBundled(i)) continue;
      final file = File('${dir.path}/${_getFontName(i)}.ttf');
      if (!file.existsSync() || file.lengthSync() <= 1000) pending.add(i);
    }

    if (pending.isEmpty) {
      await _markComplete();
      onProgress?.call(1.0);
      return true;
    }

    int done = 0;
    bool anyFailed = false;

    for (final page in pending) {
      if (cancelToken?.isCancelled == true) break;
      try {
        await _downloadPage(page, dir);
        done++;
        onPageDone?.call(page);
        onProgress?.call(done / pending.length);
      } catch (e) {
        debugPrint('QcfFontDownloadService: failed page $page – $e');
        anyFailed = true;
      }
    }

    if (!anyFailed) await _markComplete();
    return !anyFailed;
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  static Future<void> _downloadPage(int page, Directory fontDir) async {
    final fontName = _getFontName(page);
    final ttfFile = File('${fontDir.path}/$fontName.ttf');

    // Already cached – skip.
    if (ttfFile.existsSync() && ttfFile.lengthSync() > 1000) return;

    final url = '$_baseUrl/$fontName.zip';
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final zipBytes = Uint8List.fromList(response.data!);
    final ttfBytes = await Isolate.run(() => _extractFont(zipBytes));

    await fontDir.create(recursive: true);
    await ttfFile.writeAsBytes(ttfBytes, flush: true);
  }

  static Uint8List _extractFont(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      if (file.name.endsWith('.ttf')) {
        return Uint8List.fromList(file.content as List<int>);
      }
    }
    throw Exception('QcfFontDownloadService: TTF not found in ZIP');
  }

  static Future<Directory> _getFontDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final fontDir = Directory('${appDir.path}/qcf_fonts');
    if (!fontDir.existsSync()) fontDir.createSync(recursive: true);
    return fontDir;
  }

  static String _getFontName(int page) =>
      'QCF4_tajweed_${page.toString().padLeft(3, '0')}';

  static Future<void> _markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }
}
