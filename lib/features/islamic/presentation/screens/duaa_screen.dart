import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/app_settings_cubit.dart';

class DuaaScreen extends StatelessWidget {
  const DuaaScreen({super.key});

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
        title: Text(isArabicUi ? 'الأدعية' : 'Duaa'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          isArabicUi
              ? 'صفحة الأدعية (مكان مخصص لك لإضافة الأدعية لاحقاً).'
              : 'Duaa page placeholder (add your duaas here later).',
          textAlign: isArabicUi ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
