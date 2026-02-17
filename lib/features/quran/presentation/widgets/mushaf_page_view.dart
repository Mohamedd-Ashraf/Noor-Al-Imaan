import 'package:flutter/material.dart';
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

class MushafPageView extends StatefulWidget {
  final Surah surah;
  final int? initialPage;
  final bool isArabicUi;
  final int surahNumber;
  final int? initialAyahNumber;

  const MushafPageView({
    super.key,
    required this.surah,
    this.initialPage,
    required this.isArabicUi,
    required this.surahNumber,
    this.initialAyahNumber,
  });

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  late PageController _pageController;
  late List<MushafPage> _pages;
  late final BookmarkService _bookmarkService;
  int? _highlightedAyahNumber;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _bookmarkService = di.sl<BookmarkService>();
    _pages = _groupAyahsByPage();
    final initialPage = _getInitialPageIndex();
    _pageController = PageController(initialPage: initialPage);

    // Animate to target ayah if specified
    if (widget.initialAyahNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToAyah(widget.initialAyahNumber!);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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

    final currentPage = _pageController.page?.round() ?? 0;
    final distance = (targetPageIndex - currentPage).abs();

    setState(() {
      _isAnimating = true;
    });

    // Calculate animation duration based on distance
    // Max 3 seconds even for long distances
    final baseDuration = 300; // milliseconds per page
    final maxDuration = 3000; // max 3 seconds
    final duration = (baseDuration * distance).clamp(300, maxDuration);

    // Animate to the target page
    await _pageController.animateToPage(
      targetPageIndex,
      duration: Duration(milliseconds: duration),
      curve: Curves.easeInOutCubic,
    );

    // Highlight the ayah briefly
    setState(() {
      _highlightedAyahNumber = ayahNumber;
      _isAnimating = false;
    });

    // Remove highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightedAyahNumber = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return Center(
        child: Text(widget.isArabicUi ? 'لا توجد صفحات' : 'No pages available'),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      physics: _isAnimating
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            return _buildPageWithTransition(
              child: _buildMushafPage(_pages[index]),
              pageIndex: index,
            );
          },
        );
      },
    );
  }

  Widget _buildPageWithTransition({
    required Widget child,
    required int pageIndex,
  }) {
    // Get the current page position
    double value = 1.0;
    if (_pageController.hasClients) {
      final currentPage = _pageController.page ?? 0;
      value = (currentPage - pageIndex).abs();
      value = (1 - value).clamp(0.0, 1.0);
    }

    // Calculate rotation based on page position - reduced for smoother effect
    final rotationY = (1 - value) * 0.2; // More subtle rotation

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002) // slightly increased perspective for smoothness
        ..rotateY(rotationY * (pageIndex % 2 == 0 ? -1 : 1)),
      child: Opacity(opacity: value.clamp(0.7, 1.0), child: child),
    );
  }

  Widget _buildMushafPage(MushafPage page) {
    final isFirstAyahOfSurah =
        page.ayahs.isNotEmpty && page.ayahs.first.numberInSurah == 1;
    final needsBasmalah =
        isFirstAyahOfSurah &&
        widget.surah.number != 1 &&
        widget.surah.number != 9;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFBF0),
            const Color(0xFFFFF8E7),
            const Color(0xFFFFF5DE),
          ],
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
                  horizontal: 28,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (needsBasmalah) ...[
                      _buildBasmalah(),
                      const SizedBox(height: 28),
                    ],
                    _buildContinuousText(page.ayahs),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              _toArabicNumerals(pageNumber),
              style: GoogleFonts.amiriQuran(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildSmallOrnament(),
        ],
      ),
    );
  }

  Widget _buildContinuousText(List<Ayah> ayahs) {
    if (ayahs.isEmpty) return const SizedBox();

    return BlocBuilder<AyahAudioCubit, AyahAudioState>(
      builder: (context, audioState) {
        // Get font size from settings
        final arabicFontSize = context
            .watch<AppSettingsCubit>()
            .state
            .arabicFontSize;
        final textSpans = <InlineSpan>[];

        for (int i = 0; i < ayahs.length; i++) {
          final ayah = ayahs[i];
          final isCurrentAudio = audioState.isCurrent(
            widget.surahNumber,
            ayah.numberInSurah,
          );
          final isPlaying =
              isCurrentAudio && audioState.status == AyahAudioStatus.playing;

          // Check if this ayah should be highlighted
          final isHighlighted = _highlightedAyahNumber == ayah.numberInSurah;

          // Add ayah text with tap gesture
          textSpans.add(
            TextSpan(
              text: ayah.text,
              style: GoogleFonts.amiriQuran(
                fontSize: arabicFontSize,
                height: 2.0,
                color: AppColors.arabicText,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                backgroundColor: isHighlighted
                    ? AppColors.secondary.withValues(alpha: 0.35)
                    : (isCurrentAudio
                          ? (isPlaying
                                ? AppColors.secondary.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.15))
                          : null),
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.read<AyahAudioCubit>().togglePlayAyah(
                    surahNumber: widget.surahNumber,
                    ayahNumber: ayah.numberInSurah,
                  );
                },
            ),
          );

          // Add space before ayah number
          textSpans.add(const TextSpan(text: ' '));

          // Add ayah number marker
          textSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildAyahNumberMarker(ayah.numberInSurah),
              ),
            ),
          );

          // Add space between ayahs
          if (i < ayahs.length - 1) {
            textSpans.add(const TextSpan(text: ' '));
          }
        }

        return RichText(
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          text: TextSpan(children: textSpans),
        );
      },
    );
  }

  Widget _buildAyahNumberMarker(int number) {
    return Container(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer star pattern using CustomPaint
          CustomPaint(
            size: const Size(36, 36),
            painter: AyahNumberPainter(
              color: AppColors.primary,
              number: number,
            ),
          ),
          // Main circle background with white color
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                child: Text(
                  _toArabicNumerals(number),
                  style: GoogleFonts.amiriQuran(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
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
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw ornamental border
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
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
      ..color = color.withValues(alpha: 0.2)
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
