import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isArabicUi = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? 'بدء الاستخدام' : 'Onboarding'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              isArabicUi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isArabicUi
                  ? 'هذه صفحة تمهيدية (ستقوم أنت بتعديلها لاحقاً).'
                  : 'This is a placeholder onboarding screen (you will customize it later).',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 12),
            Text(
              isArabicUi
                  ? 'اضغط متابعة للانتقال للتطبيق.'
                  : 'Tap Continue to enter the app.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                child: Text(isArabicUi ? 'متابعة' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
