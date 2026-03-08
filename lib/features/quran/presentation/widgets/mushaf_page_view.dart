import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qcf_quran_lite/qcf_quran_lite.dart' hide Surah;

import '../../../../core/audio/ayah_audio_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../domain/entities/surah.dart';
import '../bloc/tafsir/tafsir_cubit.dart';
import '../screens/tafsir_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MushafPageView
// ─────────────────────────────────────────────────────────────────────────────

class MushafPageView extends StatefulWidget {
  final Surah surah;
  final int? initialPage;
  final bool isArabicUi;
  final int surahNumber;
  final int? initialAyahNumber;

  /// Called when the user taps the next-surah transition button.
  final VoidCallback? onNextSurah;

  /// Called when the user taps the previous-surah transition button.
  final VoidCallback? onPreviousSurah;

  const MushafPageView({
    super.key,
    required this.surah,
    this.initialPage,
    required this.isArabicUi,
    required this.surahNumber,
    this.initialAyahNumber,
    this.onNextSurah,
    this.onPreviousSurah,
  });

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _MushafPageViewState extends State<MushafPageView>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<List<HighlightVerse>> _highlightsNotifier =
      ValueNotifier([]);

  late PageController _pageController;
  late final BookmarkService _bookmarkService;

  late AnimationController _highlightAnimationController;

  // 1-based mushaf page currently visible – tracked via onPageChanged.
  int _currentPage = 1;

  // Navigation highlight (jumps to ayah) – separate from audio highlight.
  HighlightVerse? _navHighlight;

  // Audio highlight – updated by BlocListener whenever the cubit changes.
  HighlightVerse? _audioHighlight;

  // ── Init / dispose ─────────────────────────────────────────────────────────

  int _getStartPage() {
    if (widget.initialPage != null) return widget.initialPage!;
    try {
      return getPageNumber(
        widget.surahNumber,
        widget.initialAyahNumber ?? 1,
      );
    } catch (_) {
      return getPageNumber(widget.surahNumber, 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _bookmarkService = di.sl<BookmarkService>();

    _highlightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final startPage = _getStartPage();
    _currentPage = startPage;
    _pageController = PageController(initialPage: startPage - 1);

    if (widget.initialAyahNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _highlightAyah(widget.surahNumber, widget.initialAyahNumber!);
      });
    } else if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Highlight the first ayah on the target page.
        try {
          final ranges = getPageData(startPage);
          if (ranges.isNotEmpty) {
            final s = int.parse(ranges.first['surah'].toString());
            final v = int.parse(ranges.first['start'].toString());
            _highlightAyah(s, v);
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _highlightAnimationController.dispose();
    _pageController.dispose();
    _highlightsNotifier.dispose();
    super.dispose();
  }

  // ── Highlight helpers ──────────────────────────────────────────────────────

  void _updateHighlightsNotifier() {
    final list = <HighlightVerse>[];
    if (_audioHighlight != null) list.add(_audioHighlight!);
    if (_navHighlight != null) list.add(_navHighlight!);
    _highlightsNotifier.value = List.unmodifiable(list);
  }

  void _highlightAyah(int surah, int verse) {
    int page;
    try {
      page = getPageNumber(surah, verse);
    } catch (_) {
      return;
    }
    _navHighlight = HighlightVerse(
      surah: surah,
      verseNumber: verse,
      page: page,
      color: AppColors.secondary,
    );
    _updateHighlightsNotifier();
    _highlightAnimationController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _highlightAnimationController.reverse().then((_) {
          if (mounted) {
            _navHighlight = null;
            _updateHighlightsNotifier();
          }
        });
      }
    });
  }

  void _syncAudioHighlights(AyahAudioState state) {
    if (!state.hasTarget || state.status == AyahAudioStatus.idle) {
      if (_audioHighlight != null) {
        _audioHighlight = null;
        _updateHighlightsNotifier();
      }
      return;
    }
    int page;
    try {
      page = getPageNumber(state.surahNumber!, state.ayahNumber!);
    } catch (_) {
      return;
    }
    final color = state.status == AyahAudioStatus.playing
        ? AppColors.secondary
        : AppColors.primary;
    _audioHighlight = HighlightVerse(
      surah: state.surahNumber!,
      verseNumber: state.ayahNumber!,
      page: page,
      color: color,
    );
    _updateHighlightsNotifier();
  }

  // ── Long-press → Tafsir ────────────────────────────────────────────────────

  void _onLongPress(int surah, int verse, LongPressStartDetails _) {
    HapticFeedback.mediumImpact();
    String arabicText = '';
    try {
      arabicText = getVerse(surah, verse);
    } catch (_) {}
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<TafsirCubit>(),
          child: TafsirScreen(
            surahNumber: surah,
            ayahNumber: verse,
            surahName: SurahNames.getArabicName(surah),
            surahEnglishName: SurahNames.getEnglishName(surah),
            arabicAyahText: arabicText,
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    final isDark = settings.darkMode;
    final isAr = widget.isArabicUi;

    final bgColor =
        isDark ? const Color(0xFF0E1A12) : const Color(0xFFFFF9ED);
    final textColor =
        isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    return BlocListener<AyahAudioCubit, AyahAudioState>(
      listener: (_, state) => _syncAudioHighlights(state),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            isAr ? widget.surah.name : widget.surah.englishName,
            style: GoogleFonts.amiriQuran(
                fontSize: 20, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            // Word-by-word toggle (setting preserved but QCF renders full lines)
            BlocBuilder<AppSettingsCubit, AppSettingsState>(
              buildWhen: (p, n) => p.wordByWordAudio != n.wordByWordAudio,
              builder: (context, s) {
                final wbw = s.wordByWordAudio;
                return IconButton(
                  tooltip: wbw
                      ? (isAr
                          ? 'إيقاف التلاوة كلمة بكلمة'
                          : 'Disable word-by-word')
                      : (isAr
                          ? 'تفعيل التلاوة كلمة بكلمة'
                          : 'Enable word-by-word'),
                  icon: Icon(
                    wbw
                        ? Icons.record_voice_over_rounded
                        : Icons.voice_over_off_rounded,
                    color: wbw ? AppColors.secondary : Colors.white54,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context
                        .read<AppSettingsCubit>()
                        .setWordByWordAudio(!wbw);
                  },
                );
              },
            ),
            // Bookmark + Play for the current page
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPageBookmarkButton(_currentPage),
                _buildPagePlayButton(_currentPage),
              ],
            ),
          ],
        ),
        body: Container(
          color: bgColor,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: IslamicPatternPainter(color: AppColors.primary),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: BorderOrnamentPainter(color: AppColors.primary),
                ),
              ),
              QuranPageView(
                pageController: _pageController,
                scaffoldKey: _scaffoldKey,
                highlightsNotifier: _highlightsNotifier,
                onLongPress: _onLongPress,
                pageBackgroundColor: Colors.transparent,
                onPageChanged: (pageNum) {
                  if (mounted) setState(() => _currentPage = pageNum);
                },
                ayahStyle: TextStyle(
                  color: textColor,
                  fontSize: settings.arabicFontSize,
                ),
                topBar: _buildTopBar(isDark),
                bottomBar: _buildDecorativeFooter(_currentPage,
                    isDarkMode: isDark),
                surahHeaderBuilder: (ctx, surahNum) =>
                    _buildSurahHeader(surahNum, isDark),
                basmallahBuilder: (ctx, surahNum) => _buildBasmalah(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar action buttons ──────────────────────────────────────────────────

  Widget _buildPageBookmarkButton(int pageNumber) {
    final pageId = '${widget.surahNumber}:page:$pageNumber';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isBookmarked = _bookmarkService.isBookmarked(pageId);
        return IconButton(
          onPressed: () {
            final isArabicUi = widget.isArabicUi;
            if (isBookmarked) {
              _bookmarkService.removeBookmark(pageId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    isArabicUi ? 'تم حذف الإشارة' : 'Bookmark removed'),
                duration: const Duration(seconds: 1),
              ));
            } else {
              _bookmarkService.addBookmark(
                id: pageId,
                reference: pageId,
                arabicText: 'صفحة $pageNumber',
                surahName: widget.surah.name,
                surahNumber: widget.surahNumber,
                ayahNumber: null,
              );
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    isArabicUi ? 'تمت إضافة إشارة' : 'Bookmark added'),
                duration: const Duration(seconds: 1),
              ));
            }
            setLocalState(() {});
          },
          icon: Icon(
            _bookmarkService.isBookmarked(pageId)
                ? Icons.bookmark
                : Icons.bookmark_border,
            color: AppColors.secondary,
            size: 28,
          ),
          tooltip: widget.isArabicUi ? 'إشارة مرجعية' : 'Bookmark',
        );
      },
    );
  }

  Widget _buildPagePlayButton(int pageNumber) {
    return BlocBuilder<AyahAudioCubit, AyahAudioState>(
      builder: (context, audioState) {
        // Cast to List<dynamic> so firstWhere's orElse type-checks correctly.
        final List rawRanges;
        try {
          rawRanges = getPageData(pageNumber);
        } catch (_) {
          return const SizedBox.shrink();
        }
        if (rawRanges.isEmpty) return const SizedBox.shrink();

        // Prefer the current widget's surah if it's on this page; fall back
        // to the first range. Use a plain loop to avoid firstWhere orElse
        // type issues with the runtime-typed List returned by getPageData().
        Map<dynamic, dynamic>? matched;
        for (final r in rawRanges) {
          final m = r as Map<dynamic, dynamic>;
          if (int.tryParse(m['surah'].toString()) == widget.surahNumber) {
            matched = m;
            break;
          }
        }
        final range = matched ?? (rawRanges.first as Map<dynamic, dynamic>);
        final surahNum = int.parse(range['surah'].toString());
        final startAyah = int.parse(range['start'].toString());
        final endAyah = int.parse(range['end'].toString());

        final isPagePlaying =
            audioState.surahNumber == surahNum &&
            audioState.ayahNumber != null &&
            audioState.ayahNumber! >= startAyah &&
            audioState.ayahNumber! <= endAyah &&
            audioState.status == AyahAudioStatus.playing;

        return IconButton(
          onPressed: () {
            context.read<AyahAudioCubit>().playAyahRange(
                  surahNumber: surahNum,
                  startAyah: startAyah,
                  endAyah: endAyah,
                );
          },
          icon: Icon(
            isPagePlaying ? Icons.pause_circle : Icons.play_circle,
            color: isPagePlaying ? AppColors.secondary : Colors.white54,
            size: 28,
          ),
          tooltip: widget.isArabicUi ? 'تشغيل الصفحة' : 'Play page',
        );
      },
    );
  }

  // ── Decorative widgets ─────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOrnamentalLine(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.auto_awesome,
              size: 12,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          _buildOrnamentalLine(),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(int surahNumber, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Text(
        SurahNames.getArabicName(surahNumber),
        textAlign: TextAlign.center,
        style: GoogleFonts.amiriQuran(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.secondary : AppColors.primary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBasmalah() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _buildCornerOrnament()),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.rotate(
                angle: math.pi / 2, child: _buildCornerOrnament()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
                angle: -math.pi / 2, child: _buildCornerOrnament()),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
                angle: math.pi, child: _buildCornerOrnament()),
          ),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallOrnament(),
                    const SizedBox(width: 12),
                    Icon(Icons.auto_awesome,
                        size: 14,
                        color: AppColors.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 12),
                    _buildSmallOrnament(),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Text(
                    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiriQuran(
                      fontSize: 28,
                      height: 1.8,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallOrnament(),
                    const SizedBox(width: 12),
                    Icon(Icons.auto_awesome,
                        size: 14,
                        color: AppColors.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 12),
                    _buildSmallOrnament(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeFooter(int pageNumber, {required bool isDarkMode}) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSmallOrnament(),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/logo/files/transparent/label.png',
                height: 30,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.85)
                    : null,
              ),
              Text(
                _toArabicNumerals(pageNumber),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiriQuran(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : AppColors.primary,
                  height: 2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          _buildSmallOrnament(),
        ],
      ),
    );
  }

  // ── Ornament helpers ───────────────────────────────────────────────────────

  Widget _buildOrnamentalLine({double width = 60}) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallOrnament() {
    return Container(
      width: 30,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerOrnament() {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  left: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const arabicDigits = [
      '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'
    ];
    return number
        .toString()
        .split('')
        .map((d) => int.tryParse(d) != null ? arabicDigits[int.parse(d)] : d)
        .join();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BorderOrnamentPainter extends CustomPainter {
  final Color color;
  BorderOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);

    const cornerSize = 20.0;
    final corners = [
      Offset(10, 10),
      Offset(size.width - 10, 10),
      Offset(10, size.height - 10),
      Offset(size.width - 10, size.height - 10),
    ];
    for (final c in corners) {
      _drawCornerOrnament(canvas, c, cornerSize, paint);
    }
  }

  void _drawCornerOrnament(
      Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = center.dx + math.cos(angle) * size / 2;
      final y = center.dy + math.sin(angle) * size / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
