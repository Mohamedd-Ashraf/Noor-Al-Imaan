import 'package:equatable/equatable.dart';

abstract class TafsirDownloadState extends Equatable {
  const TafsirDownloadState();

  @override
  List<Object?> get props => [];
}

class TafsirDownloadIdle extends TafsirDownloadState {
  const TafsirDownloadIdle();
}

class TafsirDownloadResumable extends TafsirDownloadState {
  final String edition;
  final String scope;
  final List<String> pendingAyahs;
  final List<String> completedAyahs;
  final int totalAyahs;

  const TafsirDownloadResumable({
    required this.edition,
    required this.scope,
    required this.pendingAyahs,
    required this.completedAyahs,
    required this.totalAyahs,
  });

  int get completed => completedAyahs.length;
  int get remaining => pendingAyahs.length;
  double get percent => totalAyahs == 0 ? 0 : completed / totalAyahs * 100;

  @override
  List<Object?> get props => [edition, scope, pendingAyahs, completedAyahs, totalAyahs];
}

class TafsirDownloadInProgress extends TafsirDownloadState {
  final String edition;
  final String scope;
  final int completed;
  final int total;
  final String currentAyahRef;

  const TafsirDownloadInProgress({
    required this.edition,
    required this.scope,
    required this.completed,
    required this.total,
    required this.currentAyahRef,
  });

  double get percent => total == 0 ? 0 : completed / total * 100;

  @override
  List<Object?> get props => [edition, scope, completed, total, currentAyahRef];
}

class TafsirDownloadCancelling extends TafsirDownloadState {
  const TafsirDownloadCancelling();
}

class TafsirDownloadCompleted extends TafsirDownloadState {
  final String edition;
  final int totalAyahs;

  const TafsirDownloadCompleted({
    required this.edition,
    required this.totalAyahs,
  });

  @override
  List<Object?> get props => [edition, totalAyahs];
}

class TafsirDownloadFailed extends TafsirDownloadState {
  final String message;
  final String edition;
  final List<String> pendingAyahs;
  final List<String> completedAyahs;

  const TafsirDownloadFailed({
    required this.message,
    required this.edition,
    required this.pendingAyahs,
    required this.completedAyahs,
  });

  @override
  List<Object?> get props => [message, edition, pendingAyahs, completedAyahs];
}
