import 'package:equatable/equatable.dart';

enum TafsirStatus { initial, loading, loaded, error }

class TafsirState extends Equatable {
  final TafsirStatus status;
  final String selectedEdition;
  final String tafsirText;
  final String errorMessage;
  final bool isOfflineContent;
  final bool isDownloadingOffline;
  final int downloadDone;
  final int downloadTotal;
  final String downloadStatusText;

  const TafsirState({
    required this.status,
    required this.selectedEdition,
    this.tafsirText = '',
    this.errorMessage = '',
    this.isOfflineContent = false,
    this.isDownloadingOffline = false,
    this.downloadDone = 0,
    this.downloadTotal = 0,
    this.downloadStatusText = '',
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
    bool? isOfflineContent,
    bool? isDownloadingOffline,
    int? downloadDone,
    int? downloadTotal,
    String? downloadStatusText,
  }) {
    return TafsirState(
      status: status ?? this.status,
      selectedEdition: selectedEdition ?? this.selectedEdition,
      tafsirText: tafsirText ?? this.tafsirText,
      errorMessage: errorMessage ?? this.errorMessage,
      isOfflineContent: isOfflineContent ?? this.isOfflineContent,
      isDownloadingOffline: isDownloadingOffline ?? this.isDownloadingOffline,
      downloadDone: downloadDone ?? this.downloadDone,
      downloadTotal: downloadTotal ?? this.downloadTotal,
      downloadStatusText: downloadStatusText ?? this.downloadStatusText,
    );
  }

  @override
  List<Object?> get props =>
      [
        status,
        selectedEdition,
        tafsirText,
        errorMessage,
        isOfflineContent,
        isDownloadingOffline,
        downloadDone,
        downloadTotal,
        downloadStatusText,
      ];
}
