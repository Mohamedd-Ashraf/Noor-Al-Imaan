import "dart:io";

void main() {
  final file = File("lib/features/quran/presentation/screens/offline_tafsir_screen.dart");
  var content = file.readAsStringSync();
  content = content.replaceFirst("? 'المحمّل: \${stat.ayahCount} آية • \${_fmtBytes(stat.bytes)}'", "? 'المحمّل: \${stat.ayahCount} آية (\${((stat.ayahCount / 6236) * 100).toStringAsFixed(1)}%) • \${_fmtBytes(stat.bytes)}'");
  content = content.replaceFirst(": 'Downloaded: \${stat.ayahCount} ayahs • \${_fmtBytes(stat.bytes)}',", ": 'Downloaded: \${stat.ayahCount} ayahs (\${((stat.ayahCount / 6236) * 100).toStringAsFixed(1)}%) • \${_fmtBytes(stat.bytes)}',");
  file.writeAsStringSync(content);
}
