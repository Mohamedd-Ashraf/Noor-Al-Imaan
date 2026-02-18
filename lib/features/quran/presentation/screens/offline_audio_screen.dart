import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/audio_edition_service.dart';
import '../../../../core/services/offline_audio_service.dart';
import '../../../../core/audio/ayah_audio_cubit.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import 'select_download_screen.dart';

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
  Map<String, dynamic>? _downloadStats;
  Map<String, dynamic>? _allStorageStats;
  Map<String, dynamic>? _qualityStats;
  Map<String, dynamic>? _downloadPlan;
  Map<String, dynamic>? _fileBitrateStats;
  String? _confirmedDownloadPlanEdition;

  @override
  void initState() {
    super.initState();
    _service = di.sl<OfflineAudioService>();
    _audioEditionService = di.sl<AudioEditionService>();
    _audioEditionsFuture = _audioEditionService.getVerseByVerseAudioEditions();
    _loadDownloadStats();
  }

  Future<void> _loadDownloadStats() async {
    final stats = await _service.getDownloadStatistics();
    final allStats = await _service.getAllEditionsStorageStats();
    final qualityStats = await _service.assessCurrentEditionAudioQuality();
    final plan = await _service.inspectCurrentEditionDownloadPlan();
    final bitrateStats = await _service.analyzeCurrentEditionDownloadedBitrates(maxFiles: 600);
    if (mounted) {
      setState(() {
        _downloadStats = stats;
        _allStorageStats = allStats;
        _qualityStats = qualityStats;
        _downloadPlan = plan;
        _fileBitrateStats = bitrateStats;
      });
    }
  }

  Future<bool> _confirmDownloadPlanBeforeStart({
    required bool isArabicUi,
    required bool isSelective,
    int selectedSurahsCount = 0,
  }) async {
    final currentEdition = _service.edition;
    if (_confirmedDownloadPlanEdition == currentEdition) {
      return true;
    }

    final latestPlan = await _service.inspectCurrentEditionDownloadPlan();
    final sourceBitrate = _toInt(latestPlan['sourceBitrate']);
    final downloadBitrate = _toInt(latestPlan['downloadBitrate'], fallback: 64);

    if (!mounted) return false;

    final sourceLabel = sourceBitrate > 0
        ? '${sourceBitrate}kbps'
        : (isArabicUi ? 'غير معروف' : 'Unknown');

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isArabicUi ? 'تأكيد جودة التنزيل' : 'Confirm download quality',
        ),
        content: Text(
          isArabicUi
              ? 'القارئ: $currentEdition\nجودة المصدر من الخادم: $sourceLabel\nالجودة التي سيحمّلها التطبيق: ${downloadBitrate}kbps\n\n${isSelective ? 'سيتم تنزيل $selectedSurahsCount سورة محددة.' : 'سيتم تنزيل جميع السور.'}'
              : 'Reciter: $currentEdition\nSource bitrate from API: $sourceLabel\nBitrate that app will download: ${downloadBitrate}kbps\n\n${isSelective ? 'Will download $selectedSurahsCount selected surah(s).' : 'Will download all surahs.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabicUi ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabicUi ? 'متابعة' : 'Continue'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      _confirmedDownloadPlanEdition = currentEdition;
      return true;
    }
    return false;
  }

  Future<void> _cleanupOldEditions({required bool isArabicUi}) async {
    await _service.deleteOtherEditionsAudio();
    await _loadDownloadStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabicUi
              ? 'تم حذف ملفات القرّاء القديمة وتوفير مساحة.'
              : 'Old reciter files deleted and storage was freed.',
        ),
      ),
    );
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

  double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Widget _buildOrnamentedPanel({
    required Widget child,
    required ColorScheme scheme,
    bool highlighted = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final borderColor = highlighted
        ? AppColors.secondary.withValues(alpha: 0.7)
        : scheme.primary.withValues(alpha: 0.45);
    final innerBorderColor = highlighted
        ? AppColors.accent.withValues(alpha: 0.55)
        : scheme.outline.withValues(alpha: 0.45);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highlighted
              ? [
                  scheme.primaryContainer.withValues(alpha: 0.65),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.75),
                ]
              : [
                  scheme.surfaceContainer.withValues(alpha: 0.85),
                  scheme.surfaceContainerHigh.withValues(alpha: 0.85),
                ],
        ),
        border: Border.all(color: borderColor, width: 1.8),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: innerBorderColor, width: 1.2),
        ),
        child: Stack(
          children: [
            Positioned(top: 8, left: 8, child: Icon(Icons.diamond, size: 10, color: AppColors.secondary.withValues(alpha: 0.55))),
            Positioned(top: 8, right: 8, child: Icon(Icons.diamond, size: 10, color: AppColors.secondary.withValues(alpha: 0.55))),
            Positioned(bottom: 8, left: 8, child: Icon(Icons.diamond, size: 10, color: AppColors.secondary.withValues(alpha: 0.55))),
            Positioned(bottom: 8, right: 8, child: Icon(Icons.diamond, size: 10, color: AppColors.secondary.withValues(alpha: 0.55))),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    final isArabicUi = context.read<AppSettingsCubit>().state.appLanguageCode.toLowerCase().startsWith('ar');

    final canStart = await _confirmDownloadPlanBeforeStart(
      isArabicUi: isArabicUi,
      isSelective: false,
    );
    if (!canStart) return;

    setState(() {
      _isRunning = true;
      _cancelRequested = false;
      _error = null;
      _progress = null;
    });

    try {
      await _service.deleteOtherEditionsAudio();
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
    } finally {
      _loadDownloadStats(); // Refresh stats after download
    }
  }

  Future<void> _startSelectiveDownload() async {
    final isArabicUi = context.read<AppSettingsCubit>().state.appLanguageCode.toLowerCase().startsWith('ar');
    
    // Navigate to selection screen
    final selectedSurahs = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectDownloadScreen(),
      ),
    );

    if (selectedSurahs == null || selectedSurahs.isEmpty) return;

    final canStart = await _confirmDownloadPlanBeforeStart(
      isArabicUi: isArabicUi,
      isSelective: true,
      selectedSurahsCount: selectedSurahs.length,
    );
    if (!canStart) return;

    setState(() {
      _isRunning = true;
      _cancelRequested = false;
      _error = null;
      _progress = null;
    });

    try {
      await _service.deleteOtherEditionsAudio();
      await _service.downloadSurahs(
        surahNumbers: selectedSurahs,
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
          SnackBar(content: Text(isArabicUi ? 'اكتمل التنزيل' : 'Download completed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _error = isArabicUi
            ? 'فشل التنزيل. الرجاء التحقق من اتصال الإنترنت.'
            : 'Download failed. Please check your internet connection.';
      });
    } finally {
      _loadDownloadStats(); // Refresh stats after download
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsCubit>().state;
    final isArabicUi = settings.appLanguageCode.toLowerCase().startsWith('ar');
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _progress;
    final progressValue = (p == null || p.totalFiles == 0)
        ? null
        : (p.percentage / 100);
    final downloadedFiles = _toInt(_downloadStats?['downloadedFiles']);
    final downloadedSurahs = _toInt(_downloadStats?['downloadedSurahs']);
    final percentage = _toDouble(_downloadStats?['percentage']);
    final totalSizeMB = _toDouble(_downloadStats?['totalSizeMB']);
    // Real-world 64kbps verse-by-verse Quran size varies by reciter and pauses.
    final expectedFullSizeMB = 820.0;
    final expectedMinSizeMB = 700.0;
    final expectedMaxSizeMB = 900.0;
    final sizeProgressPercent = expectedFullSizeMB <= 0
      ? 0.0
      : ((totalSizeMB / expectedFullSizeMB) * 100).clamp(0.0, 100.0);
    final avgFileKB = downloadedFiles > 0
      ? (totalSizeMB * 1024) / downloadedFiles
      : 0.0;
    final otherEditionsSizeMB = _toDouble(_allStorageStats?['otherEditionsSizeMB']);
    final otherEditionsCount = _toInt(_allStorageStats?['otherEditionsCount']);
    final averageFileKB = _toDouble(_qualityStats?['averageFileKB']);
    final estimatedBitrate = (_qualityStats?['estimatedBitrate'] as String?) ?? 'unknown';
    final likelyHighBitrate = _qualityStats?['likelyHighBitrate'] == true;
    final currentEdition = (_downloadPlan?['edition'] as String?) ?? _service.edition;
    final sourceBitrate = _toInt(_downloadPlan?['sourceBitrate']);
    final plannedBitrate = _toInt(_downloadPlan?['downloadBitrate'], fallback: 64);
    final sourceBitrateLabel = sourceBitrate > 0
      ? '${sourceBitrate}kbps'
      : (isArabicUi ? 'غير معروف' : 'Unknown');
    final scannedFiles = _toInt(_fileBitrateStats?['scannedFiles']);
    final unknownBitrateFiles = _toInt(_fileBitrateStats?['unknownFiles']);
    final dominantDownloadedBitrate =
      (_fileBitrateStats?['dominantBitrate'] as String?) ?? 'unknown';
    final distribution =
      (_fileBitrateStats?['distribution'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
    final distributionText = distribution.entries
      .map((e) => '${e.key}: ${e.value}')
      .join(' | ');

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
        child: SingleChildScrollView(
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
                                    _confirmedDownloadPlanEdition = null;
                                  });

                                  await _loadDownloadStats();

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
            // Download Statistics
            if (_downloadStats != null)
              _buildOrnamentedPanel(
                scheme: scheme,
                highlighted: true,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: scheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isArabicUi ? 'إحصائيات التحميل' : 'Download Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.file_download,
                            value: '$downloadedFiles',
                            label: isArabicUi ? 'ملف' : 'Files',
                            percentage: percentage,
                            isArabicUi: isArabicUi,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.menu_book,
                            value: '$downloadedSurahs',
                            label: isArabicUi ? 'سورة' : 'Surahs',
                            percentage: (downloadedSurahs / 114) * 100,
                            isArabicUi: isArabicUi,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isArabicUi ? 'الحجم:' : 'Size:',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${totalSizeMB.toStringAsFixed(1)} MB',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isArabicUi
                            ? 'تقدّم الحجم: ${sizeProgressPercent.toStringAsFixed(1)}% من ~${expectedFullSizeMB.toStringAsFixed(0)}MB (النطاق الطبيعي ${expectedMinSizeMB.toStringAsFixed(0)}–${expectedMaxSizeMB.toStringAsFixed(0)}MB، متوسط الملف ${avgFileKB.toStringAsFixed(0)}KB)'
                            : 'Size progress: ${sizeProgressPercent.toStringAsFixed(1)}% of ~${expectedFullSizeMB.toStringAsFixed(0)}MB (normal range ${expectedMinSizeMB.toStringAsFixed(0)}-${expectedMaxSizeMB.toStringAsFixed(0)}MB, avg ${avgFileKB.toStringAsFixed(0)}KB/file)',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isArabicUi
                            ? 'تقدير الجودة الحالية: $estimatedBitrate (متوسط فعلي ${averageFileKB.toStringAsFixed(0)}KB/ملف)'
                            : 'Current quality estimate: $estimatedBitrate (actual avg ${averageFileKB.toStringAsFixed(0)}KB/file)',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (downloadedSurahs > 0) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showManageDownloadsDialog(isArabicUi),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(isArabicUi ? 'إدارة التحميلات' : 'Manage Downloads'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            side: BorderSide(color: scheme.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isRunning
                              ? null
                              : () async {
                                  final latestQuality =
                                      await _service.assessCurrentEditionAudioQuality();
                                  final isHigh = latestQuality['likelyHighBitrate'] == true;

                                  if (!isHigh) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isArabicUi
                                              ? 'الملفات الحالية تبدو محسّنة بالفعل (64kbps تقريبًا). لن يتم الحذف.'
                                              : 'Current files already look optimized (~64kbps). No deletion needed.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        isArabicUi
                                            ? 'إعادة بناء ملفات الصوت؟'
                                            : 'Rebuild audio files?',
                                      ),
                                      content: Text(
                                        isArabicUi
                                            ? 'سيتم حذف الملفات الحالية لهذا القارئ ثم إعادة تنزيلها بجودة 64kbps فقط لضمان أقل حجم.'
                                            : 'This will delete current files for this reciter, then re-download at 64kbps only for minimum size.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(isArabicUi ? 'إلغاء' : 'Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(isArabicUi ? 'متابعة' : 'Continue'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await _service.deleteAllAudio();
                                  await _loadDownloadStats();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isArabicUi
                                            ? 'تم حذف الملفات الحالية. ابدأ تنزيل جديد بضغط Download أو Select.'
                                            : 'Current files deleted. Start a fresh 64kbps download using Download or Select.',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.tune),
                          label: Text(
                            isArabicUi
                                ? 'ضمان أقل حجم (إعادة بناء 64kbps)'
                                : 'Ensure minimum size (rebuild 64kbps)',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (_allStorageStats != null && otherEditionsSizeMB > 1) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer.withValues(alpha: isDark ? 0.35 : 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.tertiary.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabicUi
                          ? 'ملفات قرّاء قديمة تستهلك مساحة'
                          : 'Old reciter files are using space',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabicUi
                          ? 'هناك $otherEditionsCount إصدار/قارئ قديم بحجم ${otherEditionsSizeMB.toStringAsFixed(0)} MB. يمكنك حذفها مع الإبقاء على القارئ الحالي فقط.'
                          : 'There are $otherEditionsCount old reciter edition(s) using ${otherEditionsSizeMB.toStringAsFixed(0)} MB. You can remove them and keep only the current reciter.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRunning
                            ? null
                            : () => _cleanupOldEditions(isArabicUi: isArabicUi),
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: Text(
                          isArabicUi
                              ? 'حذف ملفات القرّاء القديمة'
                              : 'Delete old reciter files',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.tertiary,
                          side: BorderSide(color: scheme.tertiary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: isDark ? 0.28 : 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabicUi ? 'خطة التحميل الحالية' : 'Current download plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabicUi
                        ? 'القارئ: $currentEdition\nجودة المصدر: $sourceBitrateLabel\nسيتم التحميل فعليًا: ${plannedBitrate}kbps'
                        : 'Reciter: $currentEdition\nSource bitrate: $sourceBitrateLabel\nActual download bitrate: ${plannedBitrate}kbps',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabicUi
                        ? 'فحص bitrate للملفات المحمّلة'
                        : 'Downloaded files bitrate check',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabicUi
                        ? 'Dominant: $dominantDownloadedBitrate | تم فحص $scannedFiles ملف | غير معروف: $unknownBitrateFiles'
                        : 'Dominant: $dominantDownloadedBitrate | Scanned: $scannedFiles files | Unknown: $unknownBitrateFiles',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                  if (distributionText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      distributionText,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Warning if files are too large (old 128kbps files)
            if (_downloadStats != null && likelyHighBitrate)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.error, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabicUi 
                                ? 'حجم ملفات كبير جداً!' 
                                : 'Files are too large!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabicUi
                          ? 'تم اكتشاف bitrate مرتفع في الملفات الحالية. الحجم الحالي ${totalSizeMB.toStringAsFixed(0)}MB ويبدو أعلى من النطاق الطبيعي لـ64kbps (${expectedMinSizeMB.toStringAsFixed(0)}–${expectedMaxSizeMB.toStringAsFixed(0)}MB).'
                          : 'High bitrate was detected in current files. Current size is ${totalSizeMB.toStringAsFixed(0)}MB and appears above typical 64kbps range (${expectedMinSizeMB.toStringAsFixed(0)}-${expectedMaxSizeMB.toStringAsFixed(0)}MB).',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isArabicUi ? 'حذف وإعادة تحميل؟' : 'Delete & Re-download?'),
                              content: Text(
                                isArabicUi
                                    ? 'سيتم حذف جميع الملفات القديمة وإعادة تحميلها بجودة 64kbps (65% أصغر). هل تريد المتابعة؟'
                                    : 'This will delete all old files and re-download them at 64kbps (65% smaller). Continue?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(isArabicUi ? 'إلغاء' : 'Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(isArabicUi ? 'نعم، احذف وأعد التحميل' : 'Yes, Delete & Re-download'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await _service.deleteAllAudio();
                            await _loadDownloadStats();
                            if (!mounted) return;
                            _start();
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(isArabicUi ? 'حذف وإعادة التحميل (64kbps)' : 'Delete & Re-download (64kbps)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_downloadStats != null && totalSizeMB > 500)
              const SizedBox(height: 16),
            _buildOrnamentedPanel(
              scheme: scheme,
              highlighted: false,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabicUi
                              ? 'تنزيل محسّن (64kbps - حجم أصغر)'
                              : 'Optimized Download (64kbps - Smaller Size)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabicUi
                    ? 'سيتم تنزيل 6236 ملف صوتي (64kbps). الحجم المعتاد يعتمد على القارئ ويكون غالبًا بين ${expectedMinSizeMB.toStringAsFixed(0)} و${expectedMaxSizeMB.toStringAsFixed(0)} ميجابايت.'
                    : 'Will download 6,236 audio files (64kbps). Typical total size depends on reciter and is often between ${expectedMinSizeMB.toStringAsFixed(0)} and ${expectedMaxSizeMB.toStringAsFixed(0)} MB.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabicUi
                        ? '${p.completedFiles} من ${p.totalFiles} ملف'
                        : '${p.completedFiles} of ${p.totalFiles} files',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${p.percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            // Download buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _start,
                        icon: const Icon(Icons.download),
                        label: Text(isArabicUi ? 'تنزيل الكل' : 'Download All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRunning ? null : _startSelectiveDownload,
                        icon: const Icon(Icons.playlist_add_check),
                        label: Text(isArabicUi ? 'اختيار' : 'Select'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
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
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required double percentage,
    required bool isArabicUi,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            scheme.surfaceContainerLowest,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: isDark ? 0.40 : 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageDownloadsDialog(bool isArabicUi) async {
    final downloadedSurahs = await _service.getDownloadedSurahs();
    if (downloadedSurahs.isEmpty) return;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _ManageDownloadsDialog(
        downloadedSurahs: downloadedSurahs,
        isArabicUi: isArabicUi,
        onDelete: (surahs) async {
          await _service.deleteSurahsAudio(surahs);
          await _loadDownloadStats();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabicUi
                    ? 'تم حذف ${surahs.length} سورة'
                    : 'Deleted ${surahs.length} surahs',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManageDownloadsDialog extends StatefulWidget {
  final List<int> downloadedSurahs;
  final bool isArabicUi;
  final Future<void> Function(List<int>) onDelete;

  const _ManageDownloadsDialog({
    required this.downloadedSurahs,
    required this.isArabicUi,
    required this.onDelete,
  });

  @override
  State<_ManageDownloadsDialog> createState() => _ManageDownloadsDialogState();
}

class _ManageDownloadsDialogState extends State<_ManageDownloadsDialog> {
  final Set<int> _selectedForDeletion = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isArabicUi ? 'إدارة التحميلات' : 'Manage Downloads'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text(widget.isArabicUi ? 'تحديد الكل' : 'Select All'),
              value: _selectAll,
              onChanged: (value) {
                setState(() {
                  _selectAll = value ?? false;
                  if (_selectAll) {
                    _selectedForDeletion.addAll(widget.downloadedSurahs);
                  } else {
                    _selectedForDeletion.clear();
                  }
                });
              },
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.downloadedSurahs.length,
                itemBuilder: (context, index) {
                  final surah = widget.downloadedSurahs[index];
                  final isSelected = _selectedForDeletion.contains(surah);
                  return CheckboxListTile(
                    title: Text(
                      widget.isArabicUi ? 'سورة $surah' : 'Surah $surah',
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedForDeletion.add(surah);
                        } else {
                          _selectedForDeletion.remove(surah);
                          _selectAll = false;
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isArabicUi ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: _selectedForDeletion.isEmpty
              ? null
              : () async {
                  Navigator.pop(context);
                  await widget.onDelete(_selectedForDeletion.toList());
                },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(
            widget.isArabicUi
                ? 'حذف (${_selectedForDeletion.length})'
                : 'Delete (${_selectedForDeletion.length})',
          ),
        ),
      ],
    );
  }
}

