import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/surah/surah_bloc.dart';
import '../bloc/surah/surah_event.dart';
import '../bloc/surah/surah_state.dart';
import '../../domain/entities/surah.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/settings_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/audio/ayah_audio_cubit.dart';
import '../../../../core/widgets/islamic_logo.dart';
import '../../../islamic/presentation/screens/adhan_settings_screen.dart';
import '../../../islamic/presentation/screens/prayer_times_screen.dart';
import '../../../adhkar/presentation/screens/adhkar_categories_screen.dart';
import 'offline_audio_screen.dart';
import 'juz_list_screen.dart';
import '../../../islamic/presentation/widgets/next_prayer_countdown.dart';
import 'surah_detail_screen.dart';
import '../../../islamic/presentation/screens/qiblah_screen.dart';
import '../widgets/islamic_audio_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final Map<int, String> _juzLabelBySurahNumber = {};
  final Set<int> _loadingJuzForSurah = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  void _loadSurahs() {
    final currentState = context.read<SurahBloc>().state;
    // Only load if we don't have the list or if we have an error/detail state
    if (currentState is! SurahListLoaded) {
      context.read<SurahBloc>().add(GetAllSurahsEvent());
    }
  }

  void reload() {
    context.read<SurahBloc>().add(GetAllSurahsEvent());
  }

  String _revelationLabel(String revelationType, {required bool isArabicUi}) {
    final value = revelationType.toLowerCase().trim();
    if (!isArabicUi) {
      return value.startsWith('med') ? 'Medinan' : 'Meccan';
    }
    return value.startsWith('med') ? 'مدنية' : 'مكية';
  }

  String _ayahCountLabel(int count, {required bool isArabicUi}) {
    if (!isArabicUi) return '$count Ayahs';
    // Keep it simple; Arabic pluralization can be refined later.
    return '$count آية';
  }

  Future<void> _ensureJuzLabel(int surahNumber) async {
    if (_juzLabelBySurahNumber.containsKey(surahNumber)) return;
    if (_loadingJuzForSurah.contains(surahNumber)) return;
    _loadingJuzForSurah.add(surahNumber);

    try {
      final jsonString = await rootBundle.loadString(
        'assets/offline/surah_$surahNumber.json',
      );
      final decoded = jsonDecode(jsonString);
      final ayahs = (decoded is Map<String, dynamic>)
          ? (decoded['ayahs'] as List?)
          : null;

      int? firstJuz;
      int? lastJuz;
      if (ayahs != null && ayahs.isNotEmpty) {
        final first = ayahs.first;
        final last = ayahs.last;
        if (first is Map) {
          final v = first['juz'];
          if (v is int) firstJuz = v;
        }
        if (last is Map) {
          final v = last['juz'];
          if (v is int) lastJuz = v;
        }
      }

      if (firstJuz != null) {
        final label = (lastJuz != null && lastJuz != firstJuz)
            ? 'Juz $firstJuz-$lastJuz'
            : 'Juz $firstJuz';
        _juzLabelBySurahNumber[surahNumber] = label;
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Ignore; juz will simply not show.
    } finally {
      _loadingJuzForSurah.remove(surahNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isArabicUi = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IslamicLogo(
            size: 32,
            darkTheme: context.watch<AppSettingsCubit>().state.darkMode,
          ),
        ),
        title: Text(isArabicUi ? 'القرآن الكريم' : 'Quran'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          ),
        ),
        actions: [
          // Dark mode toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                context.watch<AppSettingsCubit>().state.darkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: AppColors.onPrimary,
              ),
              tooltip: isArabicUi
                  ? (context.watch<AppSettingsCubit>().state.darkMode
                        ? 'الوضع الفاتح'
                        : 'الوضع الداكن')
                  : (context.watch<AppSettingsCubit>().state.darkMode
                        ? 'Light Mode'
                        : 'Dark Mode'),
              onPressed: () {
                final cubit = context.read<AppSettingsCubit>();
                cubit.setDarkMode(!cubit.state.darkMode);
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<SurahBloc, SurahState>(
        builder: (context, state) {
          if (state is SurahLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SurahListLoaded) {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: NextPrayerCountdown()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _CategoriesSection(isArabicUi: isArabicUi),
                  ),
                ),
                //TODO شوف مكان احسن للزرار ده واتأكد انه م
                // SliverToBoxAdapter(
                //   child: Padding(
                //     padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                //     child: _QuranPlaylistBanner(
                //       isArabicUi: isArabicUi,
                //       surahs: state.surahs,
                //     ),
                //   ),
                // ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final surah = state.surahs[index];
                      _ensureJuzLabel(surah.number);
                      final juzLabel = _juzLabelBySurahNumber[surah.number];

                      final revelation = _revelationLabel(
                        surah.revelationType,
                        isArabicUi: isArabicUi,
                      );
                      final ayahs = _ayahCountLabel(
                        surah.numberOfAyahs,
                        isArabicUi: isArabicUi,
                      );
                      final juz = juzLabel == null
                          ? null
                          : (isArabicUi
                                ? juzLabel.replaceFirst('Juz', 'الجزء')
                                : juzLabel);
                      final detailsParts = <String>[
                        revelation,
                        ayahs,
                        if (juz != null) juz,
                      ];
                      final detailsLine = detailsParts.join(' • ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shadowColor: AppColors.secondary.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).cardColor,
                                Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.95),
                              ],
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurahDetailScreen(
                                    surahNumber: surah.number,
                                    surahName: isArabicUi
                                        ? surah.name
                                        : surah.englishName,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                textDirection: isArabicUi
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.gradientStart,
                                          AppColors.gradientEnd,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.secondary,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${surah.number}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: isArabicUi
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabicUi
                                              ? surah.name
                                              : surah.englishName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: isArabicUi
                                              ? TextAlign.right
                                              : TextAlign.left,
                                          textDirection: isArabicUi
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          locale: isArabicUi
                                              ? const Locale('ar')
                                              : null,
                                          strutStyle: isArabicUi
                                              ? const StrutStyle(
                                                  height: 1.6,
                                                  forceStrutHeight: true,
                                                )
                                              : null,
                                          style: isArabicUi
                                              ? GoogleFonts.amiriQuran(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.6,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                                )
                                              : Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          detailsLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: isArabicUi
                                              ? TextAlign.right
                                              : TextAlign.left,
                                          textDirection: isArabicUi
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          context
                                              .read<AyahAudioCubit>()
                                              .togglePlaySurah(
                                                surahNumber: surah.number,
                                                numberOfAyahs:
                                                    surah.numberOfAyahs,
                                              );
                                        },
                                        child: Tooltip(
                                          message: isArabicUi
                                              ? 'تشغيل السورة كاملة'
                                              : 'Play full surah',
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: state.surahs.length),
                  ),
                ),
              ],
            );
          } else if (state is SurahError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SurahBloc>().add(GetAllSurahsEvent());
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
      bottomNavigationBar: IslamicAudioPlayer(isArabicUi: isArabicUi),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final bool isArabicUi;

  const _CategoriesSection({required this.isArabicUi});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: isDark ? AppColors.secondary : AppColors.primary,
      letterSpacing: 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Islamic pattern background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: isDark
                      ? AppColors.secondary.withValues(alpha: 0.04)
                      : AppColors.primary.withValues(alpha: 0.04),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.darkCard, AppColors.darkSurface]
                    : [AppColors.surfaceVariant, AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: isArabicUi
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isArabicUi
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isArabicUi) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: isDark
                              ? AppColors.secondary
                              : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      isArabicUi ? 'الأقسام' : 'Categories',
                      style: titleStyle,
                    ),
                    if (isArabicUi) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: isDark
                              ? AppColors.secondary
                              : AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 0.80,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _CategoryTile(
                      label: isArabicUi ? 'مواقيت الصلاة' : 'Prayer Times',
                      imagePath: 'assets/logo/button icons/moon.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrayerTimesScreen(),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: isArabicUi ? 'الأذكار والأدعية' : 'Adhkar',
                      imagePath: 'assets/logo/button icons/praying.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdhkarCategoriesScreen(),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: isArabicUi ? 'الأذان' : 'Adhan',
                      imagePath: 'assets/logo/button icons/nabawi-mosque.png',
                      imagePadding: 3,
                      showDisabledBadge:
                          !di.sl<SettingsService>().getAdhanNotificationsEnabled(),
                      disabledTooltip:
                          isArabicUi ? 'الأذان معطَّل' : 'Adhan disabled',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdhanSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: isArabicUi ? 'الصوت' : 'Audio',
                      imagePath: 'assets/logo/button icons/microphone.png',
                      // imageTint: Colors.white,
                      imagePadding: 2,

                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OfflineAudioScreen(),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: isArabicUi ? 'الأجزاء' : 'Juz',
                      imagePath: 'assets/logo/button icons/quran.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const JuzListScreen(),
                          ),
                        );
                      },
                    ),
                    _CategoryTile(
                      label: isArabicUi ? 'القبلة' : 'Qibla',
                      imagePath: 'assets/logo/button icons/qibla.png',
                      imagePadding: 0,

                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QiblahScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.15 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.25 : 0.1,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isArabicUi
                        ? 'يمكنك الوصول للسور من خلال الأجزاء أو من القائمة أدناه.'
                        : 'Access Surahs through Juz or the list below.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? const Color(0xFFB0B0B0)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quran Playlist Banner
// ─────────────────────────────────────────────────────────────────────────────

class _QuranPlaylistBanner extends StatelessWidget {
  final bool isArabicUi;
  final List<Surah> surahs;

  const _QuranPlaylistBanner({
    required this.isArabicUi,
    required this.surahs,
  });

  void _playAll(BuildContext context) {
    final queue = surahs
        .map((s) => (surahNumber: s.number, numberOfAyahs: s.numberOfAyahs))
        .toList();
    context.read<AyahAudioCubit>().playQueue(queue);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabicUi
              ? 'يتم الآن تشغيل القرآن الكريم كاملاً 🎙'
              : 'Playing the full Holy Quran 🎙',
          textDirection: isArabicUi ? TextDirection.rtl : TextDirection.ltr,
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _selectSurahs(BuildContext context) async {
    final selected = await showModalBottomSheet<List<Surah>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectSurahsSheet(
        surahs: surahs,
        isArabicUi: isArabicUi,
      ),
    );
    if (selected == null || selected.isEmpty) return;
    if (!context.mounted) return;
    final queue = selected
        .map((s) => (surahNumber: s.number, numberOfAyahs: s.numberOfAyahs))
        .toList();
    context.read<AyahAudioCubit>().playQueue(queue);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.gradientStart.withValues(alpha: 0.85),
                  AppColors.gradientEnd.withValues(alpha: 0.70),
                ]
              : [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle Islamic star pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arabic header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isArabicUi ? 'استمع للقرآن الكريم' : 'Listen to the Holy Quran',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: isArabicUi ? 0.5 : 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.headphones_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Divider with gold ornament
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.secondary.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.star_rounded,
                          color: AppColors.secondary,
                          size: 14,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Buttons
                  Row(
                    children: [
                      // Play Full Quran
                      Expanded(
                        child: _BannerButton(
                          label: isArabicUi ? 'تشغيل القرآن كاملاً' : 'Play Full Quran',
                          icon: Icons.play_circle_fill_rounded,
                          filled: true,
                          onPressed: () => _playAll(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Select specific surahs
                      Expanded(
                        child: _BannerButton(
                          label: isArabicUi ? 'اختر سوراً' : 'Select Surahs',
                          icon: Icons.playlist_add_check_rounded,
                          filled: false,
                          onPressed: () => _selectSurahs(context),
                        ),
                      ),
                    ],
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

class _BannerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _BannerButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onBackground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.secondary),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          side: BorderSide(color: AppColors.secondary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Select Surahs Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SelectSurahsSheet extends StatefulWidget {
  final List<Surah> surahs;
  final bool isArabicUi;

  const _SelectSurahsSheet({
    required this.surahs,
    required this.isArabicUi,
  });

  @override
  State<_SelectSurahsSheet> createState() => _SelectSurahsSheetState();
}

class _SelectSurahsSheetState extends State<_SelectSurahsSheet> {
  final Set<int> _selected = {};
  String _query = '';

  List<Surah> get _filtered {
    if (_query.trim().isEmpty) return widget.surahs;
    final q = _query.trim().toLowerCase();
    return widget.surahs.where((s) {
      return s.name.contains(q) ||
          s.englishName.toLowerCase().contains(q) ||
          '${s.number}' == q;
    }).toList();
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == widget.surahs.length) {
        _selected.clear();
      } else {
        _selected.addAll(widget.surahs.map((s) => s.number));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;
    final isAr = widget.isArabicUi;
    final selectedCount = _selected.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with gradient
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.playlist_add_check_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr ? 'اختر السور للتشغيل' : 'Select Surahs to Play',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _selected.length == widget.surahs.length
                            ? (isAr ? 'إلغاء الكل' : 'Deselect All')
                            : (isAr ? 'اختر الكل' : 'Select All'),
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  textDirection:
                      isAr ? TextDirection.rtl : TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: isAr ? 'ابحث عن سورة…' : 'Search surah…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF8A9BAB)
                          : AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkCard
                        : AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              // Surah list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'لا توجد نتائج' : 'No results',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF8A9BAB)
                                : AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final surah = filtered[i];
                          final isChecked = _selected.contains(surah.number);
                          return _SurahCheckTile(
                            surah: surah,
                            isArabicUi: isAr,
                            isChecked: isChecked,
                            isDark: isDark,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selected.add(surah.number);
                                } else {
                                  _selected.remove(surah.number);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),

              // Bottom action bar
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      // Selection count chip
                      if (selectedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$selectedCount ${isAr ? 'سورة' : 'Surah'}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (selectedCount > 0) const SizedBox(width: 10),
                      // Play button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedCount == 0
                              ? null
                              : () {
                                  // Return selected surahs in original order
                                  final orderedSelected = widget.surahs
                                      .where(
                                        (s) => _selected.contains(s.number),
                                      )
                                      .toList();
                                  Navigator.of(context)
                                      .pop(orderedSelected);
                                },
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          label: Text(
                            selectedCount == 0
                                ? (isAr ? 'اختر سورة أولاً' : 'Select a surah first')
                                : (isAr
                                    ? 'تشغيل $selectedCount ${selectedCount == 1 ? 'سورة' : 'سور'}'
                                    : 'Play $selectedCount ${selectedCount == 1 ? 'Surah' : 'Surahs'}'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SurahCheckTile extends StatelessWidget {
  final Surah surah;
  final bool isArabicUi;
  final bool isChecked;
  final bool isDark;
  final ValueChanged<bool?> onChanged;

  const _SurahCheckTile({
    required this.surah,
    required this.isArabicUi,
    required this.isChecked,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isChecked
            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark ? AppColors.darkCard : AppColors.surfaceVariant),
        border: Border.all(
          color: isChecked
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.secondary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!isChecked),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            textDirection:
                isArabicUi ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Surah number circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Names
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabicUi
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabicUi ? surah.name : surah.englishName,
                      textDirection: isArabicUi
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isArabicUi ? 16 : 14,
                        color: isDark
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.numberOfAyahs} ${isArabicUi ? 'آية' : 'ayahs'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF8A9BAB)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isChecked
                        ? AppColors.primary
                        : AppColors.secondary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Islamic geometric pattern painter
// ─────────────────────────────────────────────────────────────────────────────

class _IslamicPatternPainter extends CustomPainter {
  final Color color;

  _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;

    // Draw star pattern
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, Offset(x, y), 12, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final points = 8;
    final angle = (3.14159 * 2) / points;

    for (int i = 0; i < points; i++) {
      final x = center.dx + radius * cos(angle * i - 3.14159 / 2);
      final y = center.dy + radius * sin(angle * i - 3.14159 / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;
  final double imagePadding;
  final bool showDisabledBadge;
  final String? disabledTooltip;

  const _CategoryTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.imagePadding = 4,
    this.showDisabledBadge = false,
    this.disabledTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.9),
              ],
            ),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientMid,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(imagePadding),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (showDisabledBadge)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Tooltip(
                              message: disabledTooltip ?? '',
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.orange.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
