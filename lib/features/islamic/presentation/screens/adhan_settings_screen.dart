import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/adhan_sounds.dart';
import '../../../../core/constants/prayer_calculation_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/adhan_notification_service.dart';
import '../../../../core/settings/app_settings_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cache state for each online sound
// ─────────────────────────────────────────────────────────────────────────────
enum _CacheState { none, caching, cached, error }

// ─────────────────────────────────────────────────────────────────────────────

class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key});
  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen>
    with WidgetsBindingObserver {
  static const MethodChannel _adhanChannel = MethodChannel('quraan/adhan_player');

  late final SettingsService _settings;
  late final AdhanNotificationService _adhanService;

  // ── Core settings ──────────────────────────────────────────────────────
  String _selectedSoundId = AdhanSounds.defaultId;
  String _selectedMethodId = 'egyptian';
  String _selectedAsrMethod = 'standard';
  bool _notificationsEnabled = true;
  bool _includeFajr = true;
  bool _methodAutoDetected = true;
  double _adhanVolume = 1.0;

  // ── New settings ───────────────────────────────────────────────────────
  bool _shortMode = false;
  bool _reminderEnabled = false;
  int _reminderMinutes = 10;
  bool _iqamaEnabled = false;
  int _iqamaMinutes = 15;
  bool _salawatEnabled = false;
  int _salawatMinutes = 30;

  // ── Audio stream setting ───────────────────────────────────────────────
  /// 'ringtone' → ring stream (default). 'alarm' → bypasses silent mode.
  String _adhanAudioStream = 'ringtone';

  // ── System alarm info ──────────────────────────────────────────────────
  int _systemAlarmCurrent = -1;
  int _systemAlarmMax = 15;

  // ── Preview state ──────────────────────────────────────────────────────
  bool _isPreviewPlaying = false;
  String? _previewingId;
  AudioPlayer? _onlinePlayer;
  Timer? _shortModeTimer;

  // ── Per-sound cache state ──────────────────────────────────────────────
  final Map<String, _CacheState> _cacheState = {};
  final Map<String, double> _cacheProgress = {};

  // ── UI flags ───────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isTesting = false;
  bool _schedulingTest = false;
  bool _batteryUnrestricted = false;
  Timer? _debounce;
  /// Show the "جديد / New" badge next to Short Adhan only for version 1.0.7.
  bool _showNewBadge = false;

  // ═══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = di.sl<SettingsService>();
    _adhanService = di.sl<AdhanNotificationService>();
    _load();
    _checkBatteryStatus();
    _fetchAlarmVolume();
    _checkCachedOnlineSounds();
    _adhanChannel.setMethodCallHandler(_handleNativeCallback);
    // Show the "جديد" badge only for version 1.0.7
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _showNewBadge = info.version == '1.0.7');
      }
    });
  }

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'previewCompleted' && mounted) {
      setState(() {
        _isPreviewPlaying = false;
        _previewingId = null;
      });
    }
  }

  void _load() {
    setState(() {
      _selectedSoundId = _settings.getSelectedAdhanSound();
      _selectedMethodId = _settings.getPrayerCalculationMethod();
      _selectedAsrMethod = _settings.getPrayerAsrMethod();
      _notificationsEnabled = _settings.getAdhanNotificationsEnabled();
      _includeFajr = _settings.getAdhanIncludeFajr();
      _methodAutoDetected = _settings.getPrayerMethodAutoDetected();
      _adhanVolume = _settings.getAdhanVolume();
      _shortMode = _settings.getAdhanShortMode();
      _reminderEnabled = _settings.getPrayerReminderEnabled();
      _reminderMinutes = _settings.getPrayerReminderMinutes();
      _iqamaEnabled = _settings.getIqamaEnabled();
      _iqamaMinutes = _settings.getIqamaMinutes();
      _salawatEnabled = _settings.getSalawatEnabled();
      _salawatMinutes = _settings.getSalawatMinutes();
      _adhanAudioStream = _settings.getAdhanAudioStream();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _checkBatteryStatus();
      _fetchAlarmVolume();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _shortModeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _adhanChannel.setMethodCallHandler(null);
    _stopPreview();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Native / System helpers
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _fetchAlarmVolume() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      // Returns a map with int 'current', int 'max', and String 'streamType'.
      final res = await _adhanChannel.invokeMethod<Object>('getAlarmVolume');
      if (res is Map && mounted) {
        setState(() {
          _systemAlarmCurrent = (res['current'] as int?) ?? -1;
          _systemAlarmMax     = (res['max'] as int?) ?? 15;
        });
      }
    } catch (_) {}
  }

  Future<void> _openSoundSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _adhanChannel.invokeMethod('openSoundSettings');
    } catch (_) {}
  }

  Future<void> _checkBatteryStatus() async {
    if (defaultTargetPlatform != TargetPlatform.android || kIsWeb) {
      if (mounted) setState(() => _batteryUnrestricted = true);
      return;
    }
    try {
      final disabled = await _adhanChannel
              .invokeMethod<bool>('isBatteryOptimizationDisabled') ??
          false;
      if (mounted) setState(() => _batteryUnrestricted = disabled);
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Online sound cache helpers
  // ═══════════════════════════════════════════════════════════════════════

  Future<Directory> _cacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/adhan_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<File> _cachedFile(AdhanSoundInfo sound) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${sound.id}.mp3');
  }

  Future<void> _checkCachedOnlineSounds() async {
    for (final s in AdhanSounds.online) {
      try {
        final f = await _cachedFile(s);
        if (f.existsSync() && f.lengthSync() > 1024) {
          if (mounted) setState(() => _cacheState[s.id] = _CacheState.cached);
        }
      } catch (_) {}
    }
  }

  /// Fetches and caches an online sound silently in the background.
  /// Called automatically when the user selects an online sound.
  Future<void> _cacheOnlineSound(AdhanSoundInfo sound) async {
    if (sound.url == null) return;
    if (_cacheState[sound.id] == _CacheState.caching) return;
    if (_cacheState[sound.id] == _CacheState.cached) return;

    if (mounted) {
      setState(() {
        _cacheState[sound.id] = _CacheState.caching;
        _cacheProgress[sound.id] = 0.0;
      });
    }

    try {
      final file = await _cachedFile(sound);
      final request = http.Request('GET', Uri.parse(sound.url!));
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && mounted) {
          setState(() => _cacheProgress[sound.id] = received / total);
        }
      }
      await sink.close();
      if (mounted) {
        setState(() {
          _cacheState[sound.id] = _CacheState.cached;
          _cacheProgress[sound.id] = 1.0;
        });
      }
    } catch (e) {
      debugPrint('[AdhanCache] Error: $e');
      if (mounted) {
        setState(() => _cacheState[sound.id] = _CacheState.error);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Preview
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _previewSound(AdhanSoundInfo sound) async {
    if (_isPreviewPlaying) {
      await _stopPreview();
      if (_previewingId == sound.id) return;
    }

    setState(() {
      _isPreviewPlaying = true;
      _previewingId = sound.id;
    });

    try {
      if (sound.isOnline) {
        _onlinePlayer = AudioPlayer();
        final state = _cacheState[sound.id];
        if (state == _CacheState.cached) {
          final f = await _cachedFile(sound);
          await _onlinePlayer!.setFilePath(f.path);
        } else if (sound.url != null) {
          await _onlinePlayer!.setUrl(sound.url!);
        } else {
          throw Exception('No URL available');
        }
        // Apply clip BEFORE play — position-based, works for both cached files
        // and streaming URLs regardless of buffer state.
        if (_shortMode) {
          await _onlinePlayer!.setClip(
            end: Duration(seconds: sound.shortDurationSeconds),
          );
        }
        _onlinePlayer!.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed && mounted) {
            setState(() {
              _isPreviewPlaying = false;
              _previewingId = null;
            });
          }
        });
        await _onlinePlayer!.play();
      } else {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          // Native prepare() is synchronous — invokeMethod returns only after
          // player.start() has been called, so a Dart timer here tracks audio
          // position accurately without any init-overhead offset.
          await _adhanChannel.invokeMethod(
            'playAdhan',
            {
              'soundName': sound.id,
              'volume': _adhanVolume,
            },
          );
          if (_shortMode && mounted) {
            _shortModeTimer?.cancel();
            _shortModeTimer = Timer(
              Duration(seconds: sound.shortDurationSeconds),
              () => _stopPreview(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Preview error: $e');
      if (mounted) {
        setState(() {
          _isPreviewPlaying = false;
          _previewingId = null;
        });
        _showSnack(
          _isAr ? 'تعذّر تشغيل الأذان' : 'Could not play adhan',
          Colors.red,
        );
      }
    }
  }

  Future<void> _stopPreview() async {
    _shortModeTimer?.cancel();
    _shortModeTimer = null;
    try {
      await _onlinePlayer?.stop();
      await _onlinePlayer?.dispose();
      _onlinePlayer = null;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _adhanChannel.invokeMethod('stopAdhan');
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isPreviewPlaying = false;
        _previewingId = null;
      });
    }
  }

  void _selectSound(AdhanSoundInfo sound) {
    setState(() => _selectedSoundId = sound.id);
    HapticFeedback.selectionClick();
    _autoSave();
    if (sound.isOnline) _cacheOnlineSound(sound); // auto-cache in background
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Save
  // ═══════════════════════════════════════════════════════════════════════

  void _autoSave({Duration delay = const Duration(milliseconds: 600)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, _save);
  }

  Future<void> _save() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    await Future.wait([
      _settings.setSelectedAdhanSound(_selectedSoundId),
      _settings.setPrayerCalculationMethod(_selectedMethodId),
      _settings.setPrayerAsrMethod(_selectedAsrMethod),
      _settings.setAdhanIncludeFajr(_includeFajr),
      _settings.setAdhanVolume(_adhanVolume),
      _settings.setPrayerMethodAutoDetected(_methodAutoDetected),
      _settings.setAdhanShortMode(_shortMode),
      _settings.setPrayerReminderEnabled(_reminderEnabled),
      _settings.setPrayerReminderMinutes(_reminderMinutes),
      _settings.setIqamaEnabled(_iqamaEnabled),
      _settings.setIqamaMinutes(_iqamaMinutes),
      _settings.setSalawatEnabled(_salawatEnabled),
      _settings.setSalawatMinutes(_salawatMinutes),
      _settings.setAdhanAudioStream(_adhanAudioStream),
    ]);
    if (_notificationsEnabled) {
      await _adhanService.enableAndSchedule();
    } else {
      await _adhanService.disable();
    }
    if (mounted) setState(() => _isSaving = false);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════

  bool get _isAr {
    try {
      return context
          .read<AppSettingsCubit>()
          .state
          .appLanguageCode
          .toLowerCase()
          .startsWith('ar');
    } catch (_) {
      return false;
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isAr),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Disabled banner
                if (!_notificationsEnabled) ...[
                  const SizedBox(height: 16),
                  _DisabledBanner(isAr: isAr),
                ],

                // Battery warning (prominent, at top)
                if (!_batteryUnrestricted) ...[
                  const SizedBox(height: 16),
                  _BatteryWarningCard(
                    isAr: isAr,
                    onTap: () async {
                      try {
                        await _adhanChannel.invokeMethod('openBatterySettings');
                        // Re-check status after user returns
                        await Future.delayed(const Duration(seconds: 1));
                        _checkBatteryStatus();
                      } catch (_) {}
                    },
                  ),
                ],
                const SizedBox(height: 20),

                // 1. Notifications & toggles
                _buildSection(
                  icon: Icons.notifications_active_rounded,
                  titleAr: 'الأذان والإشعارات',
                  titleEn: 'Adhan & Notifications',
                  isAr: isAr,
                  children: [
                    _buildSwitchRow(
                      icon: _notificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      iconColor: _notificationsEnabled ? AppColors.primary : Colors.grey,
                      titleAr: 'تفعيل الأذان',
                      titleEn: 'Enable Adhan',
                      subtitleAr: 'تشغيل الأذان تلقائياً عند كل وقت صلاة',
                      subtitleEn: 'Auto-play adhan at each prayer time',
                      value: _notificationsEnabled,
                      onChanged: (v) {
                        setState(() => _notificationsEnabled = v);
                        _autoSave();
                      },
                      isAr: isAr,
                    ),
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: Icons.wb_twilight_rounded,
                      iconColor: _includeFajr ? AppColors.primary : Colors.grey,
                      titleAr: 'تضمين أذان الفجر',
                      titleEn: 'Include Fajr Adhan',
                      subtitleAr: 'أذان الفجر مختلف — قد تريد تعطيله ليلاً',
                      subtitleEn: 'Fajr differs — disable at night if needed',
                      value: _includeFajr,
                      onChanged: _notificationsEnabled
                          ? (v) {
                              setState(() => _includeFajr = v);
                              _autoSave();
                            }
                          : null,
                      isAr: isAr,
                    ),
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: Icons.compress_rounded,
                      iconColor: _shortMode ? AppColors.secondary : Colors.grey,
                      titleAr: 'الأذان المختصر',
                      titleEn: 'Short Adhan (2 Takbeers)',
                      subtitleAr: 'تكبيرتان فقط بدلاً من الأذان الكامل',
                      subtitleEn: 'Only two Takbeers instead of the full Adhan',
                      value: _shortMode,
                      onChanged: _notificationsEnabled
                          ? (v) {
                              setState(() => _shortMode = v);
                              _autoSave();
                            }
                          : null,
                      isAr: isAr,
                      badge: _showNewBadge ? (isAr ? 'جديد' : 'New') : null,
                    ),
                    if (_shortMode) ...[              _buildDivider(),
                      _buildShortModeExplanation(isAr),
                    ],
                    _buildDivider(),
                    _buildStreamPickerRow(isAr),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. صوت الأذان — pick first, then adjust volume
                _buildSoundSection(isAr),
                const SizedBox(height: 16),

                // 3. مستوى الصوت
                _buildSection(
                  icon: Icons.volume_up_rounded,
                  titleAr: 'مستوى الصوت',
                  titleEn: 'Volume',
                  isAr: isAr,
                  children: [_buildVolumeCard(isAr)],
                ),
                const SizedBox(height: 16),

                // 4. التذكيرات
                _buildSection(
                  icon: Icons.alarm_rounded,
                  titleAr: 'التذكيرات',
                  titleEn: 'Reminders',
                  isAr: isAr,
                  children: [
                    _buildSwitchRow(
                      icon: Icons.timer_rounded,
                      iconColor: _reminderEnabled ? Colors.orange : Colors.grey,
                      titleAr: 'تذكير قبل موعد الصلاة',
                      titleEn: 'Pre-Prayer Reminder',
                      subtitleAr: 'تنبيه قبل وقت الصلاة بعدة دقائق',
                      subtitleEn: 'Notify you a few minutes before prayer time',
                      value: _reminderEnabled,
                      onChanged: _notificationsEnabled
                          ? (v) {
                              setState(() => _reminderEnabled = v);
                              _autoSave();
                            }
                          : null,
                      isAr: isAr,
                    ),
                    if (_reminderEnabled) ...[
                      _buildDivider(),
                      _buildMinutesPicker(
                        icon: Icons.timer_outlined,
                        labelAr: 'وقت التذكير قبل الصلاة',
                        labelEn: 'Reminder before prayer',
                        value: _reminderMinutes,
                        options: const [5, 10, 15, 20, 30],
                        isAr: isAr,
                        onChanged: (v) {
                          setState(() => _reminderMinutes = v);
                          _autoSave();
                        },
                      ),
                    ],
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: Icons.access_alarm_rounded,
                      iconColor: _iqamaEnabled ? Colors.teal : Colors.grey,
                      titleAr: 'تنبيه وقت الإقامة',
                      titleEn: 'Iqama Notification',
                      subtitleAr: 'تنبيه عند موعد إقامة الصلاة',
                      subtitleEn: 'Alert when it\'s time to start the prayer',
                      value: _iqamaEnabled,
                      onChanged: _notificationsEnabled
                          ? (v) {
                              setState(() => _iqamaEnabled = v);
                              _autoSave();
                            }
                          : null,
                      isAr: isAr,
                    ),
                    if (_iqamaEnabled) ...[
                      _buildDivider(),
                      _buildMinutesPicker(
                        icon: Icons.hourglass_bottom_rounded,
                        labelAr: 'الإقامة بعد الأذان بـ',
                        labelEn: 'Iqama after Adhan by',
                        value: _iqamaMinutes,
                        options: const [5, 10, 15, 20, 25, 30],
                        isAr: isAr,
                        onChanged: (v) {
                          setState(() => _iqamaMinutes = v);
                          _autoSave();
                        },
                      ),
                    ],
                    _buildDivider(),
                    _buildSwitchRow(
                      icon: Icons.favorite_rounded,
                      iconColor: _salawatEnabled ? Colors.pink : Colors.grey,
                      titleAr: 'الصلاة على النبي ﷺ',
                      titleEn: 'Salawat / Durood Reminder',
                      subtitleAr: 'اللهم صلِّ وسلم وبارك على نبينا محمد ﷺ',
                      subtitleEn: 'Reminder to send blessings on the Prophet ﷺ',
                      value: _salawatEnabled,
                      onChanged: (v) {
                        setState(() => _salawatEnabled = v);
                        _autoSave();
                      },
                      isAr: isAr,
                    ),
                    if (_salawatEnabled) ...[
                      _buildDivider(),
                      _buildMinutesPicker(
                        icon: Icons.schedule_rounded,
                        labelAr: 'كل كم دقيقة؟',
                        labelEn: 'Every (minutes)',
                        value: _salawatMinutes,
                        options: const [15, 30, 60, 120],
                        isAr: isAr,
                        onChanged: (v) {
                          setState(() => _salawatMinutes = v);
                          _autoSave();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Prayer calculation method
                _buildSection(
                  icon: Icons.calculate_rounded,
                  titleAr: 'طريقة حساب المواقيت',
                  titleEn: 'Prayer Calculation Method',
                  isAr: isAr,
                  children: [_buildMethodCard(isAr)],
                ),
                const SizedBox(height: 16),

                // 6. Schedule
                _buildSection(
                  icon: Icons.calendar_month_rounded,
                  titleAr: 'جدول الأذان',
                  titleEn: 'Adhan Schedule',
                  isAr: isAr,
                  children: [_buildScheduleCard(isAr)],
                ),
                const SizedBox(height: 16),

                // 7. Test
                _buildSection(
                  icon: Icons.science_rounded,
                  titleAr: 'اختبار الأذان',
                  titleEn: 'Test Adhan',
                  isAr: isAr,
                  children: [_buildTestCard(isAr)],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(bool isAr) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Positioned(
              //   right: -30, top: -30,
              //   child: Container(width: 160, height: 160,
              //     decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06))),
              // ),
              // Positioned(
              //   right: 40, top: 60,
              //   child: Container(width: 80, height: 80,
              //     decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withValues(alpha: 0.15))),
              // ),
              // Positioned(
              //   left: -20, bottom: -20,
              //   child: Container(width: 100, height: 100,
              //     decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),
              // ),
              // ── Basmala watermark overlay ─────────────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.06,
                    child: Center(
                      child: Text(
                        '﷽',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 90,
                          fontFamily: 'Scheherazade',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          // Expanded(
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         isAr ? 'إعدادات الأذان والصلاة' : 'Adhan & Prayer Settings',
                          //         style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          //       ),
                          //       const SizedBox(height: 3),
                          //       Text(
                          //         isAr ? 'خصّص تجربة الأذان والإشعارات' : 'Customize your adhan experience',
                          //         style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          isAr ? 'الأذان والصلاة' : 'Adhan & Prayer',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Tooltip(
              message: isAr ? 'الحفظ تلقائي' : 'Auto-saved',
              child: const Icon(Icons.cloud_done_rounded, color: Colors.white70, size: 22),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Section builder
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required IconData icon,
    required String titleAr,
    required String titleEn,
    required bool isAr,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                isAr ? titleAr : titleEn,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => const Divider(
        height: 1, thickness: 1, color: AppColors.cardBorder, indent: 16, endIndent: 16);

  // ─── Switch row ──────────────────────────────────────────────────────────

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String titleAr,
    required String titleEn,
    required String subtitleAr,
    required String subtitleEn,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required bool isAr,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isAr ? titleAr : titleEn,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: onChanged == null ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFF4D03F)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(badge, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(isAr ? subtitleAr : subtitleEn,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }

  // ─── Minutes picker ──────────────────────────────────────────────────────

  Widget _buildMinutesPicker({
    required IconData icon,
    required String labelAr,
    required String labelEn,
    required int value,
    required List<int> options,
    required bool isAr,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(isAr ? labelAr : labelEn,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: options.map((opt) {
              final selected = opt == value;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.cardBorder),
                  ),
                  child: Text(
                    isAr ? '$opt د' : '${opt}m',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.primary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Volume card ─────────────────────────────────────────────────────────

  Widget _buildVolumeCard(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        children: [
          Row(children: [
            Icon(
              _adhanVolume == 0 ? Icons.volume_off_rounded : _adhanVolume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded,
              color: _notificationsEnabled ? AppColors.primary : Colors.grey, size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(isAr ? 'مستوى صوت الأذان' : 'Adhan Volume',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: _notificationsEnabled
                    ? const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd])
                    : null,
                color: _notificationsEnabled ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${(_adhanVolume * 100).round()}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: _notificationsEnabled ? Colors.white : AppColors.textSecondary)),
            ),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 5,
            ),
            child: Slider(
              value: _adhanVolume, min: 0.0, max: 1.0, divisions: 10,
              onChanged: _notificationsEnabled ? (v) => setState(() => _adhanVolume = v) : null,
              onChangeEnd: _notificationsEnabled
                  ? (_) => _autoSave(delay: const Duration(milliseconds: 800)) : null,
            ),
          ),
          if (_systemAlarmCurrent >= 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text.rich(TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: isAr
                          ? (_adhanAudioStream == 'alarm' ? 'صوت المنبهات في الجهاز: ' : 'صوت الرنين في الجهاز: ')
                          : (_adhanAudioStream == 'alarm' ? 'System alarm volume: ' : 'System ring volume: '),
                    ),
                    TextSpan(text: '$_systemAlarmCurrent / $_systemAlarmMax',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ))),
                GestureDetector(
                  onTap: _openSoundSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(isAr ? 'تعديل' : 'Adjust',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Audio stream picker row ───────────────────────────────────────────────────────

  Widget _buildStreamPickerRow(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.deepPurple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isAr ? 'نوع تدفّق الصوت' : 'Audio Stream Type',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 3),
            Text(
              isAr ? 'رنين: يكتم في الصامت • منبه: يتجاوز وضع الصامت' : 'Ring: muted in silent • Alarm: bypasses silent mode',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildStreamChip(
            isAr: isAr, icon: Icons.ring_volume_rounded,
            labelAr: 'رنين 🔔', labelEn: 'Ring 🔔',
            selected: _adhanAudioStream == 'ringtone',
            onTap: () async {
              if (_adhanAudioStream == 'ringtone') return;
              setState(() => _adhanAudioStream = 'ringtone');
              await _settings.setAdhanAudioStream('ringtone');
              _fetchAlarmVolume(); _autoSave();
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildStreamChip(
            isAr: isAr, icon: Icons.alarm_rounded,
            labelAr: 'منبه ⏰', labelEn: 'Alarm ⏰',
            selected: _adhanAudioStream == 'alarm',
            onTap: () async {
              if (_adhanAudioStream == 'alarm') return;
              setState(() => _adhanAudioStream = 'alarm');
              await _settings.setAdhanAudioStream('alarm');
              _fetchAlarmVolume(); _autoSave();
            },
          )),
        ]),
      ]),
    );
  }

  Widget _buildStreamChip({
    required bool isAr, required IconData icon,
    required String labelAr, required String labelEn,
    required bool selected, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: selected ? Colors.white : AppColors.primary),
          const SizedBox(width: 7),
          Text(
            isAr ? labelAr : labelEn,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Short Adhan explanation ──────────────────────────────────────────────

  Widget _buildShortModeExplanation(bool isAr) {
    final sound = AdhanSounds.findById(_selectedSoundId);
    final seconds = sound.shortDurationSeconds;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              isAr ? 'كيف يعمل الأذان المختصر؟' : 'How does Short Adhan work?',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ]),
          const SizedBox(height: 12),
          // Step-by-step explanation
          _ShortModeStep(
            number: '١',
            isAr: isAr,
            ar: 'يبدأ الأذان بـ "الله أكبر" أربع مرات',
            en: 'Adhan starts with 4 Takbeers: "Allahu Akbar"',
          ),
          _ShortModeStep(
            number: '٢',
            isAr: isAr,
            ar: 'التطبيق يوقف الصوت بعد التكبيرتين الأوليين (~$seconds ثانية)',
            en: 'App stops after the first 2 Takbeers (~$seconds seconds)',
          ),
          _ShortModeStep(
            number: '٣',
            isAr: isAr,
            ar: 'نتيجة: تنبيه خفيف وسريع بدل الأذان الكامل (~3 دقائق)',
            en: 'Result: a brief alert instead of the full adhan (~3 minutes)',
          ),
          const SizedBox(height: 10),
          // Pronunciation illustration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            ),
            child: Row(children: [
              const Icon(Icons.graphic_eq_rounded, size: 18, color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                isAr
                    ? '🔊  الله أكبر ×٢  →  ⏹  (يقف)'
                    : '🔊  Allahu Akbar ×2  →  ⏹  (stops)',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: 0.5,
                ),
              )),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.play_circle_outline_rounded, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(child: Text(
                isAr
                    ? 'عند الضغط على استماع في القائمة أدناه سيشتغل الأذان بنفس الطريقة المختصرة'
                    : 'Preview buttons below will also use short mode',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Sound section (unified, streaming, no tabs) ─────────────────────────

  Widget _buildSoundSection(bool isAr) {
    final allSounds = [...AdhanSounds.local, ...AdhanSounds.online];
    final selected = AdhanSounds.findById(_selectedSoundId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
              isAr ? 'صوت الأذان والمؤذن' : 'Adhan Sound & Muezzin',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
            )),
          ]),
        ),

        // Selected sound card (gold-bordered hero)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.secondary.withValues(alpha: 0.12),
              AppColors.primary.withValues(alpha: 0.06),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? selected.nameAr : selected.nameEn,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(
                '${isAr ? "المؤذن: " : "Muezzin: "}${selected.muezzinDisplay(isAr)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                '${isAr ? "المسجد: " : "Mosque: "}${selected.mosqueDisplay(isAr)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ])),
            const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 22),
          ]),
        ),

        // Offline note
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(children: [
            const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(
              isAr
                  ? 'الأصوات الأون‌لاين تُشغَّل مباشرةً بدون تحميل. عند انقطاع الإنترنت يُستخدم أذان مكة المكرمة احتياطياً.'
                  : 'Online sounds stream directly. If offline, Makkah adhan is used as fallback.',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            )),
          ]),
        ),

        // Unified sound list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allSounds.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final s = allSounds[i];
                final cs = s.isOnline ? (_cacheState[s.id] ?? _CacheState.none) : _CacheState.cached;
                final cp = s.isOnline ? (_cacheProgress[s.id] ?? 0.0) : 1.0;
                return _SoundTile(
                  sound: s,
                  isSelected: _selectedSoundId == s.id,
                  isPlaying: _previewingId == s.id && _isPreviewPlaying,
                  cacheState: cs,
                  cacheProgress: cp,
                  isAr: isAr,
                  onSelect: () => _selectSound(s),
                  onPreview: () => _previewSound(s),
                  onStop: _stopPreview,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Prayer method card ──────────────────────────────────────────────────

  Widget _buildMethodCard(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          value: _methodAutoDetected,
          title: Text(
            isAr ? 'تحديد الطريقة تلقائياً حسب الموقع' : 'Auto-detect method from location',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isAr ? 'يعتمد على الدولة المكتشفة من GPS' : 'Based on GPS-detected country',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          onChanged: (v) { setState(() => _methodAutoDetected = v); _autoSave(); },
        ),
        const Divider(height: 1, color: AppColors.cardBorder),
        const SizedBox(height: 8),
        Text(isAr ? 'أو اختر يدوياً:' : 'Or select manually:',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ...PrayerCalculationConstants.calculationMethods.entries.map((entry) {
          final id = entry.key;
          final info = entry.value;
          final isEgyptian = id == 'egyptian';
          final isSelected = _selectedMethodId == id;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  )
                : null,
            child: RadioListTile<String>(
              value: id, groupValue: _selectedMethodId,
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              title: Row(children: [
                Flexible(child: Text(isAr ? info.nameAr : info.nameEn,
                    style: TextStyle(fontSize: 13,
                        fontWeight: isEgyptian || isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary))),
                if (isEgyptian) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(isAr ? 'الافتراضي' : 'Default',
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              onChanged: _methodAutoDetected ? null : (v) {
                if (v != null) { setState(() => _selectedMethodId = v); _autoSave(); }
              },
            ),
          );
        }),
      ]),
    );
  }

  // ─── Schedule card ───────────────────────────────────────────────────────

  Widget _buildScheduleCard(bool isAr) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.event_available_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(isAr ? 'مُجدوَل: ٣٠ يوماً قادمة' : '30 days scheduled ahead',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          isAr ? 'بمجرد الحفظ، يُجدَّل الأذان تلقائياً لـ ٣٠ يوماً.\nيعمل حتى عند إغلاق التطبيق.'
              : 'Once saved, adhan is scheduled for 30 days.\nWorks even when the app is closed.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final raw = _settings.getAdhanSchedulePreview();
              if (!context.mounted) return;
              await _showScheduleDialog(isAr: isAr, raw: raw, notificationsEnabled: _notificationsEnabled);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calendar_view_week_rounded, size: 18),
            label: Text(isAr ? 'عرض الجدول الحالي' : 'View Current Schedule',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  // ─── Test card ───────────────────────────────────────────────────────────

  Widget _buildTestCard(bool isAr) {
    final selectedSound = AdhanSounds.findById(_selectedSoundId);
    final needsDownload = selectedSound.isOnline &&
        (_cacheState[_selectedSoundId] ?? _CacheState.none) != _CacheState.cached;
    final isDownloading = _cacheState[_selectedSoundId] == _CacheState.caching;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          isAr
              ? 'تحقق من عمل الأذان. "بعد دقيقة" يختبر التشغيل في الخلفية — جرّب إغلاق التطبيق.'
              : 'Verify Adhan works. "In 1 min" tests background playback — try closing the app.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
        ),
        // Warning banner when online sound isn't cached yet
        if (needsDownload) ...[               const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              if (isDownloading)
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
              else
                const Icon(Icons.download_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(
                isAr
                    ? (isDownloading
                        ? 'يُحمَّل الصوت... سيتم التشغيل تلقائيًا عند الاكتمال'
                        : 'الصوت الأونلاين لم يُحمَّل بعد. اضغط استماع في قائمة الأصوات لتحميله، تم تشغيل أذان مكة احتياطيًا')
                    : (isDownloading
                        ? 'Downloading sound... will switch automatically when ready'
                        : 'Online sound not cached. Press ▶ in the sound list to download. Makkah adhan used as fallback.'),
                style: const TextStyle(fontSize: 11, color: Colors.orange, height: 1.4),
              )),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _GradientButton(
            loading: _isTesting,
            icon: Icons.volume_up_rounded,
            label: isAr ? 'اختبار الآن' : 'Test Now',
            onPressed: () async {
              final sel = AdhanSounds.findById(_selectedSoundId);
              if (sel.isOnline) {
                // Online sounds: stream via Dart AudioPlayer (from cache or URL)
                // This works correctly even when the file isn't downloaded yet
                await _previewSound(sel);
                _showSnack(isAr ? 'يعمل الأذان الآن 🔊' : 'Adhan playing now 🔊', AppColors.success);
              } else {
                // Offline sounds: use native service (shows foreground notification too)
                setState(() => _isTesting = true);
                try {
                  await _adhanService.testNow();
                  _showSnack(isAr ? 'يعمل الأذان الآن 🔊' : 'Adhan playing now 🔊', AppColors.success);
                } finally {
                  if (mounted) setState(() => _isTesting = false);
                }
              }
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: _OutlineButton(
            loading: _schedulingTest,
            icon: Icons.access_alarm_rounded,
            label: isAr ? 'بعد دقيقة' : 'In 1 Minute',
            onPressed: () async {
              setState(() => _schedulingTest = true);
              try {
                await _adhanService.scheduleTestIn(const Duration(minutes: 1));
                _showSnack(isAr ? 'سيعمل الأذان بعد دقيقة ✔️' : 'Adhan in 1 min ✔️', AppColors.success);
              } finally {
                if (mounted) setState(() => _schedulingTest = false);
              }
            },
          )),
        ]),
      ]),
    );
  }

  // ─── Schedule dialog ─────────────────────────────────────────────────────

  Future<void> _showScheduleDialog({
    required bool isAr,
    String? raw,
    bool notificationsEnabled = true,
  }) async {
    List<Map<String, dynamic>> items = [];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          items = decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        }
      } catch (_) {}
    }
    String localizePrayer(String label) {
      if (!isAr) return label;
      switch (label.toLowerCase()) {
        case 'fajr': return 'الفجر';
        case 'dhuhr': return 'الظهر';
        case 'asr': return 'العصر';
        case 'maghrib': return 'المغرب';
        case 'isha': return 'العشاء';
        default: return label;
      }
    }
    IconData prayerIcon(String label) {
      switch (label.toLowerCase()) {
        case 'fajr': return Icons.nights_stay_rounded;
        case 'dhuhr': return Icons.wb_sunny_rounded;
        case 'asr': return Icons.wb_cloudy_rounded;
        case 'maghrib': return Icons.wb_twilight_rounded;
        case 'isha': return Icons.bedtime_rounded;
        default: return Icons.access_time_rounded;
      }
    }
    Color prayerColor(String label) {
      switch (label.toLowerCase()) {
        case 'fajr': return const Color(0xFF6A5ACD);
        case 'dhuhr': return const Color(0xFFF4B400);
        case 'asr': return AppColors.primary;
        case 'maghrib': return const Color(0xFFFF7043);
        case 'isha': return const Color(0xFF1565C0);
        default: return AppColors.primary;
      }
    }
    final parsed = <({String label, DateTime time})>[];
    for (final it in items) {
      final label = (it['label'] as String?) ?? '';
      final timeStr = it['time'] as String?;
      final dt = timeStr == null ? null : DateTime.tryParse(timeStr);
      if (dt == null) continue;
      parsed.add((label: label, time: dt));
    }
    parsed.sort((a, b) => a.time.compareTo(b.time));
    final now = DateTime.now();
    final byDate = <String, List<({String label, DateTime time})>>{};
    for (final item in parsed) {
      final key = '${item.time.year}-${item.time.month.toString().padLeft(2, '0')}-${item.time.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => []).add(item);
    }
    ({String label, DateTime time})? nextPrayer;
    for (final item in parsed) { if (item.time.isAfter(now)) { nextPrayer = item; break; } }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String fmtTime(DateTime dt) {
          final tod = TimeOfDay.fromDateTime(dt.toLocal());
          final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
          final m = tod.minute.toString().padLeft(2, '0');
          return '$h:$m ${tod.period == DayPeriod.am ? "AM" : "PM"}';
        }
        String fmtDate(DateTime dt) {
          final months = isAr
              ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
              : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          return '${dt.day} ${months[dt.month - 1]}';
        }
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? 'جدول الأذان' : 'Adhan Schedule',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${parsed.length} ${isAr ? "صلاة · ٣٠ يوماً" : "prayers · 30 days"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
            ]),
          ]),
          content: SizedBox(width: double.maxFinite, height: 480, child: parsed.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(notificationsEnabled ? Icons.event_busy_rounded : Icons.notifications_off_rounded,
                    size: 56, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  notificationsEnabled
                      ? (isAr ? 'لا يوجد جدول بعد.\nاحفظ الإعدادات أولاً.' : 'No schedule yet.\nSave settings first.')
                      : (isAr ? 'إشعارات الأذان معطّلة.' : 'Adhan notifications are off.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ]))
            : Column(children: [
                if (nextPrayer != null) ...[
                  Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: prayerColor(nextPrayer.label).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: prayerColor(nextPrayer.label).withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Icon(prayerIcon(nextPrayer.label), size: 20, color: prayerColor(nextPrayer.label)),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${isAr ? "التالي: " : "Next: "}${localizePrayer(nextPrayer.label)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: prayerColor(nextPrayer.label))),
                        Text('${fmtDate(nextPrayer.time)} — ${fmtTime(nextPrayer.time)}',
                            style: TextStyle(fontSize: 12, color: prayerColor(nextPrayer.label).withValues(alpha: 0.8))),
                      ]),
                    ])),
                  const SizedBox(height: 6),
                ],
                Expanded(child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: byDate.length,
                  itemBuilder: (ctx2, index) {
                    final dateKey = byDate.keys.elementAt(index);
                    final dayItems = byDate[dateKey]!;
                    final dt = dayItems.first.time;
                    final today = DateTime(now.year, now.month, now.day);
                    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
                    final isTomorrow = DateTime(dt.year, dt.month, dt.day).difference(today).inDays == 1;
                    String dayLabel = fmtDate(dt);
                    if (isToday) dayLabel = isAr ? 'اليوم' : 'Today';
                    if (isTomorrow) dayLabel = isAr ? 'غداً' : 'Tomorrow';
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.fromLTRB(6, 10, 6, 6), child: Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
                          child: Text(dayLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isToday ? Colors.white : AppColors.textSecondary))),
                        const SizedBox(width: 6),
                        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
                      ])),
                      Wrap(spacing: 6, runSpacing: 6, children: dayItems.map((item) {
                        final color = prayerColor(item.label);
                        final isPast = item.time.isBefore(now);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPast ? Colors.transparent : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isPast ? AppColors.divider : color.withValues(alpha: 0.35)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(prayerIcon(item.label), size: 14, color: isPast ? AppColors.textSecondary : color),
                            const SizedBox(width: 5),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(localizePrayer(item.label), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: isPast ? AppColors.textSecondary : color)),
                              Text(fmtTime(item.time), style: TextStyle(fontSize: 11,
                                  color: isPast ? AppColors.textSecondary : color.withValues(alpha: 0.8))),
                            ]),
                          ]),
                        );
                      }).toList()),
                      const SizedBox(height: 4),
                    ]);
                  },
                )),
              ])),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إغلاق' : 'Close',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))],
        );
      },
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _DisabledBanner extends StatelessWidget {
  final bool isAr;
  const _DisabledBanner({required this.isAr});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.notifications_off_rounded, color: Colors.orange, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(
          isAr ? 'الأذان معطَّل حالياً — فعِّله من الإعداد أدناه' : 'Adhan is currently disabled — enable it below',
          style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }
}

// ─── Sound tile ───────────────────────────────────────────────────────────────

class _SoundTile extends StatelessWidget {
  final AdhanSoundInfo sound;
  final bool isSelected;
  final bool isPlaying;
  final _CacheState cacheState;
  final double cacheProgress;
  final bool isAr;
  final VoidCallback onSelect;
  final VoidCallback onPreview;
  final VoidCallback onStop;

  const _SoundTile({
    required this.sound, required this.isSelected, required this.isPlaying,
    required this.cacheState, required this.cacheProgress, required this.isAr,
    required this.onSelect, required this.onPreview, required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(children: [
            Row(children: [
              // Radio circle
              AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 2),
                  color: isSelected ? AppColors.primary : Colors.transparent),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null),
              const SizedBox(width: 12),
              // Mosque icon
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.mosque_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22)),
              const SizedBox(width: 12),
              // Name & metadata
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(isAr ? sound.nameAr : sound.nameEn,
                    style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis)),
                  if (sound.isOfflineFallback) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(isAr ? 'احتياطي' : 'Fallback',
                        style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.person_outline_rounded, size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Flexible(child: Text(sound.muezzinDisplay(isAr),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 1),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Flexible(child: Text(sound.mosqueDisplay(isAr),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis)),
                ]),
              ])),
              const SizedBox(width: 4),
              // Cache indicator (online sounds only)
              if (sound.isOnline) ...[
                _CacheIndicator(state: cacheState, progress: cacheProgress),
                const SizedBox(width: 2),
              ],
              // Play / Stop button — always enabled (streams if online)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: isPlaying
                  ? const Icon(Icons.stop_circle_rounded, key: ValueKey('stop'), color: Colors.red, size: 26)
                  : Icon(Icons.play_circle_rounded, key: const ValueKey('play'),
                      color: AppColors.primary, size: 26)),
                tooltip: isPlaying ? (isAr ? 'إيقاف' : 'Stop') : (isAr ? 'استماع' : 'Preview'),
                onPressed: isPlaying ? onStop : onPreview),
            ]),
            // Cache progress bar (while caching)
            if (sound.isOnline && cacheState == _CacheState.caching && cacheProgress > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: cacheProgress, minHeight: 3,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12), color: AppColors.secondary)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─── Cache indicator ──────────────────────────────────────────────────────────

class _CacheIndicator extends StatelessWidget {
  final _CacheState state;
  final double progress;
  const _CacheIndicator({required this.state, required this.progress});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _CacheState.caching:
        return SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2, color: AppColors.secondary));
      case _CacheState.cached:
        return const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.secondary);
      case _CacheState.error:
        return const Icon(Icons.cloud_off_rounded, size: 18, color: Colors.red);
      case _CacheState.none:
        return Icon(Icons.wifi_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.45));
    }
  }
}

// ─── Battery warning ──────────────────────────────────────────────────────────

class _BatteryWarningCard extends StatelessWidget {
  final bool isAr;
  final VoidCallback onTap;
  const _BatteryWarningCard({required this.isAr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.battery_alert_rounded, color: Colors.amber, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isAr ? 'تحسين استهلاك البطارية' : 'Battery Optimization',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              isAr ? 'لضمان سماع الأذان دائماً، اضغط أدناه واختر "غير مقيَّد"'
                  : 'For reliable Adhan, tap below and select "Unrestricted"',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ])),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 11), elevation: 0),
          icon: const Icon(Icons.battery_charging_full_rounded, size: 18),
          label: Text(isAr ? 'افتح إعدادات البطارية' : 'Open Battery Settings',
              style: const TextStyle(fontWeight: FontWeight.bold)))),
      ]),
    );
  }
}

// ─── Gradient button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final bool loading;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _GradientButton({required this.loading, required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: loading ? null : const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
          color: loading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          else
            Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: loading ? Colors.grey : Colors.white, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─── Outline button ───────────────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final bool loading;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _OutlineButton({required this.loading, required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: loading ? Colors.grey : AppColors.primary, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else
            Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: loading ? Colors.grey : AppColors.primary, fontSize: 13)),
        ]),
      ),
    );
  }
}
// ─── Short mode step ──────────────────────────────────────────────────────────

class _ShortModeStep extends StatelessWidget {
  final String number;
  final bool isAr;
  final String ar;
  final String en;
  const _ShortModeStep({required this.number, required this.isAr, required this.ar, required this.en});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isAr ? ar : en,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ]),
    );
  }
}