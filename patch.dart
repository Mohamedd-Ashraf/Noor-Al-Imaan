import '''dart:io''';
void main() {
  final f = File('''lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart''');
  var txt = f.readAsStringSync();
  final old = '''Future<void> startAllEditionsFull() async {
    for (final e in ApiConstants.tafsirEditions) {
      if (_cancelRequested) break;
      await startFull(e['id']!);
    }
  }'''.replaceAll('\r\n', '\n');
  txt = txt.replaceAll('\r\n', '\n');
  print(txt.contains(old));
}
