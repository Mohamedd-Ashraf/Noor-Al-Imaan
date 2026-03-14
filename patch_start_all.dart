import '''dart:io''';
void main() {
  final file = File('''lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart''');
  var text = file.readAsStringSync();
  text = text.replaceFirst(
'''  Future<void> startAllEditionsFull() async {
    for (final e in ApiConstants.tafsirEditions) {
      if (_cancelRequested) break;
      await startFull(e['id']!);
    }
  }''',
'''  Future<void> startAllEditionsFull() async {
    int totalSavedAll = 0;
    for (final e in ApiConstants.tafsirEditions) {
      if (_cancelRequested) break;
      final editionId = e['id']!;
      final stats = await _localTafsir.getEditionStats(editionId);
      if (stats.ayahCount >= 6236) {
        totalSavedAll += 6236;
        continue;
      }
      await startFull(editionId, isPartOfAll: true);
      totalSavedAll += 6236;
    }
    if (!_cancelRequested && !isClosed) {
      emit(TafsirDownloadCompleted(edition: 'all', totalAyahs: totalSavedAll));
    }
  }''');
  file.writeAsStringSync(text);
  print("Patched startAll!");
}
