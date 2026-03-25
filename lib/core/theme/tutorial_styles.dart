import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_design_system.dart';

/// Islamic-themed styling helpers for tutorial coach marks.
class TutorialStyles {
  TutorialStyles._();

  /// Overlay color for the coach mark background.
  /// Uses dark color so the cutout "hole" is visible against the
  /// app's green-themed AppBar and backgrounds.
  static Color get overlayColor => const Color(0xFF111111);

  /// Builds the content widget shown next to each highlighted target.
  static Widget buildContent({
    required String titleAr,
    required String titleEn,
    required String descriptionAr,
    required String descriptionEn,
    required bool isArabic,
    required bool isDark,
    int? stepIndex,
    int? totalSteps,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    bool isLastStep = false,
  }) {
    final title = isArabic ? titleAr : titleEn;
    final description = isArabic ? descriptionAr : descriptionEn;
    final nextLabel = isLastStep
        ? (isArabic ? 'تم ✓' : 'Done ✓')
        : (isArabic ? 'التالي' : 'Next');
    final skipLabel = isArabic ? 'تخطي' : 'Skip';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusLg),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Step progress dots
          if (stepIndex != null && totalSteps != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalSteps, (i) {
                  final isActive = i == stepIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: isActive ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.secondary
                          : AppColors.secondary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3.5),
                    ),
                  );
                }),
              ),
            ),

          // Title
          Text(
            title,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.secondary,
              fontFamily: isArabic ? 'Amiri' : null,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            description,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Skip button
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(skipLabel, style: const TextStyle(fontSize: 13)),
                )
              else
                const SizedBox.shrink(),

              // Next / Done button
              if (onNext != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: isLastStep
                        ? AppColors.primaryGradient
                        : AppColors.goldGradient,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onNext,
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        child: Text(
                          nextLabel,
                          style: const TextStyle(
                            color: AppColors.onSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),  // end Container (child of TweenAnimationBuilder)
    ),  // end TweenAnimationBuilder
    );  // end SingleChildScrollView
  }

  /// Builds a simple welcome overlay (no target highlight).
  static Widget buildWelcomeContent({
    required String titleAr,
    required String titleEn,
    required String descriptionAr,
    required String descriptionEn,
    required bool isArabic,
    required bool isDark,
  }) {
    final title = isArabic ? titleAr : titleEn;
    final description = isArabic ? descriptionAr : descriptionEn;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXl),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Islamic star icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.secondary,
              fontFamily: isArabic ? 'Amiri' : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
