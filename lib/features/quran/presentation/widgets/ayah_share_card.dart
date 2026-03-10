import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showAyahShareDialog({
  required BuildContext context,
  required int surahNumber,
  required int initialVerse,
  required String surahName,
}) async {
  int totalAyahs;
  try {
    totalAyahs = getVerseCount(surahNumber);
  } catch (_) {
    totalAyahs = initialVerse;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AyahRangeShareDialog(
      surahNumber: surahNumber,
      surahName: surahName,
      startVerse: initialVerse,
      maxVerse: totalAyahs,
      rootContext: context,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Range-picker dialog  (redesigned)
// ─────────────────────────────────────────────────────────────────────────────

class _AyahRangeShareDialog extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int startVerse;
  final int maxVerse;
  final BuildContext rootContext;

  const _AyahRangeShareDialog({
    required this.surahNumber,
    required this.surahName,
    required this.startVerse,
    required this.maxVerse,
    required this.rootContext,
  });

  @override
  State<_AyahRangeShareDialog> createState() => _AyahRangeShareDialogState();
}

class _AyahRangeShareDialogState extends State<_AyahRangeShareDialog> {
  static const int _maxRange = 10;
  late int _endVerse;

  @override
  void initState() {
    super.initState();
    _endVerse = widget.startVerse;
  }

  int get _upperBound =>
      (widget.startVerse + _maxRange - 1).clamp(widget.startVerse, widget.maxVerse);

  bool get _canAddMore => _endVerse < _upperBound;
  bool get _canRemove  => _endVerse > widget.startVerse;
  bool get _hasSlider  => _upperBound > widget.startVerse;
  int  get _count      => _endVerse - widget.startVerse + 1;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Green gradient header ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064428), Color(0xFF0D5E3A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.share_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'مشاركة آيات قرآنية',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded,
                          color: Color(0xFFD4AF37), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'من سورة ${widget.surahName}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Verse range chips
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _VerseChip(label: 'من آية', verse: widget.startVerse),
                        Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.primary.withValues(alpha: 0.4),
                            size: 14),
                        _VerseChip(label: 'إلى آية', verse: _endVerse),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // +/- counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundIconBtn(
                        icon: Icons.remove_rounded,
                        enabled: _canRemove,
                        onTap: () => setState(() => _endVerse--),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '$_count',
                            style: GoogleFonts.cairo(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            _count == 1 ? 'آية' : 'آيات',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      _RoundIconBtn(
                        icon: Icons.add_rounded,
                        enabled: _canAddMore,
                        onTap: () => setState(() => _endVerse++),
                      ),
                    ],
                  ),

                  // Slider
                  if (_hasSlider) ...[
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        thumbColor: AppColors.primary,
                        overlayColor:
                            AppColors.primary.withValues(alpha: 0.10),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _endVerse.toDouble(),
                        min: widget.startVerse.toDouble(),
                        max: _upperBound.toDouble(),
                        divisions: (_upperBound - widget.startVerse)
                            .clamp(1, _maxRange),
                        onChanged: (v) =>
                            setState(() => _endVerse = v.round()),
                      ),
                    ),
                  ],

                  if (!_canAddMore &&
                      _endVerse == _upperBound &&
                      _upperBound < widget.maxVerse)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'الحد الأقصى للمشاركة $_maxRange آيات',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 11, color: Colors.orange[700]),
                      ),
                    ),
                ],
              ),
            ),

            // ── Actions ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('إلغاء',
                          style: GoogleFonts.cairo(color: Colors.grey[700])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text('مشاركة كصورة',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final end      = _endVerse;
                        final rootCtx  = widget.rootContext;
                        final surahNum = widget.surahNumber;
                        final surahNm  = widget.surahName;
                        final start    = widget.startVerse;
                        Navigator.of(context).pop();
                        _captureAndShare(rootCtx, surahNum, start, end, surahNm);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets for the dialog
// ─────────────────────────────────────────────────────────────────────────────

class _VerseChip extends StatelessWidget {
  final String label;
  final int verse;
  const _VerseChip({required this.label, required this.verse});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            '$verse',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _RoundIconBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.grey[100],
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.grey[300]!,
          ),
        ),
        child: Icon(icon,
            size: 22,
            color: enabled ? AppColors.primary : Colors.grey[400]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Capture the share card as PNG and invoke the system share sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _captureAndShare(
  BuildContext context,
  int surahNumber,
  int startVerse,
  int endVerse,
  String surahName,
) async {
  OverlayEntry? cardEntry;
  OverlayEntry? loaderEntry;
  try {
    // ── Loading indicator ────────────────────────────────────────────────────
    loaderEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.25),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 3),
                const SizedBox(height: 14),
                Text('جاري تجهيز الصورة…',
                    style: GoogleFonts.cairo(fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
    if (context.mounted) Overlay.of(context).insert(loaderEntry);

    // ── Off-screen card ──────────────────────────────────────────────────────
    final captureKey = GlobalKey();
    cardEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: -6000,
        top: 0,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
            child: SizedBox(
              width: 400,
              child: RepaintBoundary(
                key: captureKey,
                child: AyahShareCard(
                  surahNumber: surahNumber,
                  surahName: surahName,
                  startVerse: startVerse,
                  endVerse: endVerse,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    Overlay.of(context).insert(cardEntry);

    // Two frames: layout → paint
    await Future.delayed(const Duration(milliseconds: 350));

    final renderObj = captureKey.currentContext?.findRenderObject();
    if (renderObj is! RenderRepaintBoundary) {
      throw Exception('Capture failed – widget not painted');
    }

    final image    = await renderObj.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('PNG encoding failed');

    final bytes   = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final fileName = startVerse == endVerse
        ? 'quran_${surahNumber}_$startVerse.png'
        : 'quran_${surahNumber}_${startVerse}_$endVerse.png';
    final filePath = '${tempDir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes, flush: true);

    final subject = startVerse == endVerse
        ? '$surahName ﴿$startVerse﴾'
        : '$surahName ﴿$startVerse – $endVerse﴾';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'image/png')],
        subject: subject,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر إنشاء الصورة، حاول مجدداً'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } finally {
    cardEntry?.remove();
    loaderEntry?.remove();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AyahShareCard — Mushaf-style visual card captured as PNG
// ─────────────────────────────────────────────────────────────────────────────

class AyahShareCard extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final int startVerse;
  final int endVerse;

  static const _bgColor       = Color(0xFFFFF9ED); // cream, same as Mushaf light
  static const _textColor     = Color(0xFF1A1A1A); // dark text
  static const _gold          = Color(0xFFD4AF37);
  static const _surahNameColor = Color(0xFF3D2000); // dark brown

  const AyahShareCard({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.startVerse,
    required this.endVerse,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        color: _bgColor,
        child: Stack(
          children: [
            // ── Islamic geometric background pattern ──────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _ShareIslamicPatternPainter(color: AppColors.primary),
              ),
            ),
            // ── Manuscript-style border ornaments ────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _ShareBorderOrnamentPainter(color: AppColors.primary),
              ),
            ),
            // ── Content column ────────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thin gold top rule
                Container(height: 3, color: _gold),

                // Space before surah header ("a bit lower")
                const SizedBox(height: 22),

                // Surah ornamental banner (header)
                _SurahHeader(surahNumber: surahNumber),

                const SizedBox(height: 14),

                // Ornamental separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _OrnamentRow(color: _gold),
                ),

                const SizedBox(height: 18),

                // Verse content – continuous QCF rendering
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _VerseContent(
                    surahNumber: surahNumber,
                    startVerse: startVerse,
                    endVerse: endVerse,
                  ),
                ),

                const SizedBox(height: 18),

                // Ornamental separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _OrnamentRow(color: _gold),
                ),

                const SizedBox(height: 10),

                // Minimal reference: surah name + verse range (no panel)
                _Reference(
                  surahName: surahName,
                  startVerse: startVerse,
                  endVerse: endVerse,
                ),

                const SizedBox(height: 14),

                // Thin gold bottom rule
                Container(height: 3, color: _gold),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Surah ornamental header (light-mode, same look as MushafPageView)
// ─────────────────────────────────────────────────────────────────────────────

class _SurahHeader extends StatelessWidget {
  final int surahNumber;
  const _SurahHeader({required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    const double headerWidth = 320.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ornamental frame – light mode (no color tint)
        Image.asset(
          'assets/mainframe.png',
          package: 'qcf_quran',
          width: headerWidth,
          fit: BoxFit.contain,
        ),
        // Surah name in QCF surahname font
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'surah${surahNumber.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontFamily: SurahFontHelper.fontFamily, // 'surahname'
              package: 'qcf_quran',
              fontSize: headerWidth * 0.075,
              color: AyahShareCard._surahNameColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verse content: grouped by page, rendered continuously like the Mushaf
// ─────────────────────────────────────────────────────────────────────────────

class _VerseContent extends StatelessWidget {
  final int surahNumber;
  final int startVerse;
  final int endVerse;

  const _VerseContent({
    required this.surahNumber,
    required this.startVerse,
    required this.endVerse,
  });

  @override
  Widget build(BuildContext context) {
    // ── Basmala (verse 1 of a surah except Al-Fatiha and At-Tawbah) ─────────
    // In the Mushaf, Basmala appears before verse 1 using QCF_P001 glyphs.
    Widget? basmala;
    if (startVerse == 1 && surahNumber != 1 && surahNumber != 9) {
      basmala = Text(
        ' \uFC41  \uFC42\uFC43\uFC44', // Basmala glyphs in QCF_P001
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'QCF_P001',
          package: 'qcf_quran',
          fontSize: 22,
          color: AyahShareCard._textColor,
          height: 2.0,
        ),
      );
    }

    // ── Group consecutive verses by their Mushaf page ─────────────────────
    // Verses on the same page share one font (QCF_Pxxx) and should be
    // rendered in a single Text block for natural, continuous flow.
    final Map<int, List<int>> pageGroups  = {};
    final List<int>            pageOrder  = [];

    for (int v = startVerse; v <= endVerse; v++) {
      int page;
      try {
        page = getPageNumber(surahNumber, v);
      } catch (_) {
        continue;
      }
      if (!pageGroups.containsKey(page)) {
        pageGroups[page] = [];
        pageOrder.add(page);
      }
      pageGroups[page]!.add(v);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (basmala != null) ...[
          basmala,
          const SizedBox(height: 4),
        ],
        for (final page in pageOrder)
          _PageVerseBlock(
            surahNumber: surahNumber,
            page: page,
            verses: pageGroups[page]!,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One block of verses that share the same QCF page font
// ─────────────────────────────────────────────────────────────────────────────

class _PageVerseBlock extends StatelessWidget {
  final int surahNumber;
  final int page;
  final List<int> verses;

  const _PageVerseBlock({
    required this.surahNumber,
    required this.page,
    required this.verses,
  });

  @override
  Widget build(BuildContext context) {
    final pageFont = 'QCF_P${page.toString().padLeft(3, '0')}';

    // Concatenate all QCF glyph strings for this page's verses into one
    // continuous string.  Mushaf \n line-position markers are replaced by
    // spaces so Flutter wraps the text naturally in the card width.
    final buffer = StringBuffer();
    for (final v in verses) {
      try {
        String qcf = getVerseQCF(surahNumber, v, verseEndSymbol: true);
        // Strip leading Mushaf line-break (previous verse forced a new line)
        if (qcf.startsWith('\n')) qcf = qcf.substring(1);
        // Strip trailing line-break (keep final character = verse-end glyph)
        if (qcf.endsWith('\n')) qcf = qcf.substring(0, qcf.length - 1);
        // Replace mid-verse breaks with spaces for natural card wrapping
        qcf = qcf.replaceAll('\n', ' ').trim();
        if (qcf.isEmpty) continue;
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(qcf);
      } catch (_) {}
    }

    if (buffer.isEmpty) return const SizedBox.shrink();

    return Text(
      buffer.toString(),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      softWrap: true,
      style: TextStyle(
        fontFamily: pageFont,
        package: 'qcf_quran',
        fontSize: 22,
        color: AyahShareCard._textColor,
        height: 2.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal bottom reference (no dark panel — just small text)
// ─────────────────────────────────────────────────────────────────────────────

class _Reference extends StatelessWidget {
  final String surahName;
  final int startVerse;
  final int endVerse;

  const _Reference({
    required this.surahName,
    required this.startVerse,
    required this.endVerse,
  });

  @override
  Widget build(BuildContext context) {
    final verseRef = startVerse == endVerse
        ? '﴿ $startVerse ﴾'
        : '﴿ $startVerse – $endVerse ﴾';

    return Column(
      children: [
        Text(
          surahName,
          textAlign: TextAlign.center,
          style: GoogleFonts.scheherazadeNew(
            fontSize: 20,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          verseRef,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AyahShareCard._gold,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold ornamental row separator
// ─────────────────────────────────────────────────────────────────────────────

class _OrnamentRow extends StatelessWidget {
  final Color color;
  const _OrnamentRow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                color.withValues(alpha: 0.65),
              ]),
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: 0.65),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local copies of the background painters (mirrors mushaf_page_view.dart)
// — kept separate to avoid a circular import between the two widget files.
// ─────────────────────────────────────────────────────────────────────────────

class _ShareIslamicPatternPainter extends CustomPainter {
  final Color color;
  _ShareIslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const patternSize = 40.0;
    for (double x = 0; x < size.width; x += patternSize) {
      for (double y = 0; y < size.height; y += patternSize) {
        final path = Path()
          ..moveTo(x + patternSize / 2, y)
          ..lineTo(x + patternSize, y + patternSize / 2)
          ..lineTo(x + patternSize / 2, y + patternSize)
          ..lineTo(x, y + patternSize / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(
          Offset(x + patternSize / 2, y + patternSize / 2),
          patternSize / 4,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _ShareBorderOrnamentPainter extends CustomPainter {
  final Color color;
  _ShareBorderOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor  = color.withValues(alpha: 0.28);
    final outerPaint   = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final innerPaint   = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final fillPaint    = Paint()
      ..color = strokeColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    const margin      = 9.0;
    const innerMargin = 14.0;

    // Top and bottom ornamental rules
    canvas.drawLine(Offset(margin, margin),
        Offset(size.width - margin, margin), outerPaint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(size.width - margin, size.height - margin), outerPaint);
    canvas.drawLine(Offset(innerMargin, innerMargin),
        Offset(size.width - innerMargin, innerMargin), innerPaint);
    canvas.drawLine(Offset(innerMargin, size.height - innerMargin),
        Offset(size.width - innerMargin, size.height - innerMargin),
        innerPaint);

    // Corner medallions
    for (final c in [
      Offset(margin, margin),
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
    ]) {
      _drawMedallion(canvas, c, 13.0, outerPaint, innerPaint, fillPaint);
    }
  }

  void _drawMedallion(Canvas canvas, Offset center, double r, Paint outer,
      Paint inner, Paint fill) {
    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, outer);
    canvas.drawCircle(center, r * 0.55, inner);
    final starPath = Path();
    const n = 8;
    for (int i = 0; i < n; i++) {
      final outerAngle = i * math.pi * 2 / n - math.pi / 2;
      final innerAngle = outerAngle + math.pi / n;
      final ox = center.dx + math.cos(outerAngle) * r * 0.85;
      final oy = center.dy + math.sin(outerAngle) * r * 0.85;
      final ix = center.dx + math.cos(innerAngle) * r * 0.42;
      final iy = center.dy + math.sin(innerAngle) * r * 0.42;
      if (i == 0) { starPath.moveTo(ox, oy); } else { starPath.lineTo(ox, oy); }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, inner);
    canvas.drawCircle(center, r * 0.18, outer);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
