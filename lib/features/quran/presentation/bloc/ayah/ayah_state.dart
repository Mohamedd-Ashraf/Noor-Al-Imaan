import 'package:equatable/equatable.dart';
import '../../../domain/entities/surah.dart';

abstract class AyahState extends Equatable {
  const AyahState();

  @override
  List<Object?> get props => [];
}

class AyahInitial extends AyahState {}

class AyahLoading extends AyahState {}

class AyahLoaded extends AyahState {
  final Ayah ayah;

  const AyahLoaded(this.ayah);

  @override
  List<Object?> get props => [ayah];
}

class AyahError extends AyahState {
  final String message;

  const AyahError(this.message);

  @override
  List<Object?> get props => [message];
}
