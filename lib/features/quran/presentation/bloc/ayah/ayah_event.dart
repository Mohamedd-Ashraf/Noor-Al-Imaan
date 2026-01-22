import 'package:equatable/equatable.dart';

abstract class AyahEvent extends Equatable {
  const AyahEvent();

  @override
  List<Object?> get props => [];
}

class GetAyahDetailEvent extends AyahEvent {
  final String reference;
  final String? edition;

  const GetAyahDetailEvent(this.reference, {this.edition});

  @override
  List<Object?> get props => [reference, edition];
}
