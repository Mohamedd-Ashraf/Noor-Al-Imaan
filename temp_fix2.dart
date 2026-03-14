import "dart:io";

void main() {
  final file = File("lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart");
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    "bool isResume = false,\n  }) async {",
    "bool isResume = false,\n    bool isPartOfAll = false,\n  }) async {"
  );
  file.writeAsStringSync(content);
}
