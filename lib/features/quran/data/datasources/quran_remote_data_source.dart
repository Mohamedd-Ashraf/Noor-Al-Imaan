import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/surah_model.dart';
import '../models/juz_model.dart';

abstract class QuranRemoteDataSource {
  Future<List<SurahModel>> getAllSurahs();
  Future<SurahModel> getSurah(int surahNumber, {String? edition});
  Future<AyahModel> getAyah(String reference, {String? edition});
  Future<JuzModel> getJuz(int juzNumber, {String? edition});
}

class QuranRemoteDataSourceImpl implements QuranRemoteDataSource {
  final http.Client client;

  QuranRemoteDataSourceImpl({required this.client});

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.surahEndpoint}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'] as List;
        return data.map((surah) => SurahModel.fromJson(surah)).toList();
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<SurahModel> getSurah(int surahNumber, {String? edition}) async {
    try {
      final editionParam = edition ?? ApiConstants.defaultEdition;
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.surahEndpoint}/$surahNumber/$editionParam',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return SurahModel.fromJson(jsonResponse['data']);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<AyahModel> getAyah(String reference, {String? edition}) async {
    try {
      final editionParam = edition ?? ApiConstants.defaultEdition;
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.ayahEndpoint}/$reference/$editionParam',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return AyahModel.fromJson(jsonResponse['data']);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<JuzModel> getJuz(int juzNumber, {String? edition}) async {
    try {
      final editionParam = edition ?? ApiConstants.defaultEdition;
      final response = await client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.juzEndpoint}/$juzNumber/$editionParam',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return JuzModel.fromJson(jsonResponse['data']);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
}
