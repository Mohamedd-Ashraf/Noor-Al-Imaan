import 'package:equatable/equatable.dart';

abstract class SurahEvent extends Equatable {
  const SurahEvent();

  @override
  List<Object?> get props => [];
}

class GetAllSurahsEvent extends SurahEvent {}

class GetSurahDetailEvent extends SurahEvent {
  final int surahNumber;
  final String? edition;

  const GetSurahDetailEvent(this.surahNumber, {this.edition});

  @override
  List<Object?> get props => [surahNumber, edition];
}
