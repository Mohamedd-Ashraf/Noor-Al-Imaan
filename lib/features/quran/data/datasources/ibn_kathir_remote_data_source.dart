import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

/// Fetches تفسير ابن كثير from the Quran.com API v4.
///
/// Endpoint:
///   GET https://api.quran.com/api/v4/tafsirs/14/by_ayah/{surah}:{ayah}
///   (ID 14 → "Tafsir Ibn Kathir" Arabic, slug: ar-tafsir-ibn-kathir)
///
/// Response shape:
///   { "tafsir": { "id": 14, "text": "<p>…</p>", "ayah_key": "1:1", … } }
///
/// The returned text contains HTML markup which is stripped before returning
/// clean Arabic text to the UI — consistent with other tafsir sources
/// displayed on the Tafsir screen (alquran.cloud editions).
class IbnKathirRemoteDataSource {
  final http.Client client;

  const IbnKathirRemoteDataSource({required this.client});

  /// Returns the Ibn Kathir tafsir Arabic text for [surahNumber]:[ayahNumber].
  /// Throws [ServerException] on network or parse failures.
  Future<String> getTafsir(int surahNumber, int ayahNumber) async {
    final uri = Uri.parse(
      '${ApiConstants.quranComBaseUrl}/tafsirs'
      '/${ApiConstants.ibnKathirTafsirId}'
      '/by_ayah/$surahNumber:$ayahNumber',
    );

    try {
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'QuranApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final htmlText =
            (decoded['tafsir']?['text'] as String?) ?? '';
        return _stripHtml(htmlText);
      } else {
        throw ServerException();
      }
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Strips HTML tags/entities from the quran.com tafsir response and
  /// produces clean Arabic paragraphs consistent with the Tafsir screen.
  ///
  /// Steps:
  ///   1. Remove <sup …>…</sup> blocks entirely (footnote reference numbers).
  ///   2. Replace block-closing tags with paragraph breaks.
  ///   3. Replace <br> with a single newline.
  ///   4. Strip all remaining HTML tags.
  ///   5. Decode named + numeric HTML entities.
  ///   6. Collapse excess whitespace and blank lines.
  String _stripHtml(String html) {
    return html
        // 1. Remove footnote superscripts entirely
        .replaceAll(
            RegExp(r'<sup[^>]*>.*?</sup>', caseSensitive: false, dotAll: true),
            '')
        // 2. Block-level closing tags → paragraph break
        .replaceAll(
            RegExp(r'</(p|h[1-6]|div|blockquote)>', caseSensitive: false),
            '\n\n')
        // 3. Line-break elements → single newline
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        // 4. Strip all remaining HTML tags
        .replaceAll(RegExp(r'<[^>]+>'), '')
        // 5. HTML entities
        .replaceAll('&nbsp;',  '\u00a0')
        .replaceAll('&amp;',   '&')
        .replaceAll('&lt;',    '<')
        .replaceAll('&gt;',    '>')
        .replaceAll('&quot;',  '"')
        .replaceAll('&#39;',   "'")
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'),
            (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
        .replaceAllMapped(RegExp(r'&#([0-9]+);'),
            (m) => String.fromCharCode(int.parse(m.group(1)!)))
        // 6. Normalise whitespace
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'^ ', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
