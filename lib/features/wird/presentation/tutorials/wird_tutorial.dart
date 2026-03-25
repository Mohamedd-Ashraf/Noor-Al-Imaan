import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class WirdTutorialKeys {
  static final progressCard = GlobalKey();
  static final targetSetting = GlobalKey();
  static final todayPlan = GlobalKey();
  static final continueButton = GlobalKey();
}

class WirdTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: WirdTutorialKeys.progressCard,
        titleAr: 'تقدم الوِرد',
        titleEn: 'Wird Progress',
        descriptionAr:
            'يعرض تقدمك في قراءة الوِرد اليومي مع نسبة الإنجاز',
        descriptionEn:
            'Shows your daily wird reading progress with completion percentage',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: WirdTutorialKeys.todayPlan,
        titleAr: 'ورد اليوم',
        titleEn: "Today's Wird",
        descriptionAr:
            'يوضح المقدار المطلوب قراءته اليوم من السور والآيات',
        descriptionEn:
            'Shows the surahs and ayahs you need to read today',
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
        .isTutorialComplete(TutorialService.wirdScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService.markComplete(TutorialService.wirdScreen);
          },
        );
      }
    });
  }
}
