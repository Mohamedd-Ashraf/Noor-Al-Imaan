import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class TasbeehTutorialKeys {
  static final counter = GlobalKey();
  static final tapArea = GlobalKey();
  static final dhikrSelector = GlobalKey();
  static final resetButton = GlobalKey();
}

class TasbeehTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: TasbeehTutorialKeys.counter,
        titleAr: 'العدّاد',
        titleEn: 'Counter',
        descriptionAr: 'يعرض عدد مرات التسبيح الحالية',
        descriptionEn: 'Shows the current tasbeeh count',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: TasbeehTutorialKeys.tapArea,
        titleAr: 'اضغط للتسبيح',
        titleEn: 'Tap to Count',
        descriptionAr: 'اضغط في أي مكان لزيادة العدّاد بواحد',
        descriptionEn: 'Tap anywhere to increment the counter by one',
        align: ContentAlign.top,
      ),
      TutorialStep(
        key: TasbeehTutorialKeys.resetButton,
        titleAr: 'إعادة التعيين',
        titleEn: 'Reset',
        descriptionAr: 'اضغط لإعادة العدّاد إلى الصفر',
        descriptionEn: 'Tap to reset the counter to zero',
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
      ),
    ];
  }

  static void show({
    required BuildContext context,
    required TutorialService tutorialService,
    required bool isArabic,
    required bool isDark,
  }) {
    if (tutorialService
        .isTutorialComplete(TutorialService.tasbeehScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService.markComplete(TutorialService.tasbeehScreen);
          },
        );
      }
    });
  }
}
