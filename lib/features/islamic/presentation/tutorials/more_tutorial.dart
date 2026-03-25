import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class MoreTutorialKeys {
  static final prayerTimesCard = GlobalKey();
  static final adhkarCard = GlobalKey();
  static final tasbeehCard = GlobalKey();
  static final ruqyahCard = GlobalKey();
  static final duaaCard = GlobalKey();
  static final feedbackCard = GlobalKey();
}

class MoreTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: MoreTutorialKeys.prayerTimesCard,
        titleAr: 'مواقيت الصلاة',
        titleEn: 'Prayer Times',
        descriptionAr:
            'اعرض مواقيت الصلاة اليومية حسب موقعك الجغرافي',
        descriptionEn:
            'View daily prayer times based on your geographic location',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: MoreTutorialKeys.tasbeehCard,
        titleAr: 'السبحة الإلكترونية',
        titleEn: 'Digital Tasbeeh',
        descriptionAr:
            'عدّاد تسبيح رقمي: سبحان الله، الحمد لله، الله أكبر',
        descriptionEn:
            'Digital counter for SubhanAllah, Alhamdulillah, Allahu Akbar',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: MoreTutorialKeys.ruqyahCard,
        titleAr: 'الرقية الشرعية',
        titleEn: 'Ruqyah',
        descriptionAr:
            'استمع للرقية الشرعية بأصوات متعددة للعلاج والحماية',
        descriptionEn:
            'Listen to Islamic Ruqyah with multiple reciters for healing and protection',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: MoreTutorialKeys.feedbackCard,
        titleAr: 'الملاحظات والاقتراحات',
        titleEn: 'Feedback',
        descriptionAr:
            'أرسل ملاحظاتك واقتراحاتك لتحسين التطبيق',
        descriptionEn:
            'Send your feedback and suggestions to help improve the app',
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
        .isTutorialComplete(TutorialService.moreScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService.markComplete(TutorialService.moreScreen);
          },
        );
      }
    });
  }
}
