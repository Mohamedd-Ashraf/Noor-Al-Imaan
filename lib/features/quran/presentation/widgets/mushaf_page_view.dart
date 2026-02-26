import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../../domain/entities/surah.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/audio/ayah_audio_cubit.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/arabic_text_style_helper.dart';
import '../../../../core/constants/surah_names.dart';
import '../bloc/tafsir/tafsir_cubit.dart';
import '../screens/tafsir_screen.dart';


// custom physics with lowered fling threshold to make swipes easier
class _EasySwipePagePhysics extends PageScrollPhysics {
  const _EasySwipePagePhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _EasySwipePagePhysics applyTo(ScrollPhysics? ancestor) {
    return _EasySwipePagePhysics(parent: buildParent(ancestor));
  }

  // reduce required velocity to trigger page change
  @override
  double get minFlingVelocity => 50.0;
}

class MushafPageView extends StatefulWidget {

  final Surah surah;
  final int? initialPage;
  final bool isArabicUi;
  final int surahNumber;
  final int? initialAyahNumber;
  /// Called when the user taps the button on the next-surah transition page.
  final VoidCallback? onNextSurah;
  /// Called when the user taps the button on the previous-surah transition page.
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

class _MushafPageViewState extends State<MushafPageView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late List<MushafPage> _pages;
  late final BookmarkService _bookmarkService;
  int? _highlightedAyahNumber;
  bool _isAnimating = false;
  final Map<int, GlobalKey> _richTextKeys = {};
  final Map<int, List<({int start, int end, int ayahNumber, String ayahFullText})>>
      _pageAyahOffsets = {};
  late AnimationController _highlightAnimationController;
  late Animation<double> _highlightAnimation;
  final Map<int, ScrollController> _pageScrollControllers = {};

  /// 1 when a previous-surah virtual page is prepended, 0 otherwise.
  /// All PageController indices must be shifted by this offset.
  int get _pageOffset =>
      (widget.surahNumber > 1 && widget.onPreviousSurah != null) ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _bookmarkService = di.sl<BookmarkService>();
    _pages = _groupAyahsByPage();

    // Initialize highlight animation
    _highlightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightAnimationController,
      curve: Curves.easeInOut,
    );

    // Always start from first page when we have a target
    final hasTarget =
        widget.initialAyahNumber != null || widget.initialPage != null;
    final initialPage =
        (hasTarget ? 0 : _getInitialPageIndex()) + _pageOffset;
    _pageController = PageController(initialPage: initialPage);

    // Animate to target ayah if specified
    if (widget.initialAyahNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToAyah(widget.initialAyahNumber!);
      });
    } else if (widget.initialPage != null) {
      // Page bookmark: animate to page and highlight first ayah
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToPage(widget.initialPage!);
      });
    }
  }

  @override
  void dispose() {
    _highlightAnimationController.dispose();
    _pageController.dispose();
    // Dispose all page scroll controllers
    for (final controller in _pageScrollControllers.values) {
      controller.dispose();
    }
    _pageScrollControllers.clear();
    super.dispose();
  }

  List<MushafPage> _groupAyahsByPage() {
    if (widget.surah.ayahs == null || widget.surah.ayahs!.isEmpty) {
      return [];
    }

    final Map<int, List<Ayah>> pageGroups = {};
    for (final ayah in widget.surah.ayahs!) {
      pageGroups.putIfAbsent(ayah.page, () => []).add(ayah);
    }

    return pageGroups.entries
        .map((entry) => MushafPage(pageNumber: entry.key, ayahs: entry.value))
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  int _getInitialPageIndex() {
    if (widget.initialPage == null || _pages.isEmpty) return 0;

    final index = _pages.indexWhere((p) => p.pageNumber == widget.initialPage);
    return index >= 0 ? index : 0;
  }

  Future<void> _animateToAyah(int ayahNumber) async {
    if (_isAnimating || _pages.isEmpty) return;

    // Find the page index containing this ayah
    final targetPageIndex = _pages.indexWhere(
      (page) => page.ayahs.any((ayah) => ayah.numberInSurah == ayahNumber),
    );

    if (targetPageIndex == -1) return;

    setState(() {
      _isAnimating = true;
    });

    // Jump straight to the page without any animation
    // (add _pageOffset because the controller includes the virtual prev-surah page)
    _pageController.jumpToPage(targetPageIndex + _pageOffset);

    // Highlight the ayah immediately (no scrolling animation)
    setState(() {
      _highlightedAyahNumber = ayahNumber;
      _isAnimating = false;
    });

    // Scroll to ayah within the page if it's in the lower half
    _scrollToAyahInPage(ayahNumber, targetPageIndex);

    // Start highlight animation
    _highlightAnimationController.forward(from: 0.0);

    // Remove highlight after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _highlightAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _highlightedAyahNumber = null;
            });
          }
        });
      }
    });
  }

  Future<void> _animateToPage(int pageNumber) async {
    if (_isAnimating || _pages.isEmpty) return;

    // Find the page index
    final targetPageIndex = _pages.indexWhere(
      (page) => page.pageNumber == pageNumber,
    );

    if (targetPageIndex == -1) return;

    // Get first ayah in this page for highlighting
    final firstAyahInPage = _pages[targetPageIndex].ayahs.isNotEmpty
        ? _pages[targetPageIndex].ayahs.first.numberInSurah
        : null;

    setState(() {
      _isAnimating = true;
    });

    // Jump straight to the page without animation
    _pageController.jumpToPage(targetPageIndex + _pageOffset);

    // Highlight the first ayah immediately
    if (firstAyahInPage != null) {
      setState(() {
        _highlightedAyahNumber = firstAyahInPage;
        _isAnimating = false;
      });

      // Start highlight animation
      _highlightAnimationController.forward(from: 0.0);

      // Remove highlight after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _highlightAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _highlightedAyahNumber = null;
              });
            }
          });
        }
      });
    } else {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _scrollToAyahInPage(int ayahNumber, int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;

    final page = _pages[pageIndex];
    final ayahIndex = page.ayahs.indexWhere(
      (ayah) => ayah.numberInSurah == ayahNumber,
    );

    if (ayahIndex == -1) return;

    // Get scroll controller for this page
    final scrollController = _getScrollController(page.pageNumber);

    // Retry scroll with multiple attempts to ensure scroll controller is ready
    void attemptScroll(int retryCount) {
      if (!mounted || retryCount > 5) return;

      if (!scrollController.hasClients) {
        // Retry after a delay
        Future.delayed(const Duration(milliseconds: 300), () {
          attemptScroll(retryCount + 1);
        });
        return;
      }

      final totalAyahs = page.ayahs.length;
      final ayahPosition = ayahIndex / totalAyahs;

      // If ayah is in the lower half of the page, scroll down
      if (ayahPosition > 0.35) {
        // Wait a bit more to ensure content is laid out
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted || !scrollController.hasClients) return;

          final maxExtent = scrollController.position.maxScrollExtent;
          if (maxExtent <= 0) return; // No scrolling needed

          // Scroll proportionally based on ayah position
          // Position 0.5 -> scroll to 30% of page
          // Position 1.0 -> scroll to 80% of page
          final targetScroll = maxExtent * ((ayahPosition - 0.35) / 0.65) * 0.8;

          scrollController.animateTo(
            targetScroll.clamp(0.0, maxExtent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        });
      }
    }

    // Start scroll attempts after page animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      attemptScroll(0);
    });
  }

  ScrollController _getScrollController(int pageNumber) {
    return _pageScrollControllers.putIfAbsent(
      pageNumber,
      () => ScrollController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return Center(
        child: Text(widget.isArabicUi ? 'لا توجد صفحات' : 'No pages available'),
      );
    }

    final hasNextSurah =
        widget.surahNumber < 114 && widget.onNextSurah != null;
    final hasPreviousSurah = _pageOffset == 1;
    final totalPages = _pageOffset + _pages.length + (hasNextSurah ? 1 : 0);
    final isRtlFlip = context.watch<AppSettingsCubit>().state.pageFlipRightToLeft;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: _pageController,
        itemCount: totalPages,
        reverse: isRtlFlip,
        clipBehavior: Clip.none,
        dragStartBehavior: DragStartBehavior.down,
        // Navigation happens only via button tap on the transition page.
        physics: _isAnimating
            ? const NeverScrollableScrollPhysics()
            : const _EasySwipePagePhysics(),
        itemBuilder: (context, index) {
          if (hasPreviousSurah && index == 0) {
            return _buildPreviousSurahPage(context);
          }
          final realIndex = index - _pageOffset;
          if (realIndex == _pages.length) {
            return _buildNextSurahPage(context);
          }
          return _buildMushafPage(_pages[realIndex]);
        },
      ),
    );
  }

  Widget _buildSurahTransitionPage({
    required BuildContext context,
    required int targetSurahNumber,
    required String directionLabel,
    required String buttonLabel,
    required String backHint,
    required VoidCallback? onConfirm,
    required bool isNext,
  }) {
    final isDark = context.watch<AppSettingsCubit>().state.darkMode;
    final arabicName = SurahNames.getArabicName(targetSurahNumber);
    final englishName = SurahNames.getEnglishName(targetSurahNumber);

    // Match the Mushaf page background colours
    final bgColors = isDark
        ? [const Color(0xFF0E1A12), const Color(0xFF131F16), const Color(0xFF0E1A12)]
        : [const Color(0xFFFFF9ED), const Color(0xFFFFF4D8), const Color(0xFFFFF0C8)];
    final cardColor = isDark ? const Color(0xFF1C2E24) : Colors.white;
    final borderColor = isDark
        ? AppColors.secondary.withValues(alpha: 0.45)
        : AppColors.secondary.withValues(alpha: 0.5);
    final textSecondary =
        isDark ? Colors.white54 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Same subtle Islamic pattern as regular pages
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
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Direction label chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Text(
                        directionLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark ? AppColors.secondary : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Ornamental divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ornamentLine(isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.star,
                              size: 10,
                              color: AppColors.secondary
                                  .withValues(alpha: 0.7)),
                        ),
                        _ornamentLine(isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Surah name card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: isDark ? 0.15 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            arabicName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiriQuran(
                              fontSize: 32,
                              color: isDark
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          if (!widget.isArabicUi) ...[  
                            const SizedBox(height: 6),
                            Text(
                              englishName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            widget.isArabicUi
                                ? 'السورة $targetSurahNumber'
                                : 'Surah $targetSurahNumber',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Navigate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          shadowColor:
                              AppColors.primary.withValues(alpha: 0.4),
                        ),
                        onPressed: onConfirm,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Next: ‹ [text] — arrow on left
                              if (isNext) ...[
                                const Icon(Icons.chevron_left_rounded, size: 22),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                buttonLabel,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              // Previous: [text] › — arrow on right
                              if (!isNext) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 22),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      backHint,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ornamentLine(bool isDark) {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.secondary.withValues(alpha: isDark ? 0.6 : 0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextSurahPage(BuildContext context) {
    final nextNumber = widget.surahNumber + 1;
    return _buildSurahTransitionPage(
      context: context,
      targetSurahNumber: nextNumber,
      directionLabel:
          widget.isArabicUi ? 'السورة التالية' : 'Next Surah',
      buttonLabel: widget.isArabicUi
          ? 'انتقل إلى السورة التالية'
          : 'Go to Next Surah',
      backHint: widget.isArabicUi
          ? 'اسحب للخلف للعودة'
          : 'Swipe back to return',
      isNext: true,
      onConfirm: widget.onNextSurah,
    );
  }

  Widget _buildPreviousSurahPage(BuildContext context) {
    final prevNumber = widget.surahNumber - 1;
    return _buildSurahTransitionPage(
      context: context,
      targetSurahNumber: prevNumber,
      directionLabel:
          widget.isArabicUi ? 'السورة السابقة' : 'Previous Surah',
      buttonLabel: widget.isArabicUi
          ? 'انتقل إلى السورة السابقة'
          : 'Go to Previous Surah',
      backHint: widget.isArabicUi
          ? 'اسحب للأمام للعودة'
          : 'Swipe forward to return',
      isNext: false,
      onConfirm: widget.onPreviousSurah,
    );
  }

  Widget _buildMushafPage(MushafPage page) {
    final isFirstAyahOfSurah =
        page.ayahs.isNotEmpty && page.ayahs.first.numberInSurah == 1;
    final needsBasmalah =
        isFirstAyahOfSurah &&
        widget.surah.number != 1 &&
        widget.surah.number != 9;

    // Get theme colors for light/dark mode support
    final isDarkMode = context.watch<AppSettingsCubit>().state.darkMode;

    final backgroundGradientColors = isDarkMode
        ? [
            const Color(0xFF0E1A12), // Deep warm dark (ink-on-night)
            const Color(0xFF131F16),
            const Color(0xFF0E1A12),
          ]
        : [
            const Color(0xFFFFF9ED), // Warm ivory parchment
            const Color(0xFFFFF4D8), // Classic vellum
            const Color(0xFFFFF0C8), // Aged amber
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: backgroundGradientColors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Islamic pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(color: AppColors.primary),
            ),
          ),
          // Border ornaments
          Positioned.fill(
            child: CustomPaint(
              painter: BorderOrnamentPainter(color: AppColors.primary),
            ),
          ),
          // Main content with CustomScrollView
          CustomScrollView(
            controller: _getScrollController(page.pageNumber),
            slivers: [
              // Collapsible decorative header
              SliverAppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: 50,
                expandedHeight: 100,
                collapsedHeight: 50,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildDecorativeHeader(),
                  collapseMode: CollapseMode.parallax,
                ),
                actions: [
                  _buildPageBookmarkButton(page),
                  _buildPagePlayButton(page),
                ],
              ),
              // Content area
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (needsBasmalah) ...[
                      _buildBasmalah(),
                      const SizedBox(height: 28),
                    ],
                    _buildContinuousText(page.ayahs, page.pageNumber),
                  ]),
                ),
              ),
              // Footer
              SliverToBoxAdapter(
                child: _buildDecorativeFooter(page.pageNumber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scale based on available height
        final maxHeight = 100.0;
        final minHeight = 50.0;
        final currentHeight = constraints.maxHeight;

        // Scale factor: 1.0 when expanded, ~0.5 when collapsed
        final scale = currentHeight.clamp(minHeight, maxHeight) / maxHeight;
        final isCollapsed = scale < 0.7;

        return ClipRect(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8 * scale),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08 * scale),
                  AppColors.primary.withValues(alpha: 0.02 * scale),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top ornamental line
                if (!isCollapsed)
                  Row(
                    children: [
                      Expanded(child: _buildOrnamentalLine()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildCenterOrnament(),
                      ),
                      Expanded(child: _buildOrnamentalLine()),
                    ],
                  ),
                if (!isCollapsed) SizedBox(height: 8 * scale),
                // Islamic star pattern
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIslamicStar(size: 12 * scale),
                    SizedBox(width: 16 * scale),
                    _buildIslamicStar(size: 16 * scale),
                    SizedBox(width: 16 * scale),
                    _buildIslamicStar(size: 12 * scale),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasmalah() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(width: 2, color: Colors.transparent),
      ),
      child: Stack(
        children: [
          // Corner ornaments
          Positioned(top: 0, left: 0, child: _buildCornerOrnament()),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.rotate(
              angle: math.pi / 2,
              child: _buildCornerOrnament(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: _buildCornerOrnament(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: math.pi,
              child: _buildCornerOrnament(),
            ),
          ),
          // Basmalah text
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallOrnament(),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    _buildSmallOrnament(),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                      fontSize: 30,
                      height: 1.8,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallOrnament(),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
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

  Widget _buildDecorativeFooter(int pageNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
              ),
              Text(
                _toArabicNumerals(pageNumber),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiriQuran(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
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

  Widget _buildContinuousText(List<Ayah> ayahs, int pageNumber) {
    if (ayahs.isEmpty) return const SizedBox();

    // Precompute ayah display texts (basmala removal is static)
    // and build character-offset map so long-press can identify the ayah.
    final precomputedTexts = <int, String>{}; // ayahNumber → display text
    for (final ayah in ayahs) {
      String text = ayah.text;
      if (ayah.numberInSurah == 1 &&
          widget.surahNumber != 1 &&
          widget.surahNumber != 9) {
        final words = text.split(' ');
        if (words.length >= 5 && words[0] == 'بِسْمِ') {
          text = words.sublist(4).join(' ').trim();
        }
      }
      precomputedTexts[ayah.numberInSurah] = text;
    }

    // Build (start, end, ayahNumber, ayahFullText) offset list.
    // Each ayah occupies: displayText.length chars + 1 WidgetSpan + 1 space.
    int cumOffset = 0;
    final offsetMap =
        <({int start, int end, int ayahNumber, String ayahFullText})>[];
    for (final ayah in ayahs) {
      final displayText = precomputedTexts[ayah.numberInSurah]!;
      final start = cumOffset;
      cumOffset += displayText.length + 2; // +1 WidgetSpan, +1 space
      offsetMap.add((
        start: start,
        end: cumOffset,
        ayahNumber: ayah.numberInSurah,
        ayahFullText: ayah.text,
      ));
    }
    _pageAyahOffsets[pageNumber] = offsetMap;

    // Get or create a stable GlobalKey for this page's RichText.
    final richTextKey =
        _richTextKeys.putIfAbsent(pageNumber, () => GlobalKey());

    // First BlocBuilder: Listen to AppSettingsCubit for settings changes
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settingsState) {
        // Get all settings from state
        final arabicFontSize = settingsState.arabicFontSize;
        final isDarkMode = settingsState.darkMode;
        final diacriticsColorMode = settingsState.diacriticsColorMode;
        final quranFont = settingsState.quranFont;

        // Debug: Print current settings
        print('🎨 BlocBuilder rebuilt!');
        print('   diacriticsColorMode: $diacriticsColorMode');
        print('   isDarkMode: $isDarkMode');

        // Calculate colors based on settings
        final useDifferentDiacriticsColor = diacriticsColorMode != 'same';
        final baseTextColor = isDarkMode
            ? const Color(0xFFE8E8E8) // Light gray for dark mode
            : AppColors.arabicText;

        // Define diacritics color based on mode
        Color? diacriticsColor;
        if (diacriticsColorMode == 'subtle') {
          // Slightly lighter/transparent
          diacriticsColor = isDarkMode
              ? baseTextColor.withValues(alpha: 0.5)
              : baseTextColor.withValues(alpha: 0.4);
          print('   ✅ Using SUBTLE mode: $diacriticsColor');
        } else if (diacriticsColorMode == 'different') {
          // Clearly different color - using golden/orange for visibility
          diacriticsColor = isDarkMode
              ? const Color(0xFFFFB74D) // Light orange for dark mode
              : const Color(0xFFFF6F00); // Dark orange for light mode
          print('   ✅ Using DIFFERENT mode: $diacriticsColor');
        } else {
          print('   ✅ Using SAME mode (no diacritics color)');
        }

        // Second BlocBuilder: Listen to AyahAudioCubit for audio state
        return BlocBuilder<AyahAudioCubit, AyahAudioState>(
          builder: (context, audioState) {
            return AnimatedBuilder(
              animation: _highlightAnimation,
              builder: (context, child) {
                final textSpans = <InlineSpan>[];

                for (int i = 0; i < ayahs.length; i++) {
                  final ayah = ayahs[i];
                  final isCurrentAudio = audioState.isCurrent(
                    widget.surahNumber,
                    ayah.numberInSurah,
                  );
                  final isPlaying =
                      isCurrentAudio &&
                      audioState.status == AyahAudioStatus.playing;

                  // Check if this ayah should be highlighted
                  final isHighlighted =
                      _highlightedAyahNumber == ayah.numberInSurah;

                  // Remove Basmala from first ayah if needed
                  String ayahText = ayah.text;

                  if (ayah.numberInSurah == 1 &&
                      widget.surahNumber != 1 &&
                      widget.surahNumber != 9) {
                    // Split by spaces and remove first 4 words (Basmala)
                    final words = ayahText.split(' ');
                    if (words.length >= 5 && words[0] == 'بِسْمِ') {
                      ayahText = words.sublist(4).join(' ').trim();
                    }
                  }

                  // Base text style
                  final baseTextStyle = ArabicTextStyleHelper.quranFontStyle(
                    fontKey: quranFont,
                    fontSize: arabicFontSize,
                    height: 2.0,
                    color: baseTextColor,
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ).copyWith(
                    letterSpacing: isHighlighted ? 0.3 : 0.2,
                    backgroundColor: isHighlighted
                        ? (isDarkMode
                              ? AppColors.secondary.withValues(
                                  alpha:
                                      0.4 + (0.3 * _highlightAnimation.value),
                                )
                              : AppColors.secondary.withValues(
                                  alpha:
                                      0.25 + (0.2 * _highlightAnimation.value),
                                ))
                        : (isCurrentAudio
                              ? (isPlaying
                                    ? AppColors.secondary.withValues(
                                        alpha:
                                            0.25 +
                                            (0.15 *
                                                (_highlightAnimation.value *
                                                    0.5)),
                                      )
                                    : AppColors.primary.withValues(alpha: 0.2))
                              : null),
                    shadows: isHighlighted || (isCurrentAudio && isPlaying)
                        ? [
                            Shadow(
                              color:
                                  (isHighlighted
                                          ? AppColors.secondary
                                          : AppColors.secondary)
                                      .withValues(
                                        alpha:
                                            0.5 *
                                            (isHighlighted
                                                ? _highlightAnimation.value
                                                : 0.6),
                                      ),
                              blurRadius:
                                  (isHighlighted ? 12 : 8) *
                                  (isHighlighted
                                      ? _highlightAnimation.value
                                      : 1.0),
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    decoration: isHighlighted ? TextDecoration.underline : null,
                    decorationColor: isHighlighted
                        ? AppColors.secondary.withValues(
                            alpha: 0.4 + (0.3 * _highlightAnimation.value),
                          )
                        : null,
                    decorationThickness: 2.5,
                    decorationStyle: TextDecorationStyle.solid,
                  );

                  // Build the text span with optional different color for diacritics
                  // and include tap gesture recognizer
                  final textSpan = ArabicTextStyleHelper.buildTextSpan(
                    text: ayahText,
                    baseStyle: baseTextStyle,
                    useDifferentColorForDiacritics: useDifferentDiacriticsColor,
                    diacriticsColor: diacriticsColor,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.read<AyahAudioCubit>().togglePlayAyah(
                          surahNumber: widget.surahNumber,
                          ayahNumber: ayah.numberInSurah,
                        );
                      },
                  );

                  // Add ayah text
                  textSpans.add(textSpan);

                  // Add ayah number marker after the ayah text
                  textSpans.add(
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildAyahNumberMarker(ayah.numberInSurah),
                      ),
                    ),
                  );

                  // Add space after ayah number
                  textSpans.add(const TextSpan(text: ' '));
                }

                return GestureDetector(
                  onLongPressStart: (LongPressStartDetails details) {
                    final ro =
                        richTextKey.currentContext?.findRenderObject();
                    if (ro is! RenderParagraph) return;
                    final textPosition =
                        ro.getPositionForOffset(details.localPosition);
                    final offset = textPosition.offset;
                    final pageOffsets = _pageAyahOffsets[pageNumber];
                    if (pageOffsets == null) return;
                    int? targetAyahNumber;
                    String? targetAyahFullText;
                    for (final entry in pageOffsets) {
                      if (offset >= entry.start && offset < entry.end) {
                        targetAyahNumber = entry.ayahNumber;
                        targetAyahFullText = entry.ayahFullText;
                        break;
                      }
                    }
                    // Fallback to first ayah on page if position not found.
                    if (targetAyahNumber == null && pageOffsets.isNotEmpty) {
                      targetAyahNumber = pageOffsets.first.ayahNumber;
                      targetAyahFullText = pageOffsets.first.ayahFullText;
                    }
                    if (targetAyahNumber != null &&
                        targetAyahFullText != null &&
                        context.mounted) {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => di.sl<TafsirCubit>(),
                            child: TafsirScreen(
                              surahNumber: widget.surahNumber,
                              ayahNumber: targetAyahNumber!,
                              surahName: widget.surah.name,
                              surahEnglishName: widget.surah.englishName,
                              arabicAyahText: targetAyahFullText!,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: RichText(
                    key: richTextKey,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    text: TextSpan(children: textSpans),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAyahNumberMarker(int number) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settingsState) {
        final isDarkMode = settingsState.darkMode;
        final textColor = isDarkMode ? AppColors.secondary : AppColors.primary;

        // Scale everything proportionally with the arabic font size (base = 18)
        final scale = settingsState.arabicFontSize / 18.0;
        final frameSize = 30.0 * scale;

        // Smaller font so number fits inside the octagonal frame, scaled
        final baseFontSize = number > 99 ? 8.0 : (number > 9 ? 10.0 : 12.0);
        final fontSize = baseFontSize * scale;

        // Bottom padding to vertically center text inside the frame, scaled
        final bottomPadding = 10.0 * scale;

        return Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/logo/files/transparent/frame.png',
              width: frameSize,
              height: frameSize,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
              child: Text(
                _toArabicNumerals(number),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiriQuran(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagePlayButton(MushafPage page) {
    return BlocBuilder<AyahAudioCubit, AyahAudioState>(
      builder: (context, audioState) {
        // Check if any ayah in this page is currently playing
        final isPagePlaying = page.ayahs.any(
          (ayah) =>
              audioState.isCurrent(widget.surahNumber, ayah.numberInSurah) &&
              audioState.status == AyahAudioStatus.playing,
        );

        return IconButton(
          onPressed: () {
            // Play all ayahs in the page
            if (page.ayahs.isNotEmpty) {
              final firstAyah = page.ayahs.first.numberInSurah;
              final lastAyah = page.ayahs.last.numberInSurah;
              context.read<AyahAudioCubit>().playAyahRange(
                surahNumber: widget.surahNumber,
                startAyah: firstAyah,
                endAyah: lastAyah,
              );
            }
          },
          icon: Icon(
            isPagePlaying ? Icons.pause_circle : Icons.play_circle,
            color: AppColors.primary,
            size: 28,
          ),
          tooltip: widget.isArabicUi ? 'تشغيل الصفحة' : 'Play page',
        );
      },
    );
  }

  Widget _buildPageBookmarkButton(MushafPage page) {
    final pageId = '${widget.surahNumber}:page:${page.pageNumber}';
    final isBookmarked = _bookmarkService.isBookmarked(pageId);

    return IconButton(
      onPressed: () {
        final isArabicUi = widget.isArabicUi;

        if (isBookmarked) {
          _bookmarkService.removeBookmark(pageId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabicUi ? 'تم حذف الإشارة' : 'Bookmark removed'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Get first ayah text as preview
          final arabicText = page.ayahs.isNotEmpty
              ? page.ayahs.first.text.substring(
                      0,
                      page.ayahs.first.text.length > 50
                          ? 50
                          : page.ayahs.first.text.length,
                    ) +
                    '...'
              : 'بِسۡمِ ٱللَّهِ';

          _bookmarkService.addBookmark(
            id: pageId,
            reference: '${widget.surahNumber}:page:${page.pageNumber}',
            arabicText: arabicText,
            surahName: widget.surah.name,
            surahNumber: widget.surahNumber,
            ayahNumber: null, // Indicates this is a page bookmark
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabicUi ? 'تمت إضافة إشارة' : 'Bookmark added'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        setState(() {}); // Refresh the button state
      },
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: AppColors.secondary,
        size: 28,
      ),
      tooltip: widget.isArabicUi ? 'إشارة مرجعية' : 'Bookmark',
    );
  }

  String _toArabicNumerals(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      final index = int.tryParse(digit);
      return index != null ? arabicDigits[index] : digit;
    }).join();
  }

  // Helper methods for ornamental decorations

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

  Widget _buildCenterOrnament() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: AyahNumberPainter(color: AppColors.primary, number: 0),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicStar({double size = 30}) {
    return CustomPaint(
      size: Size(size, size),
      painter: AyahNumberPainter(color: AppColors.primary, number: 0),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          Icons.auto_awesome,
          size: size * 0.5,
          color: AppColors.primary.withValues(alpha: 0.4),
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
}

class MushafPage {
  final int pageNumber;
  final List<Ayah> ayahs;

  MushafPage({required this.pageNumber, required this.ayahs});
}

// Custom Painters for Islamic decorative elements

class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw geometric Islamic pattern
    const patternSize = 40.0;
    for (double x = 0; x < size.width; x += patternSize) {
      for (double y = 0; y < size.height; y += patternSize) {
        // Draw diamond shape
        final path = Path()
          ..moveTo(x + patternSize / 2, y)
          ..lineTo(x + patternSize, y + patternSize / 2)
          ..lineTo(x + patternSize / 2, y + patternSize)
          ..lineTo(x, y + patternSize / 2)
          ..close();
        canvas.drawPath(path, paint);

        // Draw inner circle
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

    // Draw ornamental border
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);

    // Draw corner ornaments
    final cornerSize = 20.0;
    final corners = [
      Offset(10, 10), // Top-left
      Offset(size.width - 10, 10), // Top-right
      Offset(10, size.height - 10), // Bottom-left
      Offset(size.width - 10, size.height - 10), // Bottom-right
    ];

    for (final corner in corners) {
      _drawCornerOrnament(canvas, corner, cornerSize, paint);
    }
  }

  void _drawCornerOrnament(
    Canvas canvas,
    Offset center,
    double size,
    Paint paint,
  ) {
    // Draw small decorative element at each corner
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
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

class AyahNumberPainter extends CustomPainter {
  final Color color;
  final int number;

  AyahNumberPainter({required this.color, required this.number});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw star background
    final starPath = Path();
    const numPoints = 8;
    const outerRadius = 18.0;
    const innerRadius = 9.0;

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (i * math.pi / numPoints) - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    canvas.drawPath(starPath, paint);

    // Draw circle
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 13, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
