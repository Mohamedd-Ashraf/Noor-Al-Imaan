import 'package:equatable/equatable.dart';
import '../../../domain/entities/surah.dart';

abstract class SurahState extends Equatable {
  const SurahState();

  @override
  List<Object?> get props => [];
}

class SurahInitial extends SurahState {}

class SurahLoading extends SurahState {}

class SurahListLoaded extends SurahState {
  final List<Surah> surahs;

  const SurahListLoaded(this.surahs);

  @override
  List<Object?> get props => [surahs];
}

class SurahDetailLoaded extends SurahState {
  final Surah surah;

  const SurahDetailLoaded(this.surah);

  @override
  List<Object?> get props => [surah];
}

class SurahError extends SurahState {
  final String message;

  const SurahError(this.message);

  @override
  List<Object?> get props => [message];
}
