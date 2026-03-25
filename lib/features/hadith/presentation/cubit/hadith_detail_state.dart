import 'package:equatable/equatable.dart';

import '../../data/models/hadith_item.dart';

enum HadithDetailStatus { initial, loading, loaded, error }

class HadithDetailState extends Equatable {
  final HadithDetailStatus status;
  final HadithItem? hadith;
  final String? errorMessage;

  /// Whether the sanad has been loaded (for lazy tab loading).
  final bool sanadLoaded;

  /// Whether the explanation has been loaded.
  final bool explanationLoaded;

  const HadithDetailState({
    this.status = HadithDetailStatus.initial,
    this.hadith,
    this.errorMessage,
    this.sanadLoaded = false,
    this.explanationLoaded = false,
  });

  HadithDetailState copyWith({
    HadithDetailStatus? status,
    HadithItem? hadith,
    String? errorMessage,
    bool? sanadLoaded,
    bool? explanationLoaded,
  }) {
    return HadithDetailState(
      status: status ?? this.status,
      hadith: hadith ?? this.hadith,
      errorMessage: errorMessage,
      sanadLoaded: sanadLoaded ?? this.sanadLoaded,
      explanationLoaded: explanationLoaded ?? this.explanationLoaded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hadith,
    errorMessage,
    sanadLoaded,
    explanationLoaded,
  ];
}
