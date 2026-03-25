import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class AdhkarTutorialKeys {
  static final categoryGrid = GlobalKey();
  static final morningCard = GlobalKey();
  static final eveningCard = GlobalKey();
}

class AdhkarTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: AdhkarTutorialKeys.categoryGrid,
        titleAr: 'أقسام الأذكار',
        titleEn: 'Adhkar Categories',
        descriptionAr:
            'اختر من أقسام متعددة: أذكار الصباح، المساء، النوم، وغيرها',
        descriptionEn:
            'Choose from multiple categories: Morning, Evening, Sleep, and more',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: AdhkarTutorialKeys.morningCard,
        titleAr: 'أذكار الصباح',
        titleEn: 'Morning Adhkar',
        descriptionAr:
            'اضغط لفتح أذكار الصباح مع عدّاد تلقائي لكل ذكر',
        descriptionEn:
            'Tap to open morning adhkar with an automatic counter for each dhikr',
        align: ContentAlign.bottom,
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
        .isTutorialComplete(TutorialService.adhkarScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService.markComplete(TutorialService.adhkarScreen);
          },
        );
      }
    });
  }
}
