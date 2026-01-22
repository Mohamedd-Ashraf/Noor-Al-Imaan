import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class OfflineAudioProgress {
  final int currentSurah;
  final int totalSurahs;
  final int currentAyah;
  final int totalAyahs;
  final String message;

  const OfflineAudioProgress({
    required this.currentSurah,
    required this.totalSurahs,
    required this.currentAyah,
    required this.totalAyahs,
    required this.message,
  });
}

class OfflineAudioService {
  static const String _keyEnabled = 'offline_audio_enabled';
  static const String _keyEdition = 'offline_audio_edition';

  final SharedPreferences _prefs;
  final http.Client _client;

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
    final root = Directory('${dir.path}${Platform.pathSeparator}offline_audio${Platform.pathSeparator}$edition');
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    return root;
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
        urls.add(url);
      } else {
        urls.add('');
      }
    }

    return urls;
  }

  Future<void> downloadAllQuranAudio({
    required void Function(OfflineAudioProgress progress) onProgress,
    required bool Function() shouldCancel,
  }) async {
    const totalSurahs = 114;

    for (var surah = 1; surah <= totalSurahs; surah++) {
      if (shouldCancel()) return;

      onProgress(
        OfflineAudioProgress(
          currentSurah: surah,
          totalSurahs: totalSurahs,
          currentAyah: 0,
          totalAyahs: 0,
          message: 'Fetching audio URLs for Surah $surah…',
        ),
      );

      final urls = await _fetchAyahAudioUrls(surah);
      final totalAyahs = urls.length;
      final dir = await _surahDir(surah);

      for (var i = 0; i < urls.length; i++) {
        if (shouldCancel()) return;

        final url = urls[i];
        final ayah = i + 1;
        final file = File('${dir.path}${Platform.pathSeparator}ayah_$ayah.mp3');

        if (url.isEmpty) {
          continue;
        }

        if (file.existsSync() && file.lengthSync() > 0) {
          onProgress(
            OfflineAudioProgress(
              currentSurah: surah,
              totalSurahs: totalSurahs,
              currentAyah: ayah,
              totalAyahs: totalAyahs,
              message: 'Already downloaded: Surah $surah Ayah $ayah',
            ),
          );
          continue;
        }

        onProgress(
          OfflineAudioProgress(
            currentSurah: surah,
            totalSurahs: totalSurahs,
            currentAyah: ayah,
            totalAyahs: totalAyahs,
            message: 'Downloading Surah $surah Ayah $ayah…',
          ),
        );

        final resp = await _client.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          await file.writeAsBytes(resp.bodyBytes, flush: true);
        }
      }
    }
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
