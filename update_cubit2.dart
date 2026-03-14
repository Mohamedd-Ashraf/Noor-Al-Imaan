import "dart:io";

void main() {
  final file = File("lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart");
  var content = file.readAsStringSync();
  
  content = content.replaceFirst("final parallelSurahRequests = 4;", "final parallelSurahRequests = 2; // Reduced to avoid API rate limits");
  content = content.replaceFirst("final maxSurahAttempts = 3;", "final maxSurahAttempts = 5;");
  content = content.replaceFirst("Duration(milliseconds: 260 * attempt)", "Duration(milliseconds: 1000 * attempt)");
  content = content.replaceFirst("if (fetchedThisRound == 0 && roundsCount >= 6)", "if (fetchedThisRound == 0 && roundsCount >= 10)");
  
  file.writeAsStringSync(content);
}
