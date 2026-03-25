import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class SettingsTutorialKeys {
  static final languageSelector = GlobalKey();
  static final fontSizeSlider = GlobalKey();
  static final reciterSelector = GlobalKey();
  static final themeToggle = GlobalKey();
  static final replayTutorial = GlobalKey();
}

class SettingsTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: SettingsTutorialKeys.languageSelector,
        titleAr: 'تغيير اللغة',
        titleEn: 'Change Language',
        descriptionAr: 'غيّر لغة واجهة التطبيق بين العربية والإنجليزية ولغات أخرى',
        descriptionEn:
            'Switch the app language between Arabic, English, and other languages',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: SettingsTutorialKeys.fontSizeSlider,
        titleAr: 'حجم الخط',
        titleEn: 'Font Size',
        descriptionAr: 'تحكم في حجم خط القرآن والترجمة لراحة القراءة',
        descriptionEn:
            'Adjust the Quran and translation font size for comfortable reading',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: SettingsTutorialKeys.reciterSelector,
        titleAr: 'اختيار القارئ',
        titleEn: 'Select Reciter',
        descriptionAr: 'اختر القارئ المفضل لسماع تلاوة القرآن',
        descriptionEn: 'Choose your preferred reciter for Quran audio playback',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: SettingsTutorialKeys.replayTutorial,
        titleAr: 'إعادة الشرح',
        titleEn: 'Replay Tutorial',
        descriptionAr:
            'اضغط هنا لإعادة عرض الشرح التوضيحي لكل شاشات التطبيق',
        descriptionEn:
            'Tap here to replay the tutorial walkthrough for all app screens',
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
        .isTutorialComplete(TutorialService.settingsScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService
                .markComplete(TutorialService.settingsScreen);
          },
        );
      }
    });
  }
}
