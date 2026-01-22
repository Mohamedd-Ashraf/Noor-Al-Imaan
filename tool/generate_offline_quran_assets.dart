import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Generates offline Quran assets:
/// - assets/offline/surah_list.json (114 surahs without ayahs)
/// - assets/offline/surah_N.json (surah with ayahs)
///
/// Run:
///   dart run tool/generate_offline_quran_assets.dart
Future<void> main() async {
  final outDir = Directory('assets/offline');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final uri = Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani');
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    stderr.writeln('Failed to download Quran: ${res.statusCode}');
    exitCode = 1;
    return;
  }

  final decoded = json.decode(res.body) as Map<String, dynamic>;
  final data = decoded['data'] as Map<String, dynamic>;
  final surahs = (data['surahs'] as List).cast<Map<String, dynamic>>();

  // Ensure required fields exist for our models.
  for (final s in surahs) {
    final ayahs = (s['ayahs'] as List?) ?? const [];
    s['numberOfAyahs'] ??= ayahs.length;
  }

  // Write per-surah files (full)
  for (final s in surahs) {
    final number = s['number'];
    final file = File('assets/offline/surah_$number.json');
    await file.writeAsString(json.encode(s));
  }

  // Write list file (no ayahs)
  final list = surahs
      .map((s) {
        final copy = Map<String, dynamic>.from(s);
        copy.remove('ayahs');
        return copy;
      })
      .toList(growable: false);

  await File('assets/offline/surah_list.json').writeAsString(json.encode(list));

  stdout.writeln('Generated: assets/offline/surah_list.json and ${surahs.length} surah files');
}
