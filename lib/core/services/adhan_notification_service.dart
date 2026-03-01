import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/adhan_sounds.dart';
import '../constants/prayer_calculation_constants.dart';
import 'location_service.dart';
import 'settings_service.dart';
import 'prayer_times_cache_service.dart';

/// Schedules local notifications at the calculated prayer times.
///
/// Notes:
/// - On Android, notifications + exact alarms require user approval on newer OS versions.
/// - Always uses custom adhan.mp3 sound from res/raw.
class AdhanNotificationService {
  static const String _channelName = 'Prayer Times';
  static const String _channelDescription = 'Prayer time reminders with Adhan sound.';
  static const MethodChannel _androidAdhanPlayerChannel =
      MethodChannel('quraan/adhan_player');

  // V3: Silent channel. We rely on the native MediaPlayer via MethodChannel for audio.
  // This avoids conflicts/ducking/cutting between notification sound and media player.
  static const String _channelId = 'adhan_prayer_times_v3_silent';

  // Reminder channels — one per prayer so users can customise each independently
  // in Android → App info → Notifications, and each prayer has its own voice.
  // v1 channels kept for fajr/asr/isha (sounds unchanged).
  // v2 channels for dhuhr/maghrib (updated to approaching sounds).
  static const String _reminderChannelFajr    = 'prayer_reminder_fajr_v1';
  static const String _reminderChannelDhuhr   = 'prayer_reminder_dhuhr_v2'; // v2: approaching sound
  static const String _reminderChannelAsr     = 'prayer_reminder_asr_v1';
  static const String _reminderChannelMaghrib = 'prayer_reminder_maghrib_v2'; // v2: approaching sound
  static const String _reminderChannelIsha    = 'prayer_reminder_isha_v1';
  static const String _reminderChannelName        = 'Pre-Prayer Reminder';
  static const String _reminderChannelDescription = 'Alert N minutes before each prayer.';
  static const String _iqamaChannelId             = 'iqama_reminder_v2'; // v2: full iqama sound
  static const String _iqamaChannelName           = 'Iqama Reminder';
  static const String _iqamaChannelDescription    = 'Alert N minutes after the prayer call.';
  // Salawat: 5 dedicated channels — one per sound option.
  // Channels are immutable after creation, so each sound needs its own channel.
  static const String _salawatChannelId1    = 'salawat_1_v1';
  static const String _salawatChannelId2    = 'salawat_2_v1';
  static const String _salawatChannelId3    = 'salawat_3_v1';
  static const String _salawatChannelId4    = 'salawat_4_v1';
  static const String _salawatChannelId5    = 'salawat_5_v1';
  static const String _salawatChannelName         = 'Salawat Reminder';
  static const String _salawatChannelDescription  = 'Periodic salawat (blessings on the Prophet \u33ba) reminders.';

  // Old channel IDs to clean up on next launch
  static const List<String> _oldChannelIds = [
    'adhan_prayer_times',
    'adhan_prayer_times_custom',
    'adhan_prayer_times_v2',
    'prayer_reminders_v1',        // merged into 3 separate channels
    'prayer_reminder_v2',          // replaced by 5 prayer-specific channels
    'prayer_reminder_dhuhr_v1',   // replaced by v2 with approaching sound
    'prayer_reminder_maghrib_v1', // replaced by v2 with approaching sound
    'salawat_reminder_v1',        // replaced by 5 dedicated salawat channels
    'iqama_reminder_v1',          // replaced by v2 with full iqama sound
  ];

  // iOS: expects a bundled sound file (e.g. Runner -> adhan.caf)
  static const String _iosAdhanSoundName = 'adhan.caf';

  static const int _daysToScheduleAhead = 30;

  final FlutterLocalNotificationsPlugin _plugin;
  final SettingsService _settings;
  final LocationService _location;
  final PrayerTimesCacheService _cache;

  final List<Timer> _inAppTimers = [];
  // _isAdhanPlaying removed — AdhanPlayerService manages its own concurrency.
  DateTime? _lastAdhanStartedAt;

  AdhanNotificationService(
    this._plugin,
    this._settings,
    this._location,
    this._cache,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fallback: tz.local will still work on many platforms.
    }

    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    await recreateAndroidChannels();
    await _initAdhanPlayer();
  }

  Future<void> _initAdhanPlayer() async {
    // Android playback is handled natively via MethodChannel.
  }

  Future<void> _playFullAdhanAudio() async {
    try {
      final now = DateTime.now();
      // 35-second cooldown guard prevents double-triggers from overlapping timers.
      final lastStart = _lastAdhanStartedAt;
      if (lastStart != null && now.difference(lastStart) < const Duration(seconds: 35)) {
        debugPrint('🔇 [Adhan] Ignored duplicate trigger within cooldown window');
        return;
      }
      _lastAdhanStartedAt = now;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final soundId = _settings.getSelectedAdhanSound();
        final sound = AdhanSounds.findById(soundId);
        // Use the foreground service so audio plays even when the app is in the background.
        // For online sounds: pass URL so native service can stream it directly without
        // requiring a pre-downloaded file. If streaming fails, native falls back to
        // the offline fallback sound (adhan_1).
        final ok = await _androidAdhanPlayerChannel.invokeMethod<bool>(
          'startAdhanService',
          {
            'soundName': soundId,
            'shortMode': _settings.getAdhanShortMode(),
            'shortCutoffSeconds': sound.shortDurationSeconds,
            'onlineUrl': sound.isOnline ? sound.url : null,
            'fallbackSoundName': AdhanSounds.offlineFallback.id,
            'useAlarmStream': _settings.getAdhanAudioStream() == 'alarm',
          },
        );
        if (ok == true) {
          debugPrint('🔊 [Adhan] AdhanPlayerService started: $soundId');
          return;
        }
      }

      // Fallback for non-Android / service failure.
      await _plugin.show(
        999003,
        'وقت الصلاة',
        'حان وقت الصلاة',
        _notificationDetails(),
      );
      debugPrint('🔔 [Adhan] Fallback notification shown');
    } catch (e) {
      debugPrint('Adhan playback error: $e');
    }
  }

  // ── Native AlarmManager scheduling ──────────────────────────────

  /// Pushes all future prayer-time alarms to the Android AlarmManager.
  /// These alarms survive the app being killed and fire AdhanPlayerService.
  Future<void> _scheduleNativeAlarms(List<Map<String, dynamic>> preview) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final soundId = _settings.getSelectedAdhanSound();
      final sound = AdhanSounds.findById(soundId);
      final alarms = preview.map((item) {
        final timeStr = item['time'] as String?;
        if (timeStr == null) return null;
        final dt = DateTime.tryParse(timeStr);
        if (dt == null) return null;
        return <String, dynamic>{
          'id': item['id'] as int,
          'timeMs': dt.millisecondsSinceEpoch,
        };
      }).whereType<Map<String, dynamic>>().toList();

      await _androidAdhanPlayerChannel.invokeMethod('scheduleAdhanAlarms', {
        'alarms': alarms,
        'soundName': soundId,
        'shortMode': _settings.getAdhanShortMode(),
        'shortCutoffSeconds': sound.shortDurationSeconds,
        'onlineUrl': sound.isOnline ? sound.url : null,
        'fallbackSoundName': AdhanSounds.offlineFallback.id,
        'useAlarmStream': _settings.getAdhanAudioStream() == 'alarm',
      });
      debugPrint('🔔 [Adhan] AlarmManager: scheduled ${alarms.length} alarm(s)');
    } catch (e) {
      debugPrint('Native alarm scheduling error: $e');
    }
  }

  /// Cancels all previously scheduled AlarmManager alarms using the stored IDs.
  Future<void> _cancelAllNativeAlarms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final raw = _settings.getAdhanSchedulePreview();
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      final ids = list
          .whereType<Map>()
          .map((e) => e['id'])
          .whereType<int>()
          .toList();
      if (ids.isEmpty) return;
      await _androidAdhanPlayerChannel.invokeMethod('cancelAdhanAlarms', {'ids': ids});
      debugPrint('🔔 [Adhan] AlarmManager: cancelled ${ids.length} alarm(s)');
    } catch (e) {
      debugPrint('Native alarm cancel error: $e');
    }
  }

  void _clearInAppTimers() {
    for (final t in _inAppTimers) {
      t.cancel();
    }
    _inAppTimers.clear();
  }

  Future<void> recreateAndroidChannels() async {
    if (kIsWeb) return;

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // Delete all old channels (best-effort cleanup)
    for (final oldId in _oldChannelIds) {
      try {
        await android.deleteNotificationChannel(oldId);
      } catch (_) {}
    }
    
    // Delete current channel if it exists
    try {
      await android.deleteNotificationChannel(_channelId);
    } catch (_) {}

    // Create new Adhan channel with SILENT settings as we play audio via native MediaPlayer
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: false, // Ensure no double audio triggers
        enableVibration: true,
        // sound: _adhanSound, // DO NOT USE
      ),
    );

    // Reminder channel — text notifications with OS default sound.
    // Note: createNotificationChannel() is idempotent. We do NOT delete reminder channels
    // on every launch because Android discards pending notifications when a channel is deleted.
    final reminderChannels = [
      // Five prayer-specific reminder channels.
      // Fajr/Asr/Isha: original voice files (v1 unchanged).
      // Dhuhr/Maghrib: approaching-prayer sounds (v2 — new channels).
      const AndroidNotificationChannel(
        _reminderChannelFajr, _reminderChannelName,
        description: _reminderChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('prayer_reminder_fajr'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _reminderChannelDhuhr, _reminderChannelName,
        description: _reminderChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('prayer_approaching_dhuhr'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _reminderChannelAsr, _reminderChannelName,
        description: _reminderChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('prayer_reminder_asr'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _reminderChannelMaghrib, _reminderChannelName,
        description: _reminderChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('prayer_approaching_maghrib'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _reminderChannelIsha, _reminderChannelName,
        description: _reminderChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('prayer_reminder_isha'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _iqamaChannelId, _iqamaChannelName,
        description: _iqamaChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('iqama_sound_full'),
        enableVibration: true,
      ),
      // Five salawat channels — one per sound option (sounds are baked at channel creation).
      const AndroidNotificationChannel(
        _salawatChannelId1, _salawatChannelName,
        description: _salawatChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salawat_1'),
        enableVibration: false,
      ),
      const AndroidNotificationChannel(
        _salawatChannelId2, _salawatChannelName,
        description: _salawatChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salawat_2'),
        enableVibration: false,
      ),
      const AndroidNotificationChannel(
        _salawatChannelId3, _salawatChannelName,
        description: _salawatChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salawat_3'),
        enableVibration: false,
      ),
      const AndroidNotificationChannel(
        _salawatChannelId4, _salawatChannelName,
        description: _salawatChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salawat_4'),
        enableVibration: false,
      ),
      const AndroidNotificationChannel(
        _salawatChannelId5, _salawatChannelName,
        description: _salawatChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salawat_5'),
        enableVibration: false,
      ),
    ];
    for (final ch in reminderChannels) {
      await android.createNotificationChannel(ch);
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    var ok = true;

    if (android != null) {
      final notifOk = await android.requestNotificationsPermission();
      ok = ok && (notifOk ?? true);

      // Best-effort: exact alarms permission (Android 12+).
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {
        // Some Android versions/devices may not support this API; ignore.
      }
    }

    if (ios != null) {
      final notifOk = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      ok = ok && (notifOk ?? true);
    }

    return ok;
  }

  Future<void> disable() async {
    await _settings.setAdhanNotificationsEnabled(false);
    _clearInAppTimers();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidAdhanPlayerChannel.invokeMethod<void>('stopAdhan');
      } catch (_) {}
    }
    await cancelAll();               // Cancels ALL pending notifications (adhan, reminders, iqama, salawat)
    await _cancelAllNativeAlarms();   // Cancels AlarmManager alarms
    // Clear the schedule preview so the UI schedule dialog shows empty, not stale data.
    await _settings.setAdhanSchedulePreview('[]');
    // صلاة على النبي ﷺ reminders are independent of adhan.
    // Re-schedule them so they keep working even when adhan is disabled.
    await _scheduleSalawatNotifications();
  }

  /// Stops the currently playing Adhan without disabling future scheduled notifications.
  /// Call this when the user starts Quran audio so the two don't overlap.
  Future<void> stopCurrentAdhan() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _androidAdhanPlayerChannel.invokeMethod<void>('stopAdhan');
      } catch (_) {}
    }
  }

  Future<void> enableAndSchedule() async {
    await _settings.setAdhanNotificationsEnabled(true);
    await ensureScheduled();
  }

  Future<void> ensureScheduled() async {
    final enabled = _settings.getAdhanNotificationsEnabled();
    if (!enabled) return;

    final coords = await _ensureCoordinatesForScheduling();
    if (coords == null) return;

    // Update prayer times cache if invalid or stale
    if (!_cache.isCacheValid()) {
      await _cache.cachePrayerTimes(coords.latitude, coords.longitude);
    }

    // Schedule multiple days ahead so reminders still fire when the app is closed.
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);

    await cancelAll();
    final preview = <Map<String, dynamic>>[];
    for (var i = 0; i < _daysToScheduleAhead; i++) {
      final items = await _scheduleForDate(coords, today.add(Duration(days: i)));
      for (final it in items) {
        preview.add(it);
      }
    }

    await _settings.setLastAdhanScheduleDateIso(today.toIso8601String());

    // Persist a snapshot of what we scheduled (for UI display).
    // Note: this does not guarantee OS delivery, but reflects our intended schedule.
    try {
      preview.sort((a, b) {
        final ta = DateTime.tryParse(a['time'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse(b['time'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
      await _settings.setAdhanSchedulePreview(jsonEncode(preview));
      await _scheduleNativeAlarms(preview);
      await _scheduleSalawatNotifications();
    } catch (_) {
      // Ignore preview/schedule failures.
    }
  }

  Future<void> testNow() async {
    await _playFullAdhanAudio();
    final isArabic = _settings.getAppLanguage() == 'ar';
    await _plugin.show(
      999001,
      isArabic ? 'اختبار الأذان' : 'Adhan Test',
      isArabic ? 'إذا سمعت الأذان، فالتذكيرات تعمل بشكل صحيح ✓' : 'If you hear the Adhan, reminders are working.',
      _notificationDetails(),
    );
  }

  Future<void> scheduleTestIn(Duration delay) async {
    final when = tz.TZDateTime.now(tz.local).add(delay);
    final whenLocal = DateTime.now().add(delay);

    // In-app timer (fires if app stays open)
    Timer(delay, () async {
      await _playFullAdhanAudio();
    });

    // Native AlarmManager alarm (fires even when app is killed)
    await _scheduleNativeAlarms([
      {
        'id': 999002,
        'time': whenLocal.toIso8601String(),
        'prayer': 'test',
        'label': 'Test',
      }
    ]);

    // Silent OS notification as a companion reminder
    await _plugin.zonedSchedule(
      999002,
      'اختبار الأذان',
      'إذا سمعت الأذان، فالتطبيق يعمل بشكل صحيح ✓',
      when,
      _notificationDetails(),
      androidScheduleMode: await _androidScheduleMode(),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<Coordinates?> _ensureCoordinatesForScheduling() async {
    final cached = _settings.getLastKnownCoordinates();
    if (cached != null) return cached;

    final cachedFromTimes = _cache.getCachedLocation();
    if (cachedFromTimes != null) {
      return Coordinates(cachedFromTimes.latitude, cachedFromTimes.longitude);
    }

    // Try getting a fresh location once.
    final permission = await _location.ensurePermission();
    if (permission != LocationPermissionState.granted) {
      return null;
    }

    try {
      final pos = await _location.getPosition(timeout: const Duration(seconds: 12));
      await _settings.setLastKnownCoordinates(pos.latitude, pos.longitude);
      return Coordinates(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _scheduleForDate(Coordinates coordinates, DateTime date) async {
    // Try to use cached prayer times first (offline support)
    final cachedTimes = _cache.getCachedTimesForDate(date);
    
    Map<String, DateTime> prayerTimesMap;
    
    if (cachedTimes != null) {
      // Use cached times (offline mode)
      prayerTimesMap = cachedTimes;
    } else {
      // Fallback: calculate fresh times with user's preferred method
      final calculationMethod = _settings.getPrayerCalculationMethod();
      final asrMethod = _settings.getPrayerAsrMethod();
      final params = PrayerCalculationConstants.getCompleteParameters(
        calculationMethod: calculationMethod,
        asrMethod: asrMethod,
      );
      
      final prayerTimes = PrayerTimes(
        coordinates,
        DateComponents(date.year, date.month, date.day),
        params,
      );

      prayerTimesMap = {
        'fajr': prayerTimes.fajr,
        'dhuhr': prayerTimes.dhuhr,
        'asr': prayerTimes.asr,
        'maghrib': prayerTimes.maghrib,
        'isha': prayerTimes.isha,
      };
    }

    final isArabic = _settings.getAppLanguage() == 'ar';

    const arabicNames = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };

    // Per-prayer enabled flags.
    final items = <_PrayerNotifItem>[
      _PrayerNotifItem(Prayer.fajr,    'Fajr',    prayerTimesMap['fajr']!,    enabled: _settings.getAdhanIncludeFajr()),
      _PrayerNotifItem(Prayer.dhuhr,   'Dhuhr',   prayerTimesMap['dhuhr']!,   enabled: _settings.getAdhanEnableDhuhr()),
      _PrayerNotifItem(Prayer.asr,     'Asr',     prayerTimesMap['asr']!,     enabled: _settings.getAdhanEnableAsr()),
      _PrayerNotifItem(Prayer.maghrib, 'Maghrib', prayerTimesMap['maghrib']!, enabled: _settings.getAdhanEnableMaghrib()),
      _PrayerNotifItem(Prayer.isha,    'Isha',    prayerTimesMap['isha']!,    enabled: _settings.getAdhanEnableIsha()),
    ];

    final reminderEnabled = _settings.getPrayerReminderEnabled();
    final reminderMinutes = _settings.getPrayerReminderMinutes();
    final iqamaEnabled    = _settings.getIqamaEnabled();
    final schedMode       = await _androidScheduleMode();
    final now             = tz.TZDateTime.now(tz.local);

    final scheduled = <Map<String, dynamic>>[];
    for (final item in items) {
      if (!item.enabled) continue;

      final localTime = tz.TZDateTime.from(item.time.toLocal(), tz.local);
      // Don't schedule notifications in the past.
      if (localTime.isBefore(now)) continue;

      final id = _notificationId(date, item.prayer);
      final arabicName = arabicNames[item.prayer.name] ?? item.label;

      // ── Only add to schedule (drives native alarms + preview UI) ─────────
      // Audio + foreground notification are handled by AdhanPlayerService.
      // No additional OS notification here — that caused Doze-delayed double-play.
      scheduled.add({
        'id': id,
        'prayer': item.prayer.name,
        'label': item.label,
        'time': item.time.toLocal().toIso8601String(),
      });

      // ── Pre-prayer reminder ──────────────────────────────────────────────
      if (reminderEnabled && reminderMinutes > 0) {
        final reminderTime = localTime.subtract(Duration(minutes: reminderMinutes));
        if (reminderTime.isAfter(now)) {
          final remId    = _reminderNotificationId(date, item.prayer);
          final remTitle = isArabic
              ? 'تنبيه: $arabicName بعد $reminderMinutes دقيقة'
              : '${item.label} in $reminderMinutes min';
          final remBody  = isArabic
              ? 'استعد لصلاة $arabicName'
              : 'Prepare for ${item.label} prayer';
          await _plugin.zonedSchedule(
            remId, remTitle, remBody,
            reminderTime,
            _reminderNotificationDetails(item.prayer),
            androidScheduleMode: schedMode,
          );
        }
      }

      // ── Iqama reminder ────────────────────────────────────────────────────
      if (iqamaEnabled) {
        // Per-prayer iqama minutes (different defaults per prayer).
        final iqamaMinutes = switch (item.prayer) {
          Prayer.fajr    => _settings.getIqamaMinutesFajr(),
          Prayer.dhuhr   => _settings.getIqamaMinutesDhuhr(),
          Prayer.asr     => _settings.getIqamaMinutesAsr(),
          Prayer.maghrib => _settings.getIqamaMinutesMaghrib(),
          Prayer.isha    => _settings.getIqamaMinutesIsha(),
          _              => _settings.getIqamaMinutes(), // fallback
        };
        final iqamaTime  = localTime.add(Duration(minutes: iqamaMinutes));
        final iqamaId    = _iqamaNotificationId(date, item.prayer);
        final iqamaTitle = isArabic ? 'إقامة: $arabicName' : 'Iqama: ${item.label}';
        final iqamaBody  = isArabic
            ? 'حان وقت الإقامة لصلاة $arabicName'
            : 'Time to stand for ${item.label} prayer';
        if (iqamaMinutes > 0) {
          await _plugin.zonedSchedule(
            iqamaId, iqamaTitle, iqamaBody,
            iqamaTime,
            _iqamaNotificationDetails(),
            androidScheduleMode: schedMode,
          );
        }
      }
    }

    return scheduled;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: false, // SILENT — audio via AdhanPlayerService
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        // fullScreenIntent removed – it caused wake+play on Doze-delayed delivery
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: _iosAdhanSoundName,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    try {
      final canExact = await android.canScheduleExactNotifications();
      return (canExact ?? false)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  int _notificationId(DateTime day, Prayer prayer) {
    // Deterministic per day+prayer; stable and under int32 range.
    final ymd = day.year * 10000 + day.month * 100 + day.day;
    return (ymd * 10) + prayer.index;
  }

  /// ID for pre-prayer reminder — offset 300M to avoid collision with main adhan IDs.
  int _reminderNotificationId(DateTime day, Prayer prayer) {
    final ymd = day.year * 10000 + day.month * 100 + day.day;
    return 300000000 + (ymd % 1000000) * 10 + prayer.index;
  }

  /// ID for iqama reminder — offset 600M.
  int _iqamaNotificationId(DateTime day, Prayer prayer) {
    final ymd = day.year * 10000 + day.month * 100 + day.day;
    return 600000000 + (ymd % 1000000) * 10 + prayer.index;
  }

  /// Returns the reminder channel ID for a given prayer.
  String _reminderChannelId(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:    return _reminderChannelFajr;
      case Prayer.dhuhr:   return _reminderChannelDhuhr;
      case Prayer.asr:     return _reminderChannelAsr;
      case Prayer.maghrib: return _reminderChannelMaghrib;
      case Prayer.isha:    return _reminderChannelIsha;
      default:             return _reminderChannelDhuhr;
    }
  }

  /// Returns the raw-resource sound file name for a given prayer's reminder.
  /// Dhuhr and Maghrib use dedicated approaching-prayer sounds.
  String _reminderSoundFile(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:    return 'prayer_reminder_fajr';
      case Prayer.dhuhr:   return 'prayer_approaching_dhuhr';   // replaced with approaching sound
      case Prayer.asr:     return 'prayer_reminder_asr';
      case Prayer.maghrib: return 'prayer_approaching_maghrib'; // replaced with approaching sound
      case Prayer.isha:    return 'prayer_reminder_isha';
      default:             return 'prayer_approaching_dhuhr';
    }
  }

  /// Notification details for pre-prayer reminder (prayer-specific Arabic voice).
  NotificationDetails _reminderNotificationDetails(Prayer prayer) {
    final channelId  = _reminderChannelId(prayer);
    final soundFile  = _reminderSoundFile(prayer);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFile),
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Notification details for iqama (stands-for-prayer sound).
  NotificationDetails _iqamaNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _iqamaChannelId,
        _iqamaChannelName,
        channelDescription: _iqamaChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('iqama_sound_full'),
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Returns the channel ID for the currently selected salawat sound.
  String _salawatChannelId() {
    final soundId = _settings.getSalawatSound();
    switch (soundId) {
      case 'salawat_2': return _salawatChannelId2;
      case 'salawat_3': return _salawatChannelId3;
      case 'salawat_4': return _salawatChannelId4;
      case 'salawat_5': return _salawatChannelId5;
      default:          return _salawatChannelId1; // salawat_1 or any unknown value
    }
  }

  /// Notification details for Salawat reminders.
  /// Uses the channel matching the currently selected salawat sound.
  NotificationDetails _salawatNotificationDetails() {
    final channelId = _salawatChannelId();
    final soundId   = _settings.getSalawatSound();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _salawatChannelName,
        channelDescription: _salawatChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundId),
        enableVibration: false,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  /// Schedules periodic salawat (صلاة على النبي) reminder notifications.
  /// Up to 100 notifications, each [salawatMinutes] apart.
  Future<void> _scheduleSalawatNotifications() async {
    // Cancel any previously scheduled salawat notifications first.
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(700000000 + i);
    }

    final enabled = _settings.getSalawatEnabled();
    if (!enabled) return;

    final intervalMinutes = _settings.getSalawatMinutes();
    if (intervalMinutes <= 0) return;

    // Quiet hours — skip notifications scheduled inside the sleep window.
    final sleepEnabled = _settings.getSalawatSleepEnabled();
    final sleepStartH  = _settings.getSalawatSleepStartH();
    final sleepEndH    = _settings.getSalawatSleepEndH();

    bool isInSleep(tz.TZDateTime t) {
      if (!sleepEnabled) return false;
      final h = t.hour;
      // Overnight window (e.g. 22 → 06): wraps past midnight
      if (sleepStartH > sleepEndH) return h >= sleepStartH || h < sleepEndH;
      // Same-day window (e.g. 01 → 06)
      return h >= sleepStartH && h < sleepEndH;
    }

    final isArabic = _settings.getAppLanguage() == 'ar';
    final schedMode = await _androidScheduleMode();

    final salawatTexts = [
      isArabic ? 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ' : 'O Allah, send blessings upon Muhammad ﷺ',
      isArabic ? 'صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ' : 'Peace and blessings be upon the Prophet ﷺ',
      isArabic ? 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ' : 'O Allah, send peace upon our Prophet Muhammad ﷺ',
    ];

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = 0;

    for (var i = 0; i < 100; i++) {
      final triggerTime = now.add(Duration(minutes: intervalMinutes * (i + 1)));
      // Skip notifications that fall inside the user's quiet hours window.
      if (isInSleep(triggerTime)) continue;
      final text = salawatTexts[i % salawatTexts.length];
      try {
        await _plugin.zonedSchedule(
          700000000 + i,
          isArabic ? '🌙 الصلاة على النبي' : '🌙 Salawat Reminder',
          text,
          triggerTime,
          _salawatNotificationDetails(),
          androidScheduleMode: schedMode,
        );
        scheduled++;
      } catch (_) {
        // Stop if OS limit reached or permission revoked.
        break;
      }
    }

    debugPrint('🌙 [Salawat] Scheduled $scheduled reminder(s) every ${intervalMinutes}m');
  }
}

class _PrayerNotifItem {
  final Prayer prayer;
  final String label;
  final DateTime time;
  final bool enabled;

  _PrayerNotifItem(this.prayer, this.label, this.time, {this.enabled = true});
}
