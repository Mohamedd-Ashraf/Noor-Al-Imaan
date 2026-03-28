import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qcf_quran_lite/qcf_quran_lite.dart'
    show getPageData, getVerse, getVerseEndSymbol, getSurahNameArabic;

/// A fallback Quran page renderer used when the QCF tajweed font for a given
/// page has not yet been downloaded.  Renders the page text with the Amiri
/// Quran Google Font and Arabic verse-end symbols.
class QcfFallbackPage extends StatelessWidget {
  final int pageNumber;
  final bool isDarkMode;

  const QcfFallbackPage({
    super.key,
    required this.pageNumber,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDarkMode ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final bgColor =
        isDarkMode ? const Color(0xFF0E1A12) : const Color(0xFFFFF9ED);

    final List<dynamic> ranges;
    try {
      ranges = getPageData(pageNumber);
    } catch (_) {
      return Container(
        color: bgColor,
        child: Center(
          child: Text(
            'صفحة $pageNumber',
            style: GoogleFonts.amiriQuran(color: textColor, fontSize: 18),
          ),
        ),
      );
    }

    final List<Widget> blocks = [];
    int? lastSurah;

    for (final rangeRaw in ranges) {
      final range = rangeRaw as Map<dynamic, dynamic>;
      final surah = int.parse(range['surah'].toString());
      final start = int.parse(range['start'].toString());
      final end = int.parse(range['end'].toString());

      // Surah header
      if (surah != lastSurah) {
        lastSurah = surah;
        try {
          final surahName = getSurahNameArabic(surah);
          blocks.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: textColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'سورة $surahName',
                textAlign: TextAlign.center,
                style: GoogleFonts.amiriQuran(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          );
        } catch (_) {}
      }

      // Ayah text - concatenate all ayahs on this page range into a paragraph
      final StringBuffer pageText = StringBuffer();
      for (int ayah = start; ayah <= end; ayah++) {
        try {
          final text = getVerse(surah, ayah);
          final symbol = getVerseEndSymbol(ayah);
          pageText.write('$text$symbol ');
        } catch (_) {}
      }

      if (pageText.isNotEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              pageText.toString().trim(),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: GoogleFonts.amiriQuran(
                fontSize: 17,
                height: 1.9,
                color: textColor,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // "Fonts not downloaded" notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1B3A2B)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E7D32),
                width: 1,
              ),
            ),
            child: const Text(
              'عرض مبسّط — اضغط لتحميل خطوط المصحف كاملاً',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: blocks,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

