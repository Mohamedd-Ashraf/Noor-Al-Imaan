import '''dart:io''';

void main() {
  final file = File('''lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart''');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
'''  Future<void> startAllEditionsFull() async {
    for (final e in ApiConstants.tafsirEditions) {
      if (_cancelRequested) break;
      await startFull(e['id']!);
    }
  }''',
'''  Future<void> startAllEditionsFull() async {
    int fullCount = 0;
    for (final e in ApiConstants.tafsirEditions) {
      final id = e['id']!;
      final stats = await _localTafsir.getEditionStats(id);
      if (stats.ayahCount >= 6236) {
        fullCount += stats.ayahCount;
        continue;
      }
      if (_cancelRequested) break;
      await startFull(id, isPartOfAll: true);
      fullCount += 6236;
    }
    if (!_cancelRequested && !isClosed) {
      emit(TafsirDownloadCompleted(edition: 'all', totalAyahs: fullCount));
    }
  }'''
);
  print(content.contains("final stats = await _localTafsir.getEditionStats(id);"));
  file.writeAsStringSync(content);
}
