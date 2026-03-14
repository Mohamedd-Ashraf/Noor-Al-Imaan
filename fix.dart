import 'dart:io';

void main() {
  final file = File('lib/features/quran/presentation/screens/bookmarks_screen.dart');
  String text = file.readAsStringSync();
  text = text.replaceAll('''locale: const Locale('ar'),
                          locale: const Locale('ar'),''', "locale: const Locale('ar'),");
  text = text.replaceAll('''locale: const Locale('ar'),
        locale: const Locale('ar'),''', "locale: const Locale('ar'),");
  text = text.replaceAll('''locale: const Locale('ar'),\r\n                          locale: const Locale('ar'),''', "locale: const Locale('ar'),");
  text = text.replaceAll('''locale: const Locale('ar'),\r\n        locale: const Locale('ar'),''', "locale: const Locale('ar'),");
  file.writeAsStringSync(text);
}
