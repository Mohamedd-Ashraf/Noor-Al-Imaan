import '../../domain/entities/surah.dart';

class SurahModel extends Surah {
  const SurahModel({
    required super.number,
    required super.name,
    required super.englishName,
    required super.englishNameTranslation,
    required super.numberOfAyahs,
    required super.revelationType,
    super.ayahs,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
      ayahs: json['ayahs'] != null
          ? (json['ayahs'] as List)
              .map((ayah) => AyahModel.fromJson(ayah))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'numberOfAyahs': numberOfAyahs,
      'revelationType': revelationType,
      'ayahs': ayahs?.map((ayah) => (ayah as AyahModel).toJson()).toList(),
    };
  }
}

class AyahModel extends Ayah {
  const AyahModel({
    required super.number,
    required super.text,
    required super.numberInSurah,
    required super.juz,
    required super.manzil,
    required super.page,
    required super.ruku,
    required super.hizbQuarter,
    required super.sajda,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      manzil: json['manzil'] as int,
      page: json['page'] as int,
      ruku: json['ruku'] as int,
      hizbQuarter: json['hizbQuarter'] as int,
      sajda: json['sajda'] is bool 
          ? json['sajda'] as bool 
          : json['sajda'] is Map 
              ? true 
              : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
    };
  }
}
