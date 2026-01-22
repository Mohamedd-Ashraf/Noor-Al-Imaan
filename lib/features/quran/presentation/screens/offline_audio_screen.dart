import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/audio_edition_service.dart';
import '../../../../core/services/offline_audio_service.dart';
import '../../../../core/audio/ayah_audio_cubit.dart';
import '../../../../core/settings/app_settings_cubit.dart';

class OfflineAudioScreen extends StatefulWidget {
  const OfflineAudioScreen({super.key});

  @override
  State<OfflineAudioScreen> createState() => _OfflineAudioScreenState();
}

class _OfflineAudioScreenState extends State<OfflineAudioScreen> {
  late final OfflineAudioService _service;
  late final AudioEditionService _audioEditionService;
  late Future<List<AudioEdition>> _audioEditionsFuture;

  String _audioLanguageFilter = 'all';
  bool _didInitAudioLanguageFilter = false;

  bool _isRunning = false;
  bool _cancelRequested = false;
  OfflineAudioProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = di.sl<OfflineAudioService>();
    _audioEditionService = di.sl<AudioEditionService>();
    _audioEditionsFuture = _audioEditionService.getVerseByVerseAudioEditions();
  }

  void _refreshReciters() {
    setState(() {
      _audioEditionsFuture = _audioEditionService.getVerseByVerseAudioEditions();
    });
  }

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

  Future<void> _start() async {
    setState(() {
      _isRunning = true;
      _cancelRequested = false;
      _error = null;
      _progress = null;
    });

    final isArabicUi = context.read<AppSettingsCubit>().state.appLanguageCode.toLowerCase().startsWith('ar');

    try {
      await _service.downloadAllQuranAudio(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
          });
        },
        shouldCancel: () => _cancelRequested,
      );

      if (!mounted) return;
      setState(() {
        _isRunning = false;
      });

      if (_cancelRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabicUi ? 'تم إلغاء التنزيل' : 'Download cancelled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabicUi ? 'اكتمل تنزيل الصوت دون إنترنت' : 'Offline audio download completed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _error = isArabicUi
            ? 'فشل تنزيل الصوت. الرجاء التحقق من اتصال الإنترنت.'
            : 'Failed to download audio. Please check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    final isArabicUi = settings.appLanguageCode.toLowerCase().startsWith('ar');
    final p = _progress;
    final progressValue = (p == null || p.totalSurahs == 0)
        ? null
        : (p.currentSurah / p.totalSurahs);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicUi ? 'الصوت دون إنترنت' : 'Offline Audio'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isArabicUi ? 'تحديث القائمة' : 'Refresh list',
            onPressed: _isRunning ? null : _refreshReciters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<AudioEdition>>(
              future: _audioEditionsFuture,
              builder: (context, snap) {
                final all = (snap.data ?? const <AudioEdition>[]).toList();
                final selected = _service.edition;

                final selectedEdition = all.where((e) => e.identifier == selected).cast<AudioEdition?>().firstOrNull;
                if (!_didInitAudioLanguageFilter) {
                  final lang = selectedEdition?.language;
                  if (lang != null && lang.trim().isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (_didInitAudioLanguageFilter) return;
                      setState(() {
                        _audioLanguageFilter = lang.trim();
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

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabicUi ? 'القارئ' : 'Reciter',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isArabicUi
                              ? 'اختر اللغة ثم القارئ. سيتم استخدام نفس الاختيار للتنزيل والتشغيل.'
                              : 'Choose language then reciter. This selection is used for download and playback.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 12),
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
                          onChanged: _isRunning
                              ? null
                              : (value) {
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
                          onChanged: _isRunning
                              ? null
                              : (value) async {
                                  if (value == null || value.isEmpty) return;
                                  await _service.setEdition(value);
                                  if (!context.mounted) return;
                                  // Stop playback so it doesn't continue with the old reciter.
                                  try {
                                    context.read<AyahAudioCubit>().stop();
                                  } catch (_) {}

                                  // Sync language filter with selected reciter (if known).
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
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isArabicUi
                    ? 'سيتم تنزيل تلاوة آية بآية (الحالي: ${_service.edition}).\nقد يكون الحجم مئات الميغابايت وقد يستغرق وقتًا طويلًا.'
                    : 'This will download verse-by-verse recitation (current: ${_service.edition}).\n'
                        'It can be several hundred MB and may take a long time.',
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            const SizedBox(height: 12),
            if (p != null) ...[
              Text(
                isArabicUi
                    ? 'السورة ${p.currentSurah}/${p.totalSurahs}'
                    : 'Surah ${p.currentSurah}/${p.totalSurahs}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (p.totalAyahs > 0)
                Text(
                  isArabicUi
                      ? 'الآية ${p.currentAyah}/${p.totalAyahs}'
                      : 'Ayah ${p.currentAyah}/${p.totalAyahs}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Text(p.message),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRunning
                        ? () {
                            setState(() {
                              _cancelRequested = true;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.stop),
                    label: Text(isArabicUi ? 'إلغاء' : 'Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _start,
                    icon: const Icon(Icons.download),
                    label: Text(isArabicUi ? 'تنزيل' : 'Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isRunning
                    ? null
                    : () async {
                        await _service.deleteAllAudio();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isArabicUi ? 'تم حذف الصوت دون إنترنت' : 'Offline audio deleted')),
                        );
                      },
                icon: const Icon(Icons.delete_outline),
                label: Text(isArabicUi ? 'حذف الصوت المُنزّل' : 'Delete downloaded audio'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
