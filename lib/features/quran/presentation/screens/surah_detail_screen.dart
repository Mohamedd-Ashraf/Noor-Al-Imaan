import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/surah/surah_bloc.dart';
import '../bloc/surah/surah_event.dart';
import '../bloc/surah/surah_state.dart';
import '../../domain/usecases/get_surah.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/audio/ayah_audio_cubit.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialAyahNumber;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialAyahNumber,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  late final BookmarkService _bookmarkService;

  final GlobalKey _targetAyahKey = GlobalKey();
  bool _didScrollToTarget = false;
  static const double _estimatedAyahItemExtent = 240;

  final Map<int, String> _translationByAyah = {};
  bool _isLoadingTranslation = false;
  String? _translationError;

  @override
  void initState() {
    super.initState();
    _bookmarkService = di.sl<BookmarkService>();

    context.read<SurahBloc>().add(GetSurahDetailEvent(widget.surahNumber));

    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      } else if (_scrollController.offset <= 400 && _showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Stop ayah playback when leaving this screen.
    // If you later want background playback, remove this.
    try {
      context.read<AyahAudioCubit>().stop();
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLanguageCode = context.select<AppSettingsCubit, String>(
      (cubit) => cubit.state.appLanguageCode,
    );
    final isArabicUi = appLanguageCode.toLowerCase().startsWith('ar');

    final arabicFontSize = context.select<AppSettingsCubit, double>(
      (cubit) => cubit.state.arabicFontSize,
    );
    final translationFontSize = context.select<AppSettingsCubit, double>(
      (cubit) => cubit.state.translationFontSize,
    );

    final showTranslation = context.select<AppSettingsCubit, bool>(
      (cubit) => cubit.state.showTranslation,
    );

    if (showTranslation) {
      _maybeLoadTranslation();
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Ensure HomeScreen sees a list state after returning.
          context.read<SurahBloc>().add(GetAllSurahsEvent());
        }
      },
      child: BlocListener<AyahAudioCubit, AyahAudioState>(
        listenWhen: (prev, next) =>
            next.status == AyahAudioStatus.error &&
            next.errorMessage != prev.errorMessage,
        listener: (context, state) {
          final msg = state.errorMessage;
          if (msg == null || msg.isEmpty) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
        child: Scaffold(
          body: BlocBuilder<SurahBloc, SurahState>(
            builder: (context, state) {
              if (state is SurahLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SurahDetailLoaded) {
                final surah = state.surah;

                final audioState = context.watch<AyahAudioCubit>().state;
                final isThisSurahAudio =
                    audioState.surahNumber == widget.surahNumber &&
                    audioState.mode == AyahAudioMode.surah;
                final isSurahPlaying =
                    isThisSurahAudio &&
                    audioState.status == AyahAudioStatus.playing;
                final isSurahBuffering =
                    isThisSurahAudio &&
                    audioState.status == AyahAudioStatus.buffering;

                _maybeScrollToInitialAyah();

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Collapsible Header with SliverAppBar
                    SliverAppBar(
                      expandedHeight: 220,
                      floating: false,
                      pinned: true,
                      actions: [
                        IconButton(
                          tooltip: isSurahPlaying
                              ? (isArabicUi ? 'إيقاف مؤقت' : 'Pause surah')
                              : (isSurahBuffering
                                    ? (isArabicUi
                                          ? 'جاري التحميل…'
                                          : 'Loading…')
                                    : (isArabicUi
                                          ? 'تشغيل السورة كاملة'
                                          : 'Play full surah')),
                          icon: Icon(
                            isSurahBuffering
                                ? Icons.hourglass_top
                                : (isSurahPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow),
                            color: Colors.white,
                          ),
                          onPressed: () {
                            context.read<AyahAudioCubit>().togglePlaySurah(
                              surahNumber: widget.surahNumber,
                              numberOfAyahs: surah.numberOfAyahs,
                            );
                          },
                        ),
                      ],
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final topPadding = MediaQuery.of(context).padding.top;
                          final collapsedHeight = kToolbarHeight + topPadding;
                          // Hide the large header early during collapse to avoid overflow.
                          // The expanded header content needs ~140px (plus status bar) to fit.
                          final showExpandedHeader =
                              constraints.biggest.height >=
                              collapsedHeight + 140;
                          final showCollapsedTitle = !showExpandedHeader;

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                ),
                              ),
                              // Expanded header content
                              if (showExpandedHeader)
                                ClipRect(
                                  child: SafeArea(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 20),
                                        Text(
                                          surah.name,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.amiriQuran(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          surah.englishNameTranslation,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isArabicUi
                                              ? '${surah.revelationType.toUpperCase()} • ${surah.numberOfAyahs} آية'
                                              : '${surah.revelationType.toUpperCase()} • ${surah.numberOfAyahs} VERSES',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 56,
                                    right: 56,
                                  ),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: showCollapsedTitle ? 1.0 : 0.0,
                                    child: IgnorePointer(
                                      ignoring: !showCollapsedTitle,
                                      child: Text(
                                        isArabicUi ? surah.name : surah.englishName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: (isArabicUi
                                                ? GoogleFonts.amiriQuran(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.1,
                                                  )
                                                : GoogleFonts.cairo(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ))
                                            .copyWith(
                                              color: Colors.white,
                                              shadows: const [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black26,
                                                ),
                                              ],
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Bismillah (except for Surah 9)
                    if (widget.surahNumber != 1 && widget.surahNumber != 9)
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: AppColors.surface,
                          child: Text(
                            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiriQuran(
                              fontSize: 28,
                              color: AppColors.arabicText,
                              fontWeight: FontWeight.w700,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ),
                    // Ayahs List
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final ayah = surah.ayahs![index];
                          final audioState = context
                              .watch<AyahAudioCubit>()
                              .state;
                          final isCurrentAudio = audioState.isCurrent(
                            widget.surahNumber,
                            ayah.numberInSurah,
                          );

                          final isPlaying =
                              isCurrentAudio &&
                              audioState.status == AyahAudioStatus.playing;
                          final isBuffering =
                              isCurrentAudio &&
                              audioState.status == AyahAudioStatus.buffering;

                          final card = Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isCurrentAudio
                                  ? BorderSide(
                                      color: isPlaying
                                          ? AppColors.secondary
                                          : AppColors.primary.withValues(
                                              alpha: 0.6,
                                            ),
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Ayah Number Badge and Bookmark Button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          isArabicUi
                                              ? 'الآية ${ayah.numberInSurah}'
                                              : 'Ayah ${ayah.numberInSurah}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: isPlaying
                                                ? (isArabicUi
                                                      ? 'إيقاف مؤقت'
                                                      : 'Pause')
                                                : (isBuffering
                                                      ? (isArabicUi
                                                            ? 'جاري التحميل…'
                                                            : 'Loading…')
                                                      : (isArabicUi
                                                            ? 'تشغيل'
                                                            : 'Play')),
                                            icon: Icon(
                                              isBuffering
                                                  ? Icons.hourglass_top
                                                  : (isPlaying
                                                        ? Icons
                                                              .pause_circle_filled
                                                        : Icons
                                                              .play_circle_fill),
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () {
                                              context
                                                  .read<AyahAudioCubit>()
                                                  .togglePlayAyah(
                                                    surahNumber:
                                                        widget.surahNumber,
                                                    ayahNumber:
                                                        ayah.numberInSurah,
                                                  );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _bookmarkService.isBookmarked(
                                                    '${widget.surahNumber}:${ayah.numberInSurah}',
                                                  )
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              color: AppColors.secondary,
                                            ),
                                            onPressed: () {
                                              final bookmarkId =
                                                  '${widget.surahNumber}:${ayah.numberInSurah}';
                                              if (_bookmarkService.isBookmarked(
                                                bookmarkId,
                                              )) {
                                                _bookmarkService.removeBookmark(
                                                  bookmarkId,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      isArabicUi
                                                          ? 'تم حذف الإشارة'
                                                          : 'Bookmark removed',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                _bookmarkService.addBookmark(
                                                  id: bookmarkId,
                                                  reference:
                                                      '${widget.surahNumber}:${ayah.numberInSurah}',
                                                  arabicText: ayah.text,
                                                  surahName: isArabicUi
                                                      ? surah.name
                                                      : surah.englishName,
                                                  surahNumber:
                                                      widget.surahNumber,
                                                  ayahNumber:
                                                      ayah.numberInSurah,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      isArabicUi
                                                          ? 'تمت إضافة إشارة'
                                                          : 'Bookmark added',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Arabic Text (tap to play)
                                  InkWell(
                                    onTap: () {
                                      context
                                          .read<AyahAudioCubit>()
                                          .togglePlayAyah(
                                            surahNumber: widget.surahNumber,
                                            ayahNumber: ayah.numberInSurah,
                                          );
                                    },
                                    child: Text(
                                      ayah.text,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: GoogleFonts.amiriQuran(
                                        color: AppColors.arabicText,
                                        fontWeight: FontWeight.w500,
                                        height: 2,
                                        fontSize: arabicFontSize,
                                      ),
                                    ),
                                  ),

                                  if (showTranslation) ...[
                                    const SizedBox(height: 10),
                                    _buildTranslationWidget(
                                      context,
                                      ayahNumberInSurah: ayah.numberInSurah,
                                      translationFontSize: translationFontSize,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  // Metadata (only show page/juz when they change)
                                  Builder(
                                    builder: (context) {
                                      final prevAyah = index > 0
                                          ? surah.ayahs![index - 1]
                                          : null;

                                        final showJuz =
                                          prevAyah == null || ayah.juz != prevAyah.juz;
                                        final showPage =
                                          prevAyah == null || ayah.page != prevAyah.page;

                                      final chips = <Widget>[];

                                      if (showJuz) {
                                        chips.add(
                                          _buildMetadataChip(
                                            context,
                                            Icons.menu_book,
                                            isArabicUi
                                                ? 'الجزء ${ayah.juz}'
                                                : 'Juz ${ayah.juz}',
                                          ),
                                        );
                                      }

                                      if (showPage) {
                                        chips.add(
                                          _buildMetadataChip(
                                            context,
                                            Icons.description,
                                            isArabicUi
                                                ? 'الصفحة ${ayah.page}'
                                                : 'Page ${ayah.page}',
                                          ),
                                        );
                                      }

                                      if (ayah.sajda) {
                                        chips.add(
                                          _buildMetadataChip(
                                            context,
                                            Icons.accessibility_new,
                                            isArabicUi ? 'سجدة' : 'Sajda',
                                            color: AppColors.secondary,
                                          ),
                                        );
                                      }

                                      if (chips.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: chips,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );

                          final isTarget =
                              widget.initialAyahNumber != null &&
                              ayah.numberInSurah == widget.initialAyahNumber;

                          if (!isTarget) {
                            return card;
                          }

                          return KeyedSubtree(
                            key: _targetAyahKey,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.7,
                                  ),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: card,
                            ),
                          );
                        }, childCount: surah.ayahs?.length ?? 0),
                      ),
                    ),
                  ],
                );
              } else if (state is SurahError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<SurahBloc>().add(
                            GetSurahDetailEvent(widget.surahNumber),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(isArabicUi ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          bottomNavigationBar: BlocBuilder<SurahBloc, SurahState>(
            builder: (context, surahState) {
              return BlocBuilder<AyahAudioCubit, AyahAudioState>(
                buildWhen: (prev, next) => prev != next,
                builder: (context, audioState) {
                  final visible = audioState.status != AyahAudioStatus.idle;
                  if (!visible) return const SizedBox.shrink();

                  final isSurahMode = audioState.mode == AyahAudioMode.surah;
                  final title = isSurahMode
                      ? '${surahNameForBar(surahState, isArabicUi: isArabicUi)} • ${isArabicUi ? 'الآية' : 'Ayah'} ${audioState.ayahNumber ?? '-'}'
                      : '${isArabicUi ? 'الآية' : 'Ayah'} ${audioState.ayahNumber ?? '-'}';

                  final isPlaying =
                      audioState.status == AyahAudioStatus.playing;
                  final isBuffering =
                      audioState.status == AyahAudioStatus.buffering;

                  final cubit = context.read<AyahAudioCubit>();

                  return Material(
                    elevation: 10,
                    color: Theme.of(context).colorScheme.surface,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (isSurahMode)
                                  IconButton(
                                    tooltip: isArabicUi ? 'السابق' : 'Previous',
                                    onPressed: () => cubit.previous(),
                                    icon: const Icon(Icons.skip_previous),
                                  ),
                                IconButton(
                                  tooltip: isPlaying
                                      ? (isArabicUi ? 'إيقاف مؤقت' : 'Pause')
                                      : (isBuffering
                                            ? (isArabicUi
                                                  ? 'جاري التحميل…'
                                                  : 'Loading…')
                                            : (isArabicUi ? 'تشغيل' : 'Play')),
                                  onPressed: () {
                                    if (isSurahMode) {
                                      if (surahState is SurahDetailLoaded) {
                                        cubit.togglePlaySurah(
                                          surahNumber: widget.surahNumber,
                                          numberOfAyahs:
                                              surahState.surah.numberOfAyahs,
                                        );
                                      }
                                    } else {
                                      if (audioState.surahNumber != null &&
                                          audioState.ayahNumber != null) {
                                        cubit.togglePlayAyah(
                                          surahNumber: audioState.surahNumber!,
                                          ayahNumber: audioState.ayahNumber!,
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    isBuffering
                                        ? Icons.hourglass_top
                                        : (isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow),
                                  ),
                                ),
                                if (isSurahMode)
                                  IconButton(
                                    tooltip: isArabicUi ? 'التالي' : 'Next',
                                    onPressed: () => cubit.next(),
                                    icon: const Icon(Icons.skip_next),
                                  ),
                                IconButton(
                                  tooltip: isArabicUi ? 'إيقاف' : 'Stop',
                                  onPressed: () => cubit.stop(),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            StreamBuilder<Duration>(
                              stream: cubit.positionStream,
                              builder: (context, posSnap) {
                                return StreamBuilder<Duration?>(
                                  stream: cubit.durationStream,
                                  builder: (context, durSnap) {
                                    final pos = posSnap.data ?? Duration.zero;
                                    final dur = durSnap.data ?? Duration.zero;
                                    final maxMs = dur.inMilliseconds;
                                    final value = maxMs <= 0
                                        ? 0.0
                                        : (pos.inMilliseconds / maxMs).clamp(
                                            0.0,
                                            1.0,
                                          );
                                    return LinearProgressIndicator(
                                      value: value,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: _showScrollToTop
              ? FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  mini: true,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.arrow_upward),
                )
              : null,
        ),
      ),
    );
  }

  String surahNameForBar(SurahState state, {required bool isArabicUi}) {
    if (state is SurahDetailLoaded) {
      return isArabicUi ? state.surah.name : state.surah.englishName;
    }
    return widget.surahName;
  }

  void _maybeScrollToInitialAyah() {
    if (_didScrollToTarget) return;
    if (widget.initialAyahNumber == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;

      final approx = (widget.initialAyahNumber! - 1) * _estimatedAyahItemExtent;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final target = approx.clamp(0.0, maxExtent);

      _scrollController.jumpTo(target);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _targetAyahKey.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
        _didScrollToTarget = true;
      });
    });
  }

  void _maybeLoadTranslation() {
    if (_isLoadingTranslation) return;
    if (_translationByAyah.isNotEmpty) return;
    if (_translationError != null) return;

    _isLoadingTranslation = true;
    _translationError = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final getSurah = di.sl<GetSurah>();
        final result = await getSurah(
          GetSurahParams(
            surahNumber: widget.surahNumber,
            edition: ApiConstants.defaultTranslation,
          ),
        );

        result.fold(
          (failure) {
            if (!mounted) return;
            setState(() {
              _translationError = failure.message;
              _isLoadingTranslation = false;
            });
          },
          (translatedSurah) {
            if (!mounted) return;
            final map = <int, String>{};
            for (final a in translatedSurah.ayahs ?? const []) {
              map[a.numberInSurah] = a.text;
            }
            setState(() {
              _translationByAyah
                ..clear()
                ..addAll(map);
              _isLoadingTranslation = false;
            });
          },
        );
      } catch (_) {
        if (!mounted) return;
        final isArabicUi = context
            .read<AppSettingsCubit>()
            .state
            .appLanguageCode
            .toLowerCase()
            .startsWith('ar');
        setState(() {
          _translationError = isArabicUi
              ? 'فشل تحميل الترجمة'
              : 'Failed to load translation';
          _isLoadingTranslation = false;
        });
      }
    });
  }

  Widget _buildTranslationWidget(
    BuildContext context, {
    required int ayahNumberInSurah,
    required double translationFontSize,
  }) {
    final isArabicUi = context
        .read<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');
    if (_isLoadingTranslation && _translationByAyah.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isArabicUi ? 'جاري تحميل الترجمة…' : 'Loading translation…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    if (_translationError != null) {
      return Text(
        _translationError!,
        textAlign: TextAlign.left,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
      );
    }

    final text = _translationByAyah[ayahNumberInSurah];
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      text,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.5,
        color: AppColors.textSecondary,
        fontSize: translationFontSize,
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
