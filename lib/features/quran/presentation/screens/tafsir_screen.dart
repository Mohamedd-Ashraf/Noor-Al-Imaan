import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../bloc/tafsir/tafsir_cubit.dart';
import '../bloc/tafsir/tafsir_state.dart';

/// Screen that displays the tafsir (exegesis / commentary) for a single ayah.
/// Navigate to this screen by pushing it with the [TafsirScreen.route] method.
class TafsirScreen extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String surahEnglishName;
  final String arabicAyahText;

  const TafsirScreen({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.arabicAyahText,
  });

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TafsirCubit>().init(
          surahNumber: widget.surahNumber,
          ayahNumber: widget.ayahNumber,
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    final isDark = settings.darkMode;
    final isArabicUi =
        settings.appLanguageCode.toLowerCase().startsWith('ar');

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isArabicUi, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAyahCard(context, isArabicUi, isDark, settings),
                  const SizedBox(height: 16),
                  _buildEditionSelector(context, isArabicUi, isDark,
                      settings.showTranslation),
                  const SizedBox(height: 16),
                  _buildTafsirSection(context, isArabicUi, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────

  Widget _buildAppBar(
      BuildContext context, bool isArabicUi, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;
          final collapsedHeight = kToolbarHeight + topPadding;
          final isCollapsed =
              constraints.biggest.height < collapsedHeight + 50;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF071F13), AppColors.primaryDark]
                        : [AppColors.primaryDark, const Color(0xFF1A7A50)],
                  ),
                ),
              ),
              if (!isCollapsed)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 56, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          isArabicUi
                              ? '${widget.surahName} — الآية ${widget.ayahNumber}'
                              : '${widget.surahEnglishName} — Ayah ${widget.ayahNumber}',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isArabicUi ? 'التفسير والمعنى' : 'Tafsir & Commentary',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // collapsed title
              if (isCollapsed)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 56, right: 16),
                    child: Text(
                      isArabicUi
                          ? '${widget.surahName} — الآية ${widget.ayahNumber}'
                          : '${widget.surahEnglishName} — Ayah ${widget.ayahNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Ayah Card ───────────────────────────────────────────────────────────

  Widget _buildAyahCard(
    BuildContext context,
    bool isArabicUi,
    bool isDark,
    AppSettingsState settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isArabicUi
                        ? 'الآية ${widget.ayahNumber}'
                        : 'Ayah ${widget.ayahNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Spacer(),
                // Copy button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.arabicAyahText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabicUi
                            ? 'تم نسخ الآية'
                            : 'Ayah copied'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(Icons.copy_rounded,
                      size: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Arabic text
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.arabicAyahText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiriQuran(
                fontSize: settings.arabicFontSize + 2,
                height: 2.1,
                color: isDark
                    ? const Color(0xFFE8E8E8)
                    : AppColors.arabicText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edition Selector ────────────────────────────────────────────────────

  Widget _buildEditionSelector(
      BuildContext context, bool isArabicUi, bool isDark, bool showTranslation) {
    // Only expose English commentary editions when translation is enabled
    final editions = ApiConstants.tafsirEditions
        .where((e) => showTranslation || e['lang'] == 'ar')
        .toList();

    return BlocBuilder<TafsirCubit, TafsirState>(
      builder: (context, state) {
        // If the active edition is English but translation was just disabled,
        // silently switch to the first Arabic edition.
        final selectedIsEnglish = ApiConstants.tafsirEditions
            .firstWhere((e) => e['id'] == state.selectedEdition,
                orElse: () => {'lang': 'ar'})
            .containsValue('en');
        if (!showTranslation && selectedIsEnglish) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final firstArabic = editions.first['id']!;
            context.read<TafsirCubit>().selectEdition(firstArabic);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                isArabicUi ? 'اختر التفسير' : 'Select Commentary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: editions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final ed = editions[index];
                  final id = ed['id']!;
                  final label = isArabicUi ? ed['nameAr']! : ed['nameEn']!;
                  final isSelected = state.selectedEdition == id;
                  final isLoading =
                      state.status == TafsirStatus.loading && isSelected;

                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context
                            .read<TafsirCubit>()
                            .selectEdition(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkCard
                                : AppColors.cardBackground),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.cardBorder),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            )
                          : Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : AppColors.textPrimary),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Tafsir Content ──────────────────────────────────────────────────────

  Widget _buildTafsirSection(
      BuildContext context, bool isArabicUi, bool isDark) {
    return BlocBuilder<TafsirCubit, TafsirState>(
      builder: (context, state) {
        if (state.status == TafsirStatus.loading) {
          return _centeredContainer(
            isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  isArabicUi ? 'جاري تحميل التفسير…' : 'Loading tafsir…',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.status == TafsirStatus.error) {
          return _centeredContainer(
            isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48, color: AppColors.error.withValues(alpha: 0.7)),
                const SizedBox(height: 12),
                Text(
                  isArabicUi
                      ? 'تعذّر تحميل التفسير'
                      : 'Failed to load tafsir',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => context.read<TafsirCubit>().retry(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(isArabicUi ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          );
        }

        if (state.status == TafsirStatus.initial) {
          return const SizedBox.shrink();
        }

        // Loaded but no text — e.g. ar.wahidi for an ayah with no sabab
        if (state.status == TafsirStatus.loaded &&
            state.tafsirText.isEmpty) {
          final editionMeta = ApiConstants.tafsirEditions.firstWhere(
            (e) => e['id'] == state.selectedEdition,
            orElse: () => {'nameAr': '', 'nameEn': '', 'lang': 'ar'},
          );
          final editionLabel = isArabicUi
              ? editionMeta['nameAr']!
              : editionMeta['nameEn']!;
          return _centeredContainer(
            isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 40,
                    color: isDark
                        ? Colors.white38
                        : AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  isArabicUi
                      ? 'لا يوجد نص في هذا المصدر لهذه الآية'
                      : 'No content available for this ayah in this edition',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                if (editionLabel.isNotEmpty) ...
                  [
                    const SizedBox(height: 4),
                    Text(
                      editionLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
              ],
            ),
          );
        }

        // ── Loaded state ──────────────────────────────────────────────────
        final editionMeta = ApiConstants.tafsirEditions.firstWhere(
          (e) => e['id'] == state.selectedEdition,
          orElse: () => {'nameAr': '', 'nameEn': '', 'lang': 'ar'},
        );
        final editionLabel = isArabicUi
            ? editionMeta['nameAr']!
            : editionMeta['nameEn']!;
        final tafsirLang = editionMeta['lang'] ?? 'ar';
        final isRtl = tafsirLang == 'ar';

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        editionLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Copy tafsir
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: state.tafsirText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabicUi
                                ? 'تم نسخ التفسير'
                                : 'Tafsir copied'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(Icons.copy_rounded,
                          size: 18, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              // Tafsir text
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  state.tafsirText,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  textDirection:
                      isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: (isRtl
                          ? GoogleFonts.amiri(
                              fontSize: 17,
                              height: 2.0,
                            )
                          : GoogleFonts.merriweather(
                              fontSize: 14,
                              height: 1.8,
                            ))
                      .copyWith(
                    color: isDark ? const Color(0xFFDDD5C8) : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _centeredContainer(bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Center(child: child),
    );
  }
}
