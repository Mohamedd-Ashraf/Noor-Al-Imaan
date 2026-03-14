import '''dart:io''';
void main() {
  final file = File('''lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart''');
  var text = file.readAsStringSync();
  text = text.replaceFirst(
'''  Future<void> _startDownload({
    required String edition,
    required List<String> refs,
    required String scope,
    List<String>? existingCompleted,
    int? existingTotal,
    bool isResume = false,
  }) async {''',
'''  Future<void> _startDownload({
    required String edition,
    required List<String> refs,
    required String scope,
    List<String>? existingCompleted,
    int? existingTotal,
    bool isResume = false,
    bool isPartOfAll = false,
  }) async {''');
  file.writeAsStringSync(text);
}
