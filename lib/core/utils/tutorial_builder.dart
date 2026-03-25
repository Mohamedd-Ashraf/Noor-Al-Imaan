import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../theme/tutorial_styles.dart';
import '../di/injection_container.dart' as di;
import '../services/tutorial_service.dart';
import 'tutorial_config.dart';

/// Global mutex — prevents two tutorials from showing at the same time.
/// Applies across all screens.
bool _isTutorialActive = false;

/// Describes a single tutorial step.
class TutorialStep {
  final GlobalKey key;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final ContentAlign align;
  final ShapeLightFocus shape;

  const TutorialStep({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.align = ContentAlign.bottom,
    this.shape = ShapeLightFocus.RRect,
  });
}

/// Builds and shows a [TutorialCoachMark] from a list of [TutorialStep]s.
class TutorialBuilder {
  TutorialBuilder._();

  static TutorialCoachMark build({
    required BuildContext context,
    required List<TutorialStep> steps,
    required bool isArabic,
    required bool isDark,
    required VoidCallback onFinish,
    VoidCallback? onSkip,
  }) {
    final targets = <TargetFocus>[];
    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final isLastStep = i == steps.length - 1;

      // Auto-compute alignment: place content on the side with more room.
      ContentAlign effectiveAlign = step.align;
      final targetCtx = step.key.currentContext;
      if (targetCtx != null) {
        final box = targetCtx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.localToGlobal(Offset.zero);
          final targetCenter = pos.dy + box.size.height / 2;
          effectiveAlign = targetCenter > screenHeight * 0.45
              ? ContentAlign.top
              : ContentAlign.bottom;
        }
      }

      targets.add(
        TargetFocus(
          identify: 'step_$i',
          keyTarget: step.key,
          alignSkip: isArabic ? Alignment.topLeft : Alignment.topRight,
          shape: step.shape,
          radius: 8,
          paddingFocus: 12,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: effectiveAlign,
              builder: (context, controller) {
                return TutorialStyles.buildContent(
                  titleAr: step.titleAr,
                  titleEn: step.titleEn,
                  descriptionAr: step.descriptionAr,
                  descriptionEn: step.descriptionEn,
                  isArabic: isArabic,
                  isDark: isDark,
                  stepIndex: i,
                  totalSteps: steps.length,
                  onNext: () => controller.next(),
                  onSkip: isLastStep ? null : () => controller.skip(),
                  isLastStep: isLastStep,
                );
              },
            ),
          ],
        ),
      );
    }

    return TutorialCoachMark(
      targets: targets,
      colorShadow: TutorialStyles.overlayColor,
      opacityShadow: 0.82,
      hideSkip: true,
      onFinish: onFinish,
      onClickTarget: (target) {},
      onClickOverlay: (target) {},
      onSkip: () {
        onSkip?.call();
        onFinish();
        return true;
      },
      pulseEnable: true,
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration: const Duration(milliseconds: 350),
    );
  }

  /// Returns [true] if [context] is currently visible to the user.
  ///
  /// Inside an [IndexedStack]-based bottom navigation, inactive tabs are
  /// wrapped in [Offstage(offstage: true)].  Calling this before showing a
  /// tutorial prevents animations from firing on hidden screens.
  static bool isTabVisible(BuildContext context) {
    if (!context.mounted) return false;
    // Walk up the widget tree looking for the nearest Offstage ancestor.
    // If it is offstage the screen is not visible to the user.
    final offstage = context.findAncestorWidgetOfExactType<Offstage>();
    if (offstage != null && offstage.offstage) return false;
    return true;
  }

  /// Convenience method to build and show in one call.
  ///
  /// Returns [true] if the tutorial was actually shown, [false] if it was
  /// blocked (another tutorial is already active, or kill-switch is off).
  ///
  /// Awaits [TutorialService.appReady] so tutorials never appear while
  /// permission dialogs, startup banners, or feedback sheets are visible.
  static Future<bool> show({
    required BuildContext context,
    required List<TutorialStep> steps,
    required bool isArabic,
    required bool isDark,
    required VoidCallback onFinish,
    VoidCallback? onSkip,
  }) async {
    // Master kill-switch.
    if (!TutorialConfig.kTutorialsEnabled) return false;
    if (steps.isEmpty) return false;

    // Wait until permission dialogs, banners, etc. have been dismissed.
    await di.sl<TutorialService>().appReady;

    // Context may have become invalid while waiting.
    if (!context.mounted) return false;

    // Safety: if the tab is off-screen (IndexedStack Offstage) skip.
    if (!isTabVisible(context)) return false;

    // Global mutex — only one tutorial overlay at a time.
    if (_isTutorialActive) return false;

    // Filter steps: key must be attached AND target visible on screen.
    final screenHeight = MediaQuery.of(context).size.height;
    final validSteps = steps.where((s) {
      final ctx = s.key.currentContext;
      if (ctx == null) return false;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return false;
      final pos = box.localToGlobal(Offset.zero);
      final targetCenter = pos.dy + box.size.height / 2;
      // Target center must be within the visible screen area.
      return targetCenter > 0 && targetCenter < screenHeight;
    }).toList();
    if (validSteps.isEmpty) return false;

    _isTutorialActive = true;

    void releaseAndFinish() {
      _isTutorialActive = false;
      onFinish();
    }

    final tutorial = build(
      context: context,
      steps: validSteps,
      isArabic: isArabic,
      isDark: isDark,
      onFinish: releaseAndFinish,
      onSkip: onSkip == null
          ? null
          : () {
              _isTutorialActive = false;
              onSkip();
            },
    );

    tutorial.show(context: context);
    return true;
  }
}
