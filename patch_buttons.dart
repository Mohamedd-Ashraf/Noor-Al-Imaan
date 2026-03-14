import '''dart:io''';

void main() {
  final file = File('''lib/features/quran/presentation/screens/offline_tafsir_screen.dart''');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "final canStart = !isRunning || runningEdition == id;",
    "final bool isComplete = stat.ayahCount >= 6236;\n                    final canStart = (!isRunning || runningEdition == id) && !isComplete;"
  );

  final targetStr = "FilledButton.icon(\n                                  onPressed: (!isRunning && canStart)\n                                      ? () =>\n                                            _showStartDialog(context, cubit, id)\n                                      : null,\n                                  icon: const Icon(Icons.download_rounded),\n                                  label: Text(_isAr ? '?????' : 'Download'),\n                                ),";
  content = content.replaceAll(targetStr, "if (!isComplete)\n                                  $targetStr");

  file.writeAsStringSync(content);
}
