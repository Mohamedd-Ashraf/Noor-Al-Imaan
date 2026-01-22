import 'package:equatable/equatable.dart';
import 'surah.dart';

class Juz extends Equatable {
  final int number;
  final List<Ayah> ayahs;

  const Juz({
    required this.number,
    required this.ayahs,
  });

  @override
  List<Object?> get props => [number, ayahs];
}
