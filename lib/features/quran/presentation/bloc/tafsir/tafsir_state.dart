import 'package:equatable/equatable.dart';

enum TafsirStatus { initial, loading, loaded, error }

class TafsirState extends Equatable {
  final TafsirStatus status;
  final String selectedEdition;
  final String tafsirText;
  final String errorMessage;

  const TafsirState({
    required this.status,
    required this.selectedEdition,
    this.tafsirText = '',
    this.errorMessage = '',
  });

  factory TafsirState.initial(String edition) => TafsirState(
        status: TafsirStatus.initial,
        selectedEdition: edition,
      );

  TafsirState copyWith({
    TafsirStatus? status,
    String? selectedEdition,
    String? tafsirText,
    String? errorMessage,
  }) {
    return TafsirState(
      status: status ?? this.status,
      selectedEdition: selectedEdition ?? this.selectedEdition,
      tafsirText: tafsirText ?? this.tafsirText,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, selectedEdition, tafsirText, errorMessage];
}
