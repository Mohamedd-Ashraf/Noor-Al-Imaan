import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/adhan_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/app_settings_cubit.dart';
import 'core/audio/ayah_audio_cubit.dart';
import 'core/widgets/onboarding_gate.dart';
import 'features/quran/presentation/bloc/surah/surah_bloc.dart';
import 'features/quran/presentation/bloc/ayah/ayah_bloc.dart';
import 'package:quran_controller/quran_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Notifications are used for prayer reminders (adhan). Initialize early.
  final adhanService = di.sl<AdhanNotificationService>();
  await adhanService.init();

  // Best-effort: ask for notification + exact alarm permission up-front.
  // Scheduling will no-op if permissions are denied.
  unawaited(adhanService.requestPermissions());

  // Schedule upcoming prayer reminders (uses cached location/times when available).
  unawaited(adhanService.ensureScheduled());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SurahBloc>()),
        BlocProvider(create: (_) => di.sl<AyahBloc>()),
        BlocProvider(create: (_) => di.sl<AyahAudioCubit>()),
        BlocProvider(create: (_) => AppSettingsCubit(di.sl())),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          final locale = Locale(settings.appLanguageCode);
          final isArabicUi = settings.appLanguageCode.toLowerCase().startsWith(
            'ar',
          );
          return MaterialApp(
            title: 'Quran App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(isArabicUi: isArabicUi),
            darkTheme: AppTheme.darkTheme(isArabicUi: isArabicUi),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const OnboardingGate(),
          );
        },
      ),
    );
  }
}