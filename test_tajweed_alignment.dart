// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

// Direct import from pub cache (bypasses Flutter)
import 'package:qcf_quran/src/data/quran_text.dart';

final RegExp _tajweedTagRegex = RegExp(
  r'\[([a-z](?::\d+)?)\[([^\]]*)\]',
  unicode: true,
);

/// Quick diagnostic: compare word counts between the tajweed API
/// and the QCF glyph strings for pages 50 and 107.
Future<void> main() async {
  final client = HttpClient();

  for (final page in [50, 107]) {
    print('===================================================');
    print('PAGE $page');
    print('===================================================');

    // 1. Fetch tajweed API data
    final req = await client.getUrl(
      Uri.parse('https://api.alquran.cloud/v1/page/$page/quran-tajweed'),
    );
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      print('  API error: ${res.statusCode}');
      continue;
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final ayahs = data['ayahs'] as List;

    print('  Ayah count from API: ${ayahs.length}');
    print('');

    // 2. For each ayah, compare
    for (final a in ayahs) {
      final surah = (a['surah'] as Map<String, dynamic>)['number'] as int;
      final verse = a['numberInSurah'] as int;
      final tajweedText = a['text'] as String;

      // Count tajweed words (split by space)
      final tajweedWords = tajweedText.split(' ');
      final tajweedWordCount = tajweedWords.length;

      // Check which word indices have tags (simulating extractWordColors)
      final taggedIndices = <int>[];
      for (int i = 0; i < tajweedWords.length; i++) {
        if (_tajweedTagRegex.hasMatch(tajweedWords[i])) {
          taggedIndices.add(i);
        }
      }
      final hasColorAtIndex0 = taggedIndices.contains(0);

      // Get QCF data from embedded data
      String rawQcf = '';
      for (final item in quranText) {
        if (item['surah_number'] == surah && item['verse_number'] == verse) {
          rawQcf = item['qcfData'].toString();
          break;
        }
      }

      final startsWithNewline = rawQcf.startsWith('\n');
      final stripped = startsWithNewline ? rawQcf.substring(1) : rawQcf;
      final trailingNewline = stripped.endsWith('\n');
      final noTrail = trailingNewline
          ? stripped.substring(0, stripped.length - 1)
          : stripped;
      final verseText =
          noTrail.isEmpty ? '' : noTrail.substring(0, noTrail.length - 1);

      // Count QCF words (split by space -- same as buildQcfTajweedSpans)
      final qcfWords = verseText.split(' ');
      final qcfWordCount = qcfWords.length;
      final qcfCharCount = verseText.runes.length;

      print('  Surah $surah:$verse');
      print('    Tajweed words: $tajweedWordCount | QCF words(split): $qcfWordCount | QCF glyphs: $qcfCharCount');
      print('    Tagged word indices: $taggedIndices (${taggedIndices.length}/${tajweedWordCount})');
      print('    Has color at index 0: $hasColorAtIndex0');
      print('    QCF has spaces: ${verseText.contains(' ')}');
      if (tajweedWordCount != qcfWordCount) {
        print('    >>> WORD COUNT MISMATCH: tajweed=$tajweedWordCount vs qcf=$qcfWordCount');
      }
      print('');
    }
  }

  client.close();
}
