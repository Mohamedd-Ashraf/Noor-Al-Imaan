import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

import '../../../../core/utils/tajweed_parser.dart';

class AppQcfPage extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final double? fontSize;
  final double sp;
  final double h;
  final void Function(int surahNumber, int verseNumber, TapDownDetails details)?
      onTapDown;
  final void Function(int surahNumber, int verseNumber)? onTap;
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;

  /// Raw tajweed-annotated texts from alquran.cloud, keyed by "surah:verse".
  /// When provided, each verse is rendered using [UthmanicHafs] font with
  /// per-letter tajweed colouring instead of the normal QCF glyph colouring.
  final Map<String, String>? tajweedTexts;

  /// Whether the app is in dark mode (affects tajweed colour palette).
  final bool isDark;

  const AppQcfPage({
    super.key,
    required this.pageNumber,
    this.theme = const QcfThemeData(),
    this.fontSize,
    this.sp = 1.0,
    this.h = 1.0,
    this.onTapDown,
    this.onTap,
    this.verseBackgroundColor,
    this.tajweedTexts,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (pageNumber < 1 || pageNumber > 604) {
      return Center(child: Text('Invalid page number: $pageNumber'));
    }

    // Tajweed overlay uses UthmanicHafs Unicode font + per-letter colours.
    // It is a completely separate rendering path from the QCF glyph pipeline.
    if (tajweedTexts != null) return _buildTajweedPage(context);

    final ranges = getPageData(pageNumber);
    final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
    final baseFontSize = (fontSize ?? getFontSize(pageNumber, context)) * sp;
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenSize.height;

        final List<Widget> blocks = [];
        final List<InlineSpan> currentSpans = [];

        void flushTextBlock() {
          if (currentSpans.isEmpty) return;
          final spans = List<InlineSpan>.of(currentSpans);
          currentSpans.clear();
          blocks.add(
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.zero,
                child: Text.rich(
                  TextSpan(children: spans),
                  locale: const Locale('ar'),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: pageFont,
                    package: 'qcf_quran',
                    fontSize: isPortrait
                        ? baseFontSize
                        : (pageNumber == 1 || pageNumber == 2)
                            ? 20 * sp
                            : baseFontSize - (17 * sp),
                    color: theme.verseTextColor,
                    height: isPortrait
                        ? (pageNumber == 1 || pageNumber == 2)
                            ? 2.2 * h
                            : theme.verseHeight * h
                        : (pageNumber == 1 || pageNumber == 2)
                            ? 4 * h
                            : 4 * h,
                    letterSpacing: theme.letterSpacing,
                    wordSpacing: theme.wordSpacing,
                  ),
                ),
              ),
            ),
          );
        }

        if (pageNumber == 1 || pageNumber == 2) {
          blocks.add(SizedBox(height: screenSize.height * .175));
        }

        for (final r in ranges) {
          final surah = int.parse(r['surah'].toString());
          final start = int.parse(r['start'].toString());
          final end = int.parse(r['end'].toString());

          if (start == 1) {
            flushTextBlock();

            if (theme.showHeader) {
              currentSpans.add(
                WidgetSpan(child: HeaderWidget(suraNumber: surah, theme: theme)),
              );
              currentSpans.add(const TextSpan(text: '\n'));
            }
            if (theme.showBasmala && pageNumber != 1 && pageNumber != 187) {
              if (theme.basmalaBuilder != null) {
                currentSpans.add(
                  WidgetSpan(child: theme.basmalaBuilder!(surah)),
                );
              } else {
                final bool largeScreen =
                    MediaQuery.of(context).size.width >= 600;
                currentSpans.add(
                  TextSpan(
                    text: ' ﱁ  ﱂﱃﱄ',
                    style: TextStyle(
                      fontFamily: 'QCF_P001',
                      package: 'qcf_quran',
                      fontSize: (largeScreen
                              ? theme.basmalaFontSizeLarge
                              : theme.basmalaFontSizeSmall) *
                          sp,
                      color: theme.basmalaColor,
                    ),
                  ),
                );
              }
              currentSpans.add(const TextSpan(text: '\n'));
            }
          }

          for (int v = start; v <= end; v++) {
            GestureRecognizer? recognizer;
            if (onTap != null) {
              final tapRecognizer = TapGestureRecognizer();
              tapRecognizer.onTap = () => onTap?.call(surah, v);
              tapRecognizer.onTapDown =
                  (details) => onTapDown?.call(surah, v, details);
              recognizer = tapRecognizer;
            }

            final verseBgColor =
                theme.verseBackgroundColor?.call(surah, v) ??
                    verseBackgroundColor?.call(surah, v);

            final rawQcf = getVerseQCF(surah, v, verseEndSymbol: true);
            final startsWithNewline = rawQcf.startsWith('\n');
            if (startsWithNewline && currentSpans.isNotEmpty) {
              currentSpans.add(const TextSpan(text: '\n'));
            }

            final stripped = startsWithNewline ? rawQcf.substring(1) : rawQcf;
            final trailingNewline = stripped.endsWith('\n');
            final noTrail = trailingNewline
                ? stripped.substring(0, stripped.length - 1)
                : stripped;
            final glyph = noTrail.isEmpty ? '' : noTrail[noTrail.length - 1];
            final verseText = noTrail.isEmpty ? '' : noTrail.substring(0, noTrail.length - 1);

            final InlineSpan verseNumberSpan = theme.verseNumberBuilder != null
                ? theme.verseNumberBuilder!(surah, v, glyph)
                : TextSpan(
                    text: glyph,
                    style: TextStyle(
                      fontFamily: pageFont,
                      package: 'qcf_quran',
                      color: theme.verseNumberColor,
                      height: theme.verseNumberHeight * h,
                      backgroundColor:
                          theme.verseNumberBackgroundColor ?? verseBgColor,
                    ),
                  );

            final verseKey = '$surah:$v';
            final tajweedRaw = tajweedTexts?[verseKey];
            final useTajweed = tajweedRaw != null &&
                tajweedRaw.isNotEmpty &&
                hasTajweedMarkers(tajweedRaw);

            if (useTajweed) {
              // Per-letter tajweed: render with UthmanicHafs font so each
              // Arabic Unicode character can carry its own colour.
              final hafsStyle = TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: baseFontSize,
                height: isPortrait
                    ? (pageNumber == 1 || pageNumber == 2)
                        ? 2.2 * h
                        : theme.verseHeight * h
                    : 4 * h,
                color: theme.verseTextColor,
              );
              final tajweedSpans = buildTajweedSpans(
                text: '$tajweedRaw ',
                baseStyle: verseBgColor != null
                    ? hafsStyle.copyWith(backgroundColor: verseBgColor)
                    : hafsStyle,
                isDark: isDark,
              );
              currentSpans.add(
                TextSpan(
                  recognizer: recognizer,
                  children: [
                    ...tajweedSpans,
                    verseNumberSpan,
                    if (trailingNewline) const TextSpan(text: '\n'),
                  ],
                ),
              );
            } else {
              // Normal QCF glyph rendering (no tajweed data loaded yet).
              currentSpans.add(
                TextSpan(
                  text: verseText,
                  recognizer: recognizer,
                  style: verseBgColor != null
                      ? TextStyle(backgroundColor: verseBgColor)
                      : null,
                  children: [
                    verseNumberSpan,
                    if (trailingNewline) const TextSpan(text: '\n'),
                  ],
                ),
              );
            }
          }
        }

        flushTextBlock();

        return Scrollbar(
          child: SingleChildScrollView(
            child: SizedBox(
              height: availableHeight,
              width: availableWidth,
              child: ListView(
                shrinkWrap: true,
                children: blocks,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Tajweed page (UthmanicHafs, per-letter colours) ──────────────────────

  /// Renders the page using [UthmanicHafs] font with per-letter tajweed colours.
  /// Completely independent of the QCF glyph pipeline — natural word-wrap,
  /// Unicode Arabic text, no QCF-style explicit line-breaks.
  Widget _buildTajweedPage(BuildContext context) {
    final ranges = getPageData(pageNumber);

    // QCF baseFontSize is calibrated for large PUA glyphs.
    // UthmanicHafs is a normal Uthmanic Arabic font — derive size from screen
    // width so it fills the line similarly to the reference image.
    final screenW = MediaQuery.of(context).size.width;
    // Reference image shows ~9 words per line with clear readable size.
    // screenW/15 gives ~26sp on a 390px phone which matches the reference well.
    final double fs = ((screenW / 15.0) * sp).clamp(20.0, 38.0);
    final hafsBase = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: fs,
      height: 1.75,   // matches reference line-spacing (was 2.1 – too loose)
      color: theme.verseTextColor,
    );

    final spans = <InlineSpan>[];

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end   = int.parse(r['end'].toString());

      // ── Surah boundary: header + basmala ──
      if (start == 1) {
        if (theme.showHeader) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: HeaderWidget(suraNumber: surah, theme: theme),
          ));
          spans.add(const TextSpan(text: '\n'));
        }
        if (theme.showBasmala && pageNumber != 1 && pageNumber != 187) {
          spans.add(TextSpan(
            text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
            style: hafsBase.copyWith(
              color: theme.basmalaColor,
              fontSize: fs * 0.9,
            ),
          ));
          spans.add(const TextSpan(text: '\n'));
        }
      }

      for (int v = start; v <= end; v++) {
        GestureRecognizer? recognizer;
        if (onTap != null) {
          final tapRec = TapGestureRecognizer()
            ..onTap = () { onTap?.call(surah, v); }
            ..onTapDown = (d) { onTapDown?.call(surah, v, d); };
          recognizer = tapRec;
        }

        final verseBgColor = theme.verseBackgroundColor?.call(surah, v) ??
            verseBackgroundColor?.call(surah, v);
        final verseStyle = verseBgColor != null
            ? hafsBase.copyWith(backgroundColor: verseBgColor)
            : hafsBase;

        final tajweedRaw = tajweedTexts!['$surah:$v'];
        if (tajweedRaw != null && tajweedRaw.isNotEmpty) {
          spans.add(TextSpan(
            recognizer: recognizer,
            children: buildTajweedSpans(
              text: tajweedRaw,
              baseStyle: verseStyle,
              isDark: isDark,
            ),
          ));
        }

        // Inline verse-end marker  ۝٣٦
        spans.add(TextSpan(
          text: ' \u06DD${_toHafsArabicNum(v)} ',
          style: hafsBase.copyWith(
            color: theme.verseNumberColor,
            fontSize: fs * 0.8,
          ),
        ));
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width * 0.055).clamp(14.0, 28.0),
        vertical: 10,
      ),
      child: Text.rich(
        TextSpan(children: spans),
        locale: const Locale('ar'),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        softWrap: true,
        textScaler: TextScaler.noScaling,
      ),
    );
  }

  /// Converts an integer to Arabic-Indic digits for Quranic verse markers.
  static String _toHafsArabicNum(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}