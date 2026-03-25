import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_builder.dart';
import '../../../../core/services/tutorial_service.dart';

class BookmarksTutorialKeys {
  static final bookmarksList = GlobalKey();
  static final deleteButton = GlobalKey();
}

class BookmarksTutorial {
  static List<TutorialStep> steps() {
    return [
      TutorialStep(
        key: BookmarksTutorialKeys.bookmarksList,
        titleAr: 'قائمة الإشارات المرجعية',
        titleEn: 'Bookmarks List',
        descriptionAr:
            'هنا تظهر كل الآيات والصفحات اللي حفظتها. اضغط على أي إشارة للانتقال لمكانها في المصحف',
        descriptionEn:
            'All your saved ayahs and pages appear here. Tap any bookmark to jump to its location',
        align: ContentAlign.bottom,
      ),
      TutorialStep(
        key: BookmarksTutorialKeys.deleteButton,
        titleAr: 'حذف الإشارات',
        titleEn: 'Delete Bookmarks',
        descriptionAr:
            'اضغط للدخول في وضع التحديد واختر الإشارات اللي عايز تحذفها',
        descriptionEn:
            'Tap to enter selection mode and choose bookmarks to delete',
        align: ContentAlign.bottom,
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
        .isTutorialComplete(TutorialService.bookmarksScreen)) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        TutorialBuilder.show(
          context: context,
          steps: steps(),
          isArabic: isArabic,
          isDark: isDark,
          onFinish: () {
            tutorialService
                .markComplete(TutorialService.bookmarksScreen);
          },
        );
      }
    });
  }
}
