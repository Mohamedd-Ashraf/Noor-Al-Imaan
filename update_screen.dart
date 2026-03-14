import "dart:io";

void main() {
  final file = File("lib/features/quran/presentation/screens/offline_tafsir_screen.dart");
  var content = file.readAsStringSync();
  
  final regex = RegExp(r"FilledButton\.icon\(\s*onPressed:\s*\(\!isRunning\s*&&\s*canStart\)\s*\?\s*\(\)\s*=>\s*_showStartDialog\(context,\s*cubit,\s*id\)\s*:\s*null,\s*icon:\s*const\s*Icon\(Icons\.download_rounded\),\s*label:\s*Text\(_isAr\s*\?\s*'.*?'\s*:\s*'Download'\),\s*\),");
  
  if (regex.hasMatch(content)) {
    content = content.replaceFirst(regex, '''
FilledButton.icon(
                                  onPressed: (!isRunning && canStart)
                                      ? () => cubit.startFull(id)
                                      : null,
                                  icon: const Icon(Icons.download_done_rounded),
                                  label: Text(_isAr ? '????? ????' : 'Full Download'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: (!isRunning && canStart)
                                      ? () =>
                                            _showStartDialog(context, cubit, id)
                                      : null,
                                  icon: const Icon(Icons.tune_rounded),
                                  label: Text(_isAr ? '????' : 'Custom'),
                                ),
''');
    file.writeAsStringSync(content);
    print("Replaced successfully.");
  } else {
    print("Did not match");
  }
}
