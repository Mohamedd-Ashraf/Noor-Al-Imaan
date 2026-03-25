import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class SurahDetailTutorialKeys {
  static final ayahText = GlobalKey();
  static final translationToggle = GlobalKey();
  static final bookmarkButton = GlobalKey();
  static final audioPlayer = GlobalKey();
  static final mushafButton = GlobalKey();
  static final shareButton = GlobalKey();
}

class SurahDetailTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: SurahDetailTutorialKeys.ayahText,
        titleAr: 'نص الآيات',
        titleEn: 'Ayah Text',
        descriptionAr:
            'نص القرآن الكريم بالخط العثماني. اضغط مطولاً على أي آية لعرض التفسير',
        descriptionEn:
            'Quranic text in Uthmani script. Long-press any ayah to view its tafsir',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: SurahDetailTutorialKeys.mushafButton,
        titleAr: 'عرض المصحف',
        titleEn: 'Mushaf View',
        descriptionAr:
            'اعرض السورة بتصميم صفحات المصحف الشريف',
        descriptionEn:
            'View the surah in the traditional Mushaf page design',
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
      ),
      TutorialStep(
        key: SurahDetailTutorialKeys.bookmarkButton,
        titleAr: 'الإشارة المرجعية',
        titleEn: 'Bookmark',
        descriptionAr: 'احفظ مكان قراءتك للرجوع إليه لاحقاً',
        descriptionEn: 'Save your reading position to return to it later',
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.Circle,
      ),
      TutorialStep(
        key: SurahDetailTutorialKeys.audioPlayer,
        titleAr: 'مشغّل الصوت',
        titleEn: 'Audio Player',
        descriptionAr:
            'تحكم في تشغيل الآيات: تشغيل/إيقاف، التالي، السابق، وشريط التقدم',
        descriptionEn:
            'Control ayah playback: play/pause, next, previous, and seek bar',
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
        .isTutorialComplete(TutorialService.surahDetailScreen)) return;

    Future.delayed(const Duration(milliseconds: 700), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService
                .markComplete(TutorialService.surahDetailScreen);
          },
        );
      }
    });
  }
}
