import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class OfflineAudioProgress {
  final int currentSurah;
  final int totalSurahs;
  final int currentAyah;
  final int totalAyahs;
  final int completedFiles;
  final int totalFiles;
  final double percentage;
  final String message;

  const OfflineAudioProgress({
    required this.currentSurah,
    required this.totalSurahs,
    required this.currentAyah,
    required this.totalAyahs,
    required this.completedFiles,
    required this.totalFiles,
    required this.percentage,
    required this.message,
  });

  /// Create progress with auto-calculated percentage
  factory OfflineAudioProgress.create({
    required int currentSurah,
    required int totalSurahs,
    required int currentAyah,
    required int totalAyahs,
    required int completedFiles,
    required int totalFiles,
    required String message,
  }) {
    final percentage = totalFiles > 0 ? (completedFiles / totalFiles) * 100 : 0.0;
    return OfflineAudioProgress(
      currentSurah: currentSurah,
      totalSurahs: totalSurahs,
      currentAyah: currentAyah,
      totalAyahs: totalAyahs,
      completedFiles: completedFiles,
      totalFiles: totalFiles,
      percentage: percentage,
      message: message,
    );
  }
}

class _DownloadTask {
  final int surahNumber;
  final int ayahNumber;
  final String url;
  final File file;

  const _DownloadTask({
    required this.surahNumber,
    required this.ayahNumber,
    required this.url,
    required this.file,
  });
}

class OfflineAudioService {
  static const String _keyEnabled = 'offline_audio_enabled';
  static const String _keyEdition = 'offline_audio_edition';

  final SharedPreferences _prefs;
  final http.Client _client;

  static const int _totalQuranFiles = 6236;
  static const int _minValidAudioBytes = 8 * 1024;

  OfflineAudioService(this._prefs, this._client);

  bool get enabled => _prefs.getBool(_keyEnabled) ?? false;

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(_keyEnabled, value);
  }

  /// Default: verse-by-verse Mishary Alafasy.
  String get edition => _prefs.getString(_keyEdition) ?? 'ar.alafasy';

  Future<void> setEdition(String value) async {
    await _prefs.setString(_keyEdition, value);
  }

  Future<Directory> _audioRootDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory(
      '${dir.path}${Platform.pathSeparator}offline_audio${Platform.pathSeparator}$edition',
    );
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    return root;
  }

  Future<Directory> _audioBaseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final base = Directory('${dir.path}${Platform.pathSeparator}offline_audio');
    if (!base.existsSync()) {
      base.createSync(recursive: true);
    }
    return base;
  }

  Future<Directory> _surahDir(int surahNumber) async {
    final root = await _audioRootDir();
    final dir = Directory('${root.path}${Platform.pathSeparator}surah_$surahNumber');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<bool> hasAnyAudioDownloaded() async {
    final root = await _audioRootDir();
    if (!root.existsSync()) return false;
    return root.listSync(recursive: true).any((e) => e is File && e.path.endsWith('.mp3'));
  }

  Future<void> deleteAllAudio() async {
    final root = await _audioRootDir();
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  }

  /// Delete audio for specific surahs
  Future<void> deleteSurahsAudio(List<int> surahNumbers) async {
    print('🗑️ [Delete] Deleting audio for surahs: $surahNumbers');
    for (final surah in surahNumbers) {
      final dir = await _surahDir(surah);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        print('✅ [Delete] Deleted surah $surah');
      }
    }
  }

  /// Get list of downloaded surahs
  Future<List<int>> getDownloadedSurahs() async {
    final root = await _audioRootDir();
    if (!root.existsSync()) return [];

    final downloaded = <int>[];
    for (int i = 1; i <= 114; i++) {
      final dir = await _surahDir(i);
      if (dir.existsSync()) {
        final files = dir.listSync().where((e) => e is File && e.path.endsWith('.mp3')).toList();
        if (files.isNotEmpty) {
          downloaded.add(i);
        }
      }
    }
    return downloaded;
  }

  /// Get download statistics
  Future<Map<String, dynamic>> getDownloadStatistics() async {
    final root = await _audioRootDir();
    if (!root.existsSync()) {
      return {
        'downloadedFiles': 0,
        'totalFiles': _totalQuranFiles,
        'downloadedSurahs': 0,
        'totalSurahs': 114,
        'totalSizeMB': 0.0,
        'percentage': 0.0,
      };
    }

    int fileCount = 0;
    int totalSize = 0;
    final downloadedSurahs = await getDownloadedSurahs();

    final allFiles = root.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.mp3'));
    for (final file in allFiles) {
      fileCount++;
      totalSize += file.lengthSync();
    }

    return {
      'downloadedFiles': fileCount,
      'totalFiles': _totalQuranFiles,
      'downloadedSurahs': downloadedSurahs.length,
      'totalSurahs': 114,
      'totalSizeMB': totalSize / 1048576,
      'percentage': (fileCount / _totalQuranFiles) * 100,
    };
  }

  /// Quick quality check from local files (no network):
  /// returns whether files are likely old/high bitrate based on average file size.
  Future<Map<String, dynamic>> assessCurrentEditionAudioQuality() async {
    final stats = await getDownloadStatistics();
    final downloadedFiles = (stats['downloadedFiles'] as num?)?.toInt() ?? 0;
    final totalSizeMB = (stats['totalSizeMB'] as num?)?.toDouble() ?? 0.0;

    if (downloadedFiles == 0) {
      return {
        'status': 'empty',
        'averageFileKB': 0.0,
        'estimatedBitrate': 'unknown',
        'likelyHighBitrate': false,
      };
    }

    final avgFileKB = (totalSizeMB * 1024) / downloadedFiles;

    final bitrateStats = await analyzeCurrentEditionDownloadedBitrates(maxFiles: 300);
    final dominantBitrate = (bitrateStats['dominantBitrate'] as String?) ?? 'unknown';
    final dominantMatch = RegExp(r'^(\d+)kbps$').firstMatch(dominantBitrate);
    final dominantBitrateNum = int.tryParse(dominantMatch?.group(1) ?? '');
    final scannedFiles = (bitrateStats['scannedFiles'] as num?)?.toInt() ?? 0;

    final estimatedBitrate = dominantBitrate != 'unknown'
        ? dominantBitrate
        : (avgFileKB > 95 ? 'likely 128kbps+' : 'likely 64kbps');

    final likelyHighBitrate =
        scannedFiles >= 30 && dominantBitrateNum != null && dominantBitrateNum > 96;

    return {
      'status': 'ok',
      'averageFileKB': avgFileKB,
      'estimatedBitrate': estimatedBitrate,
      'likelyHighBitrate': likelyHighBitrate,
      'scannedFiles': scannedFiles,
      'dominantBitrate': dominantBitrate,
    };
  }

  /// Get storage stats across ALL downloaded reciters/editions
  Future<Map<String, dynamic>> getAllEditionsStorageStats() async {
    final base = await _audioBaseDir();
    if (!base.existsSync()) {
      return {
        'totalSizeMB': 0.0,
        'currentEditionSizeMB': 0.0,
        'otherEditionsSizeMB': 0.0,
        'editionsCount': 0,
        'otherEditionsCount': 0,
      };
    }

    final currentEditionRoot = await _audioRootDir();
    final editionDirs = base
        .listSync()
        .whereType<Directory>()
        .toList();

    int totalBytes = 0;
    int currentBytes = 0;

    for (final editionDir in editionDirs) {
      int editionBytes = 0;
      final files = editionDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp3'));
      for (final file in files) {
        editionBytes += file.lengthSync();
      }

      totalBytes += editionBytes;
      if (editionDir.path == currentEditionRoot.path) {
        currentBytes = editionBytes;
      }
    }

    final otherBytes = totalBytes - currentBytes;
    final otherCount = editionDirs.where((d) => d.path != currentEditionRoot.path).length;

    return {
      'totalSizeMB': totalBytes / 1048576,
      'currentEditionSizeMB': currentBytes / 1048576,
      'otherEditionsSizeMB': otherBytes / 1048576,
      'editionsCount': editionDirs.length,
      'otherEditionsCount': otherCount,
    };
  }

  /// Keep only the currently selected reciter files and remove old editions
  Future<void> deleteOtherEditionsAudio() async {
    final base = await _audioBaseDir();
    if (!base.existsSync()) return;

    final currentEditionRoot = await _audioRootDir();
    final editionDirs = base
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path != currentEditionRoot.path)
        .toList();

    for (final dir in editionDirs) {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    }
  }

  String _force64KbpsUrl(String url) {
    return url.replaceFirst(RegExp(r'/audio/\d+/'), '/audio/64/');
  }

  int? _detectMp3BitrateFromBytes(Uint8List bytes) {
    if (bytes.length < 4) return null;

    int offset = 0;
    if (bytes.length >= 10 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      final tagSize = ((bytes[6] & 0x7F) << 21) |
          ((bytes[7] & 0x7F) << 14) |
          ((bytes[8] & 0x7F) << 7) |
          (bytes[9] & 0x7F);
      offset = 10 + tagSize;
    }

    for (int i = offset; i + 3 < bytes.length; i++) {
      final b1 = bytes[i];
      final b2 = bytes[i + 1];
      final b3 = bytes[i + 2];

      final isSync = b1 == 0xFF && (b2 & 0xE0) == 0xE0;
      if (!isSync) continue;

      final versionBits = (b2 >> 3) & 0x03; // 00=2.5, 10=2, 11=1
      final layerBits = (b2 >> 1) & 0x03; // 01=L3,10=L2,11=L1
      final bitrateIndex = (b3 >> 4) & 0x0F;

      if (versionBits == 0x01 || layerBits == 0x00 || bitrateIndex == 0x00 || bitrateIndex == 0x0F) {
        continue;
      }

      final isMpeg1 = versionBits == 0x03;

      const mpeg1Layer1 = [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0];
      const mpeg1Layer2 = [0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0];
      const mpeg1Layer3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0];
      const mpeg2Layer1 = [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0];
      const mpeg2Layer2Or3 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0];

      List<int> table;
      switch (layerBits) {
        case 0x03: // Layer I
          table = isMpeg1 ? mpeg1Layer1 : mpeg2Layer1;
          break;
        case 0x02: // Layer II
          table = isMpeg1 ? mpeg1Layer2 : mpeg2Layer2Or3;
          break;
        case 0x01: // Layer III
          table = isMpeg1 ? mpeg1Layer3 : mpeg2Layer2Or3;
          break;
        default:
          return null;
      }

      final bitrate = table[bitrateIndex];
      if (bitrate > 0) return bitrate;
    }

    return null;
  }

  Future<int?> _detectMp3BitrateFromFile(File file) async {
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final bytes = await raf.read(16384);
      return _detectMp3BitrateFromBytes(bytes);
    } catch (_) {
      return null;
    } finally {
      await raf?.close();
    }
  }

  Future<Map<String, dynamic>> analyzeCurrentEditionDownloadedBitrates({
    int maxFiles = 0,
  }) async {
    final root = await _audioRootDir();
    if (!root.existsSync()) {
      return {
        'scannedFiles': 0,
        'unknownFiles': 0,
        'distribution': <String, int>{},
        'dominantBitrate': 'unknown',
      };
    }

    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.mp3'))
        .toList();

    final toScan = maxFiles > 0 && files.length > maxFiles
        ? files.take(maxFiles).toList()
        : files;

    final distribution = <String, int>{};
    int unknownFiles = 0;

    for (final file in toScan) {
      final bitrate = await _detectMp3BitrateFromFile(file);
      if (bitrate == null) {
        unknownFiles++;
        continue;
      }
      final key = '${bitrate}kbps';
      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    String dominantBitrate = 'unknown';
    if (distribution.isNotEmpty) {
      final sorted = distribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      dominantBitrate = sorted.first.key;
    }

    return {
      'scannedFiles': toScan.length,
      'unknownFiles': unknownFiles,
      'distribution': distribution,
      'dominantBitrate': dominantBitrate,
    };
  }

  Future<Map<String, dynamic>> inspectCurrentEditionDownloadPlan() async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.surahEndpoint}/1/$edition',
      );
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        return {
          'edition': edition,
          'sourceBitrate': 0,
          'downloadBitrate': 64,
          'status': 'unavailable',
        };
      }

      final decoded = json.decode(res.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();
      if (ayahs.isEmpty) {
        return {
          'edition': edition,
          'sourceBitrate': 0,
          'downloadBitrate': 64,
          'status': 'empty',
        };
      }

      final sampleUrl = (ayahs.first['audio'] as String?) ?? '';
      final match = RegExp(r'/audio/(\d+)/').firstMatch(sampleUrl);
      final sourceBitrate = int.tryParse(match?.group(1) ?? '') ?? 0;

      return {
        'edition': edition,
        'sourceBitrate': sourceBitrate,
        'downloadBitrate': 64,
        'sampleUrl': sampleUrl,
        'optimizedSampleUrl': sampleUrl.isNotEmpty
            ? _force64KbpsUrl(sampleUrl)
            : '',
        'status': 'ok',
      };
    } catch (_) {
      return {
        'edition': edition,
        'sourceBitrate': 0,
        'downloadBitrate': 64,
        'status': 'error',
      };
    }
  }

  Future<List<String>> _fetchAyahAudioUrls(int surahNumber) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surahEndpoint}/$surahNumber/$edition');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch audio URLs');
    }

    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();

    final urls = <String>[];
    for (final a in ayahs) {
      final url = a['audio'];
      if (url is String && url.isNotEmpty) {
        // Force 64kbps for any source bitrate (128/192/etc)
        // Example: /audio/192/ar.alafasy/1.mp3 -> /audio/64/ar.alafasy/1.mp3
        final optimizedUrl = _force64KbpsUrl(url);
        urls.add(optimizedUrl);
      } else {
        urls.add('');
      }
    }

    return urls;
  }

  /// Download audio for specific surahs only (selective download)
  Future<void> downloadSurahs({
    required List<int> surahNumbers,
    required void Function(OfflineAudioProgress progress) onProgress,
    required bool Function() shouldCancel,
  }) async {
    print('🚀 [Selective Download] Starting download for ${surahNumbers.length} surahs');
    print('📋 [Selective Download] Surahs: $surahNumbers');
    
    await _downloadVerseByVerse(
      onProgress: onProgress,
      shouldCancel: shouldCancel,
      specificSurahs: surahNumbers,
    );
  }

  Future<void> downloadAllQuranAudio({
    required void Function(OfflineAudioProgress progress) onProgress,
    required bool Function() shouldCancel,
  }) async {
    print('🚀 [Offline Audio] Starting optimized verse-by-verse download for edition: $edition');
    print('🔽 [Offline Audio] Using 30 concurrent downloads + 64kbps audio (65% smaller)...');
    
    // Start verse-by-verse download with optimized settings
    await _downloadVerseByVerse(
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// Downloads Quran audio verse-by-verse (fallback method)
  Future<void> _downloadVerseByVerse({
    required void Function(OfflineAudioProgress progress) onProgress,
    required bool Function() shouldCancel,
    List<int>? specificSurahs,
  }) async {
    final downloadSurahs = specificSurahs ?? List.generate(114, (i) => i + 1);
    final totalSurahs = downloadSurahs.length;
    
    print('🔽 [Verse-by-Verse] Starting verse-by-verse download...');
    print('📊 [Verse-by-Verse] Downloading ${downloadSurahs.length} surahs');
    const concurrentDownloads = 30; // Increased for better download speed
    print('⚙️ [Verse-by-Verse] Concurrent downloads: $concurrentDownloads');

    // Prepare all download tasks
    final tasks = <_DownloadTask>[];
    int totalAyahsCount = 0;

    // First pass: Fetch all URLs and prepare tasks
    print('📋 [Verse-by-Verse] Step 1: Preparing download list...');
    for (var surah in downloadSurahs) {
      if (shouldCancel()) {
        print('⛔ [Verse-by-Verse] Cancelled during preparation');
        return;
      }

      onProgress(
        OfflineAudioProgress.create(
          currentSurah: surah,
          totalSurahs: totalSurahs,
          currentAyah: 0,
          totalAyahs: 0,
          completedFiles: 0,
          totalFiles: 0,
          message: 'Preparing Surah $surah…',
        ),
      );

      final urls = await _fetchAyahAudioUrls(surah);
      final dir = await _surahDir(surah);

      for (var i = 0; i < urls.length; i++) {
        final url = urls[i];
        final ayah = i + 1;
        final file = File('${dir.path}${Platform.pathSeparator}ayah_$ayah.mp3');

        if (url.isEmpty) continue;

        // Skip only if file looks valid; tiny partial files are treated as broken.
        if (file.existsSync()) {
          final existingBytes = file.lengthSync();
          if (existingBytes >= _minValidAudioBytes) {
            continue;
          }
          try {
            file.deleteSync();
          } catch (_) {}
        }

        tasks.add(_DownloadTask(
          surahNumber: surah,
          ayahNumber: ayah,
          url: url,
          file: file,
        ));
      }
      totalAyahsCount += urls.length;
    }

    print('📊 [Verse-by-Verse] Preparation complete: ${tasks.length} files to download');

    if (shouldCancel()) {
      print('⛔ [Verse-by-Verse] Cancelled before download start');
      return;
    }

    // Second pass: Download in parallel batches
    int successfulCount = 0;
    int processedCount = 0;
    int failedCount = 0;
    var lastLoggedBatch = 0;
    
    print('⬇️ [Verse-by-Verse] Step 2: Starting downloads...');
    for (var i = 0; i < tasks.length; i += concurrentDownloads) {
      if (shouldCancel()) {
        print('⛔ [Verse-by-Verse] Cancelled during download');
        return;
      }

      final batch = tasks.skip(i).take(concurrentDownloads).toList();
      final batchNumber = (i ~/ concurrentDownloads) + 1;
      final totalBatches = (tasks.length / concurrentDownloads).ceil();
      
      if (batchNumber >= lastLoggedBatch + 10 || batchNumber == 1) {
        print('📦 [Verse-by-Verse] Batch $batchNumber/$totalBatches (${successfulCount}/${tasks.length} files successful)');
        lastLoggedBatch = batchNumber;
      }
      
      // Download batch in parallel
      await Future.wait(
        batch.map((task) async {
          if (shouldCancel()) return;

          onProgress(
            OfflineAudioProgress.create(
              currentSurah: task.surahNumber,
              totalSurahs: totalSurahs,
              currentAyah: task.ayahNumber,
              totalAyahs: totalAyahsCount,
              completedFiles: successfulCount,
              totalFiles: tasks.length,
              message: 'Downloading ${processedCount + 1}/${tasks.length}…',
            ),
          );

          final success = await _downloadTaskWithRetries(
            task,
            shouldCancel: shouldCancel,
          );

          if (success) {
            successfulCount++;
          } else {
            failedCount++;
          }

          processedCount++;
        }),
      );
    }

    print('✅ [Verse-by-Verse] Download complete!');
    print('📊 [Verse-by-Verse] Summary: $successfulCount successful, $failedCount failed');

    // Final progress update
    onProgress(
      OfflineAudioProgress.create(
        currentSurah: totalSurahs,
        totalSurahs: totalSurahs,
        currentAyah: 0,
        totalAyahs: 0,
        completedFiles: successfulCount,
        totalFiles: tasks.length,
        message: failedCount > 0
            ? 'Download complete with $failedCount failed file(s) after retries'
            : 'Download complete! ($successfulCount files)',
      ),
    );
  }

  Future<bool> _downloadTaskWithRetries(
    _DownloadTask task, {
    required bool Function() shouldCancel,
    int maxAttempts = 3,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (shouldCancel()) return false;

      try {
        final resp = await _client.get(Uri.parse(task.url));
        if (resp.statusCode == 200 && resp.bodyBytes.length >= _minValidAudioBytes) {
          await task.file.writeAsBytes(resp.bodyBytes, flush: true);
          final bitrate = _detectMp3BitrateFromBytes(resp.bodyBytes);
          print(
            '🎵 [Bitrate] Surah ${task.surahNumber}:${task.ayahNumber} '
            '=> ${bitrate != null ? '${bitrate}kbps' : 'unknown'} '
            '(bytes=${resp.bodyBytes.length})',
          );
          return true;
        }

        print(
          '⚠️ [Verse-by-Verse] Attempt $attempt/$maxAttempts failed '
          'for Surah ${task.surahNumber}:${task.ayahNumber} '
          '(HTTP ${resp.statusCode}, bytes=${resp.bodyBytes.length})',
        );
      } catch (e) {
        print(
          '❌ [Verse-by-Verse] Attempt $attempt/$maxAttempts error '
          'for Surah ${task.surahNumber}:${task.ayahNumber}: $e',
        );
      }

      try {
        if (task.file.existsSync()) {
          task.file.deleteSync();
        }
      } catch (_) {}

      if (attempt < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }

    return false;
  }

  Future<File?> getLocalAyahAudioFile({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final dir = await _surahDir(surahNumber);
    final file = File('${dir.path}${Platform.pathSeparator}ayah_$ayahNumber.mp3');
    if (file.existsSync() && file.lengthSync() > 0) {
      return file;
    }
    return null;
  }
}
