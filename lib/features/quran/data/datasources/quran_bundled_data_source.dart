import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/error/exceptions.dart';
import '../models/surah_model.dart';

abstract class QuranBundledDataSource {
  Future<List<SurahModel>> getBundledAllSurahs();
  Future<SurahModel> getBundledSurah(int surahNumber);
}

class QuranBundledDataSourceImpl implements QuranBundledDataSource {
  static const String _surahListPath = 'assets/offline/surah_list.json';

  String _surahPath(int surahNumber) => 'assets/offline/surah_$surahNumber.json';

  @override
  Future<List<SurahModel>> getBundledAllSurahs() async {
    try {
      final raw = await rootBundle.loadString(_surahListPath);
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
  Future<SurahModel> getBundledSurah(int surahNumber) async {
    try {
      final raw = await rootBundle.loadString(_surahPath(surahNumber));
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return SurahModel.fromJson(decoded);
    } catch (_) {
      throw CacheException();
    }
  }
}
