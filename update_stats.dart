import "dart:io";

void main() {
  final file = File("lib/features/quran/presentation/screens/offline_tafsir_screen.dart");
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "???????: \${stat.ayahCount} ??? • \${_fmtBytes(stat.bytes)}",
    "???????: \${stat.ayahCount} ??? (\${((stat.ayahCount / 6236) * 100).toStringAsFixed(1)}%) • \${_fmtBytes(stat.bytes)}"
  ).replaceAll(
    "Downloaded: \${stat.ayahCount} ayahs • \${_fmtBytes(stat.bytes)}",
    "Downloaded: \${stat.ayahCount} ayahs (\${((stat.ayahCount / 6236) * 100).toStringAsFixed(1)}%) • \${_fmtBytes(stat.bytes)}"
  );
  file.writeAsStringSync(content);
}
