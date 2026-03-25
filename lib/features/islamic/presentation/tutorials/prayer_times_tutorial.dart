import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class PrayerTimesTutorialKeys {
  static final prayerList = GlobalKey();
  static final nextPrayer = GlobalKey();
  static final locationInfo = GlobalKey();
  static final calculationMethod = GlobalKey();
}

class PrayerTimesTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: PrayerTimesTutorialKeys.prayerList,
        titleAr: 'مواعيد الصلوات',
        titleEn: 'Prayer Schedule',
        descriptionAr:
            'قائمة بمواقيت الصلوات الخمس: الفجر، الظهر، العصر، المغرب، والعشاء',
        descriptionEn:
            'List of the five daily prayer times: Fajr, Dhuhr, Asr, Maghrib, and Isha',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: PrayerTimesTutorialKeys.locationInfo,
        titleAr: 'الموقع الجغرافي',
        titleEn: 'Location',
        descriptionAr:
            'مواقيت الصلاة محسوبة حسب موقعك. اضغط لتحديث الموقع',
        descriptionEn:
            'Prayer times are calculated based on your location. Tap to update location',
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
        .isTutorialComplete(TutorialService.prayerTimesScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService
                .markComplete(TutorialService.prayerTimesScreen);
          },
        );
      }
    });
  }
}
