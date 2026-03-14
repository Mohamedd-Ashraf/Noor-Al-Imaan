import "dart:io";

void main() {
  final file = File("lib/features/quran/presentation/bloc/tafsir/tafsir_download_cubit.dart");
  var content = file.readAsStringSync();
  content = content.replaceFirst(
'''
          final result = await _getSurah(
            GetSurahParams(surahNumber: surah, edition: edition),
          );
          if (result.isLeft()) {
            return const <_FetchedAyah>[];
          }
''',
'''
          final result = await _getSurah(
            GetSurahParams(surahNumber: surah, edition: edition),
          );
          if (result.isLeft()) {
            throw Exception('Server returned Failure');
          }
'''
  );
  file.writeAsStringSync(content);
}
