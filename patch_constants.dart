import "dart:io";

void main() {
  final file = File("lib/core/constants/api_constants.dart");
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    "tafsirMuyassar: 8.0,",
    "tafsirMuyassar: 3.0,"
  ).replaceFirst(
    "tafsirIbnKathir: 60.0,",
    "tafsirIbnKathir: 15.0,"
  ).replaceFirst(
    "tafsirJalalayn: 12.0,",
    "tafsirJalalayn: 2.0,"
  ).replaceFirst(
    "tafsirQurtubi: 95.0,",
    "tafsirQurtubi: 30.0,"
  );
  file.writeAsStringSync(content);
  print("Sizes patched");
}
