import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class MushafTutorialKeys {
  static final topBar = GlobalKey();
  static final playButton = GlobalKey();
  static final bookmarkButton = GlobalKey();
  static final quranPage = GlobalKey();
  static final pageFooter = GlobalKey();
}

class MushafTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: MushafTutorialKeys.topBar,
        titleAr: 'شريط المصحف',
        titleEn: 'Mushaf Bar',
        descriptionAr: 'يعرض اسم السورة ورقم الجزء الحالي',
        descriptionEn:
            'Shows the current surah name and juz number',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: MushafTutorialKeys.playButton,
        titleAr: 'تشغيل الصفحة',
        titleEn: 'Play Page',
        descriptionAr: 'اضغط لتشغيل جميع آيات الصفحة الحالية بصوت القارئ',
        descriptionEn:
            'Tap to play all verses on the current page with selected reciter',
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
      ),
      TutorialStep(
        key: MushafTutorialKeys.bookmarkButton,
        titleAr: 'حفظ الصفحة',
        titleEn: 'Bookmark Page',
        descriptionAr: 'اضغط لحفظ إشارة مرجعية لهذه الصفحة والعودة إليها لاحقاً',
        descriptionEn:
            'Tap to bookmark this page and return to it later',
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
      ),
      TutorialStep(
        key: MushafTutorialKeys.quranPage,
        titleAr: 'صفحة المصحف',
        titleEn: 'Mushaf Page',
        descriptionAr:
            'اضغط على أي آية لسماعها، اضغط مطولاً لفتح التفسير والمشاركة والإشارة المرجعية',
        descriptionEn:
            'Tap any verse to listen, long-press for tafsir, sharing & bookmarks',
        align: ContentAlign.top,
      ),
      TutorialStep(
        key: MushafTutorialKeys.pageFooter,
        titleAr: 'تصفح المصحف',
        titleEn: 'Navigate Pages',
        descriptionAr: 'اسحب يميناً أو يساراً للتنقل بين صفحات المصحف',
        descriptionEn: 'Swipe left or right to navigate between pages',
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
    if (tutorialService.isTutorialComplete(TutorialService.mushafScreen)) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService.markComplete(TutorialService.mushafScreen);
          },
        );
      }
    });
  }
}
