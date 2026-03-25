import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class SearchTutorialKeys {
  static final searchField = GlobalKey();
  static final resultsList = GlobalKey();
}

class SearchTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: SearchTutorialKeys.searchField,
        titleAr: 'خانة البحث',
        titleEn: 'Search Field',
        descriptionAr:
            'اكتب أي كلمة أو جزء من آية للبحث في القرآن الكريم كاملاً',
        descriptionEn:
            'Type any word or part of a verse to search across the entire Holy Quran',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: SearchTutorialKeys.resultsList,
        titleAr: 'نتائج البحث',
        titleEn: 'Search Results',
        descriptionAr:
            'اضغط على أي نتيجة للانتقال مباشرة إلى الآية في سورتها',
        descriptionEn:
            'Tap any result to jump directly to the ayah in its surah',
        align: ContentAlign.top,
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
        .isTutorialComplete(TutorialService.searchScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService.markComplete(TutorialService.searchScreen);
          },
        );
      }
    });
  }
}
