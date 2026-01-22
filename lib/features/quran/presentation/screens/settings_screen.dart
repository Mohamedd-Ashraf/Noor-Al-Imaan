import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/offline_audio_service.dart';
import '../../../../core/services/audio_edition_service.dart';
import '../../../../core/audio/ayah_audio_cubit.dart';
import '../../../../core/services/adhan_notification_service.dart';
import 'offline_audio_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _arabicFontSizeDraft = 24.0;
  double _translationFontSizeDraft = 16.0;

  late final OfflineAudioService _offlineAudio;
  late final AudioEditionService _audioEditionService;
  late final AdhanNotificationService _adhanNotifications;
  late Future<List<AudioEdition>> _audioEditionsFuture;
  String _audioLanguageFilter = 'all';
  bool _didInitAudioLanguageFilter = false;

  String _languageLabel(String code, {required bool isArabicUi}) {
    switch (code.toLowerCase()) {
      case 'ar':
        return isArabicUi ? 'العربية' : 'Arabic';
      case 'en':
        return isArabicUi ? 'الإنجليزية' : 'English';
      case 'ur':
        return isArabicUi ? 'الأردية' : 'Urdu';
      case 'tr':
        return isArabicUi ? 'التركية' : 'Turkish';
      case 'fr':
        return isArabicUi ? 'الفرنسية' : 'French';
      case 'id':
        return isArabicUi ? 'الإندونيسية' : 'Indonesian';
      case 'fa':
        return isArabicUi ? 'الفارسية' : 'Persian';
      default:
        return code;
    }
  }

  @override
  void initState() {
    super.initState();
    _offlineAudio = di.sl<OfflineAudioService>();
    _audioEditionService = di.sl<AudioEditionService>();
    _adhanNotifications = di.sl<AdhanNotificationService>();
    _audioEditionsFuture = _audioEditionService.getVerseByVerseAudioEditions();
  }

  void _refreshReciters() {
    setState(() {
      _audioEditionsFuture = _audioEditionService.getVerseByVerseAudioEditions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    final isArabicUi = settings.appLanguageCode.toLowerCase().startsWith('ar');
    _arabicFontSizeDraft = settings.arabicFontSize;
    _translationFontSizeDraft = settings.translationFontSize;

    final prefs = di.sl<SettingsService>();
    final adhanEnabled = prefs.getAdhanNotificationsEnabled();
    final includeFajr = prefs.getAdhanIncludeFajr();
    final useCustomSound = prefs.getAdhanUseCustomSound();

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? 'الإعدادات' : 'Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Prayer Notifications
          _buildSectionHeader(isArabicUi ? 'تنبيهات الصلاة' : 'Prayer Notifications'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(isArabicUi ? 'تفعيل تنبيهات الأذان' : 'Enable Adhan Reminders'),
                  subtitle: Text(
                    isArabicUi
                        ? 'تنبيه عند دخول وقت الصلاة'
                        : 'Get a reminder when prayer time starts',
                  ),
                  value: adhanEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await _adhanNotifications.requestPermissions();
                      await prefs.setAdhanNotificationsEnabled(true);
                      if (!mounted) return;
                      await _adhanNotifications.ensureScheduled();
                    } else {
                      await _adhanNotifications.disable();
                    }
                    if (!mounted) return;
                    setState(() {});
                  },
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(isArabicUi ? 'أذان الفجر' : 'Fajr Adhan'),
                  subtitle: Text(
                    isArabicUi
                        ? 'تشغيل تنبيه الفجر'
                        : 'Include the Fajr reminder',
                  ),
                  value: includeFajr,
                  onChanged: adhanEnabled
                      ? (value) async {
                          await prefs.setAdhanIncludeFajr(value);
                          if (!mounted) return;
                          await _adhanNotifications.ensureScheduled();
                          if (!mounted) return;
                          setState(() {});
                        }
                      : null,
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(isArabicUi ? 'صوت أذان مخصص' : 'Custom Adhan Sound'),
                  subtitle: Text(
                    isArabicUi
                        ? 'يتطلب إضافة ملف صوت على Android/iOS (ثم إعادة ضبط القنوات)'
                        : 'Requires adding a sound file (Android/iOS) then resetting channels',
                  ),
                  value: useCustomSound,
                  onChanged: (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
                      ? null
                      : (value) async {
                          await prefs.setAdhanUseCustomSound(value);
                          if (value) {
                            if (!mounted) return;
                            await showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(isArabicUi ? 'ملاحظة' : 'Note'),
                                content: Text(
                                  isArabicUi
                                      ? 'لـ Android: أضف ملف adhan.mp3 داخل android/app/src/main/res/raw ثم اضغط "إعادة ضبط القنوات".\n\nلـ iOS: أضف adhan.caf داخل مشروع Runner (Copy Bundle Resources).\n\nتنبيه: لا يمكن للتطبيق فرض الصوت إذا تم تعطيله من إعدادات النظام لقناة الإشعارات.'
                                      : 'Android: add adhan.mp3 into android/app/src/main/res/raw then press “Reset channels”.\n\niOS: add adhan.caf to the Runner app bundle (Copy Bundle Resources).\n\nNote: the app cannot force sound if the user disabled the notification channel sound in system settings.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(isArabicUi ? 'حسناً' : 'OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (!mounted) return;
                          await _adhanNotifications.ensureScheduled();
                          if (!mounted) return;
                          setState(() {});
                        },
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _adhanNotifications.testNow();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabicUi ? 'تم إرسال إشعار تجريبي' : 'Test notification sent',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.volume_up_outlined),
                        label: Text(isArabicUi ? 'اختبار الآن' : 'Test now'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _adhanNotifications.scheduleTestIn(const Duration(seconds: 10));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabicUi
                                    ? 'سيظهر إشعار تجريبي بعد 10 ثوانٍ (جرّب إغلاق التطبيق)'
                                    : 'Test will fire in 10s (try closing the app)',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.timer_outlined),
                        label: Text(isArabicUi ? 'اختبار بعد 10 ثوانٍ' : 'Test in 10s'),
                      ),
                      OutlinedButton.icon(
                        onPressed: (defaultTargetPlatform == TargetPlatform.android)
                            ? () async {
                                await _adhanNotifications.recreateAndroidChannels();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabicUi
                                          ? 'تمت إعادة ضبط قنوات الإشعارات'
                                          : 'Notification channels reset',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.restart_alt),
                        label: Text(isArabicUi ? 'إعادة ضبط القنوات' : 'Reset channels'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _adhanNotifications.requestPermissions();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabicUi
                                    ? 'تم طلب الصلاحيات'
                                    : 'Permissions requested',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(isArabicUi ? 'طلب الصلاحيات' : 'Request permissions'),
                      ),
                      OutlinedButton.icon(
                        onPressed: adhanEnabled
                            ? () async {
                                await _adhanNotifications.ensureScheduled();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabicUi
                                          ? 'تمت إعادة جدولة التنبيهات'
                                          : 'Rescheduled reminders',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(isArabicUi ? 'إعادة الجدولة' : 'Reschedule'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Display Settings Section
          _buildSectionHeader(isArabicUi ? 'إعدادات العرض' : 'Display Settings'),
          const SizedBox(height: 12),

          // App Language
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabicUi ? 'لغة التطبيق' : 'App Language',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabicUi
                        ? 'اختر لغة واجهة التطبيق.'
                        : 'Choose the app UI language.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: isArabicUi ? 'ar' : 'en',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isArabicUi ? 'اللغة' : 'Language',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'en',
                        child: Text(isArabicUi ? 'الإنجليزية' : 'English'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'ar',
                        child: Text(isArabicUi ? 'العربية' : 'Arabic'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null || value.isEmpty) return;
                      await context.read<AppSettingsCubit>().setAppLanguage(value);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value == 'ar' ? 'تم تحديث لغة التطبيق' : 'App language updated'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Dark Mode Toggle
          Card(
            child: SwitchListTile(
              title: Text(isArabicUi ? 'الوضع الداكن' : 'Dark Mode'),
              subtitle: Text(isArabicUi ? 'استخدم الوضع الداكن' : 'Use dark theme'),
              value: settings.darkMode,
              onChanged: (value) {
                context.read<AppSettingsCubit>().setDarkMode(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabicUi
                          ? (value ? 'تم تفعيل الوضع الداكن' : 'تم إيقاف الوضع الداكن')
                          : (value ? 'Dark mode enabled' : 'Dark mode disabled'),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              activeColor: AppColors.primary,
            ),
          ),
          
          // Arabic Font Size
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabicUi ? 'حجم الخط العربي' : 'Arabic Font Size',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _arabicFontSizeDraft,
                          min: 18,
                          max: 36,
                          divisions: 18,
                          label: _arabicFontSizeDraft.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _arabicFontSizeDraft = value;
                            });
                          },
                          onChangeEnd: (value) {
                            context.read<AppSettingsCubit>().setArabicFontSize(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isArabicUi ? 'تم حفظ حجم الخط' : 'Font size saved'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${_arabicFontSizeDraft.round()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Preview Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _arabicFontSizeDraft,
                        color: AppColors.arabicText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Reading Settings Section
          _buildSectionHeader(isArabicUi ? 'إعدادات القراءة' : 'Reading Settings'),
          const SizedBox(height: 12),
          
          Card(
            child: SwitchListTile(
              title: Text(isArabicUi ? 'إظهار الترجمة' : 'Show Translation'),
              subtitle: Text(
                isArabicUi ? 'عرض الترجمة أسفل النص العربي' : 'Display English translation below Arabic text',
              ),
              value: settings.showTranslation,
              onChanged: (value) {
                context.read<AppSettingsCubit>().setShowTranslation(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabicUi
                          ? (value ? 'تم تفعيل الترجمة' : 'تم إيقاف الترجمة')
                          : (value ? 'Translation enabled' : 'Translation disabled'),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              activeColor: AppColors.primary,
            ),
          ),

          if (settings.showTranslation) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabicUi ? 'حجم خط الترجمة' : 'Translation Font Size',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _translationFontSizeDraft,
                            min: 12,
                            max: 24,
                            divisions: 12,
                            label: _translationFontSizeDraft.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                _translationFontSizeDraft = value;
                              });
                            },
                            onChangeEnd: (value) {
                              context.read<AppSettingsCubit>().setTranslationFontSize(value);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isArabicUi ? 'تم حفظ حجم خط الترجمة' : 'Translation font size saved'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${_translationFontSizeDraft.round()}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'In the name of Allah, the Most Gracious, the Most Merciful.',
                        style: TextStyle(
                          fontSize: _translationFontSizeDraft,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),

          // Offline Audio Section
          _buildSectionHeader(isArabicUi ? 'الصوت دون إنترنت (اختياري)' : 'Offline Audio (Optional)'),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: Text(isArabicUi ? 'تفعيل تنزيل الصوت دون إنترنت' : 'Enable Offline Audio Download'),
              subtitle: Text(isArabicUi ? 'تنزيل التلاوة وحفظها على الجهاز' : 'Optionally download recitation and save locally'),
              value: _offlineAudio.enabled,
              onChanged: (value) async {
                await _offlineAudio.setEnabled(value);
                if (!context.mounted) return;
                setState(() {});
              },
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isArabicUi ? 'القارئ' : 'Reciter',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: isArabicUi ? 'تحديث القائمة' : 'Refresh list',
                        onPressed: _refreshReciters,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabicUi
                        ? 'اختر إصدار الصوت (القارئ). يستخدم إصدارات الصوت آية بآية من AlQuran.cloud.'
                        : 'Choose the audio edition (reader). Uses AlQuran.cloud verse-by-verse audio editions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<AudioEdition>>(
                    future: _audioEditionsFuture,
                    builder: (context, snap) {
                      final all = (snap.data ?? const <AudioEdition>[]).toList();

                      // Ensure current selection is present even if offline/no cache.
                      final selected = _offlineAudio.edition;

                      final selectedEdition = all.where((e) => e.identifier == selected).cast<AudioEdition?>().firstOrNull;
                      if (!_didInitAudioLanguageFilter) {
                        final lang = selectedEdition?.language;
                        if (lang != null && lang.trim().isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (_didInitAudioLanguageFilter) return;
                            setState(() {
                              _audioLanguageFilter = lang;
                              _didInitAudioLanguageFilter = true;
                            });
                          });
                        } else {
                          _didInitAudioLanguageFilter = true;
                        }
                      }

                      final languageCodes = <String>{};
                      for (final e in all) {
                        final lang = e.language;
                        if (lang != null && lang.trim().isNotEmpty) {
                          languageCodes.add(lang.trim());
                        }
                      }
                      final languages = languageCodes.toList()..sort();

                      final filtered = (_audioLanguageFilter == 'all')
                          ? all
                          : all.where((e) => e.language == _audioLanguageFilter).toList();

                      final reciterItems = (filtered.isNotEmpty ? filtered : all).toList();
                      if (!reciterItems.any((e) => e.identifier == selected)) {
                        reciterItems.insert(0, AudioEdition(identifier: selected));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _audioLanguageFilter,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isArabicUi ? 'اللغة' : 'Language',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'all',
                                child: Text(isArabicUi ? 'كل اللغات' : 'All languages'),
                              ),
                              ...languages.map(
                                (code) => DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(_languageLabel(code, isArabicUi: isArabicUi)),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null || value.isEmpty) return;
                              setState(() {
                                _audioLanguageFilter = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selected,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isArabicUi ? 'القارئ' : 'Reciter',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: reciterItems
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e.identifier,
                                    child: Text(
                                      e.displayNameForAppLanguage(settings.appLanguageCode),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null || value.isEmpty) return;
                              await _offlineAudio.setEdition(value);
                              if (!context.mounted) return;
                              // Stop current playback so it doesn't continue with the old reciter.
                              try {
                                context.read<AyahAudioCubit>().stop();
                              } catch (_) {}

                              // If the chosen reciter has a language, update the language filter to match.
                              final chosen = all.where((e) => e.identifier == value).cast<AudioEdition?>().firstOrNull;
                              final chosenLang = chosen?.language;
                              setState(() {
                                if (chosenLang != null && chosenLang.trim().isNotEmpty) {
                                  _audioLanguageFilter = chosenLang.trim();
                                }
                              });

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isArabicUi ? 'تم تحديث القارئ' : 'Reciter updated'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_offlineAudio.enabled) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.download_for_offline,
                  color: AppColors.primary,
                ),
                title: const Text('Download Quran Audio'),
                subtitle: Text(isArabicUi ? 'تنزيل تلاوة آية بآية (حجم كبير)' : 'Downloads verse-by-verse recitation (large size)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OfflineAudioScreen()),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader(isArabicUi ? 'حول' : 'About'),
          const SizedBox(height: 12),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.primary),
                  title: Text(isArabicUi ? 'الإصدار' : 'Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.book, color: AppColors.primary),
                  title: Text(isArabicUi ? 'مصدر البيانات' : 'Data Source'),
                  subtitle: const Text('AlQuran.cloud API'),
                  onTap: () {
                    _showDataSourceDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.favorite, color: AppColors.secondary),
                  title: Text(isArabicUi ? 'قيّم التطبيق' : 'Rate This App'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabicUi ? 'شكرًا لدعمك!' : 'Thank you for your support!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }

  void _showDataSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.read<AppSettingsCubit>().state.appLanguageCode.toLowerCase().startsWith('ar')
            ? 'مصدر البيانات'
            : 'Data Source'),
        content: Text(
          context.read<AppSettingsCubit>().state.appLanguageCode.toLowerCase().startsWith('ar')
              ? 'يستخدم هذا التطبيق واجهة AlQuran.cloud لتوفير نص القرآن الكريم.\nتوفّر الواجهة الوصول إلى القرآن بعدة إصدارات ولغات.'
              : 'This app uses the AlQuran.cloud API to provide authentic Quranic text. '
                  'The API offers access to the Holy Quran in multiple editions and languages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.read<AppSettingsCubit>().state.appLanguageCode.toLowerCase().startsWith('ar') ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }
}
