import '../../domain/entities/juz.dart';
import 'surah_model.dart';

class JuzModel extends Juz {
  const JuzModel({
    required super.number,
    required super.ayahs,
  });

  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      number: json['number'] as int,
      ayahs: (json['ayahs'] as List)
          .map((ayah) => AyahModel.fromJson(ayah))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'ayahs': ayahs.map((ayah) => (ayah as AyahModel).toJson()).toList(),
    };
  }
}
