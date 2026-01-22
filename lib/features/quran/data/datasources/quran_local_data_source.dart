import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/surah_model.dart';

abstract class QuranLocalDataSource {
  Future<void> cacheAllSurahs(List<SurahModel> surahs);
  Future<List<SurahModel>> getCachedAllSurahs();

  Future<void> cacheSurah(SurahModel surah, {String? edition});
  Future<SurahModel> getCachedSurah(int surahNumber, {String? edition});
}

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  static const String _keySurahList = 'cached_surah_list_v1';
  static const String _keySurahPrefix = 'cached_surah_v1_';

  final SharedPreferences prefs;

  QuranLocalDataSourceImpl({required this.prefs});

  String _normalizeEdition(String? edition) {
    return (edition == null || edition.isEmpty)
        ? ApiConstants.defaultEdition
        : edition;
  }

  bool _isCacheableEdition(String? edition) {
    final normalized = _normalizeEdition(edition);
    return normalized == ApiConstants.defaultEdition;
  }

  String _surahKey(int surahNumber, {String? edition}) {
    final normalized = _normalizeEdition(edition);
    return '$_keySurahPrefix$surahNumber:$normalized';
  }

  @override
  Future<void> cacheAllSurahs(List<SurahModel> surahs) async {
    final payload = json.encode(surahs.map((s) => s.toJson()).toList());
    await prefs.setString(_keySurahList, payload);
  }

  @override
  Future<List<SurahModel>> getCachedAllSurahs() async {
    final raw = prefs.getString(_keySurahList);
    if (raw == null || raw.isEmpty) {
      throw CacheException();
    }

    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map((m) => SurahModel.fromJson(m))
          .toList();
    } catch (_) {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheSurah(SurahModel surah, {String? edition}) async {
    if (!_isCacheableEdition(edition)) {
      return;
    }

    final payload = json.encode(surah.toJson());
    await prefs.setString(_surahKey(surah.number, edition: edition), payload);
  }

  @override
  Future<SurahModel> getCachedSurah(int surahNumber, {String? edition}) async {
    if (!_isCacheableEdition(edition)) {
      throw CacheException();
    }

    final raw = prefs.getString(_surahKey(surahNumber, edition: edition));
    if (raw == null || raw.isEmpty) {
      throw CacheException();
    }

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return SurahModel.fromJson(decoded);
    } catch (_) {
      throw CacheException();
    }
  }
}
