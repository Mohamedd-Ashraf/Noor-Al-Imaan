import '''dart:io''';
void main() {
  final f = File('''lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart''');
  var txt = f.readAsStringSync().replaceAll('\r\n', '\n');
  final target = '''  Future<void> startAllEditionsFull() async {
    for (final e in ApiConstants.tafsirEditions) {
      if (_cancelRequested) break;
      await startFull(e['id']!);
    }
  }''';
  final repl = '''  Future<void> startAllEditionsFull() async {
    int totalSavedAll = 0;
    for (final e in ApiConstants.tafsirEditions) {
      if (_cancelRequested) break;
      final editionId = e['id']!;
      
      // Before starting the download, let's verify if all 6236 are fully cached and skipped
      final stats = await _localTafsir.getEditionStats(editionId);
      if (stats.ayahCount >= 6236) {
        totalSavedAll += 6236;
        continue; // Fully downloaded, seamlessly jump to the next
      }
      
      await startFull(editionId, isPartOfAll: true);
      totalSavedAll += 6236;
    }
    
    // Once all are checked/downloaded properly, emit the real completed state 
    if (!_cancelRequested && !isClosed) {
      emit(TafsirDownloadCompleted(edition: 'all', totalAyahs: totalSavedAll));
    }
  }''';
  
  if (txt.contains(target)) {
    txt = txt.replaceFirst(target, repl);
    f.writeAsStringSync(txt);
    print("Patched!");
  } else {
    print("Target not found!");
  }
}
