import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/wird_service.dart';

/// Manages all local notifications for the daily Wird feature.
///
/// Notification strategy:
/// • ID 5000 — main daily reminder at user-set time (repeating daily).
/// • IDs 5001–5005 — follow-up reminders every 4 hours if wird not complete.
///   Follow-ups are one-time notifications for TODAY only.
///   They are cancelled when the user marks their wird complete.
///   When the app re-opens the next day, follow-ups are re-evaluated & re-scheduled.
class WirdNotificationService {
  static const String _channelId = 'wird_daily_reminder_v4';
  // Old channels to delete on first run so the user gets correct sound settings.
  static const List<String> _oldChannelIds = [
    'wird_daily_reminder_v1',
    'wird_daily_reminder_v2',
    'wird_daily_reminder_v3',
  ];
  static const String _channelName = 'الورد اليومي';
  static const String _channelDescription =
      'تذكير يومي بقراءة الورد اليومي من القرآن الكريم';

  // Green Islamic color
  static const int _primaryColorInt = 0xFF0D5E3A;

  static const int _idMainReminder = 5000;
  static const List<int> _followUpIds = [5001, 5002, 5003, 5004, 5005];
  static const List<int> _allIds = [5000, 5001, 5002, 5003, 5004, 5005];

  final FlutterLocalNotificationsPlugin _plugin;
  final WirdService _wirdService;

  WirdNotificationService(this._plugin, this._wirdService);

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    // Timezone is already initialised globally by AdhanNotificationService.
    await _createChannel();
  }

  Future<void> _createChannel() async {
    if (kIsWeb) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // Delete old channels to clear any stale sound / importance settings.
    for (final old in _oldChannelIds) {
      try {
        await android.deleteNotificationChannel(old);
      } catch (_) {}
    }

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,          // uses device default notification sound
        enableVibration: true,
      ),
    );
    debugPrint('📿 [Wird] Notification channel created: $_channelId');
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool ok = true;
    if (android != null) {
      ok = (await android.requestNotificationsPermission()) ?? true;
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
    }
    if (ios != null) {
      ok = (await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          true;
    }
    return ok;
  }

  // ── Main scheduling entry-point ───────────────────────────────────────────

  /// Call this after plan creation or reminder time update.
  /// Cancels all existing wird notifications and re-schedules them.
  Future<void> scheduleForPlan() async {
    if (!_wirdService.notificationsEnabled) {
      await cancelAll();
      return;
    }

    final plan = _wirdService.getPlan();
    if (plan == null) {
      await cancelAll();
      return;
    }

    final reminderTime = _wirdService.getReminderTime();
    if (reminderTime == null) {
      debugPrint('📿 [Wird] No reminder time set — skipping schedule');
      return;
    }

    final hour = reminderTime['hour']!;
    final minute = reminderTime['minute']!;

    await cancelAll();
    await _scheduleMainReminder(hour, minute);

    // Schedule today's follow-ups only if interval is not 0 ("Never").
    final todayIndex = plan.currentDay;
    if (_wirdService.followUpIntervalHours > 0 &&
        !plan.isDayComplete(todayIndex)) {
      await _scheduleFollowUps(hour, minute);
    }

    debugPrint('📿 [Wird] Scheduled daily reminder at $hour:$minute');
  }

  /// Re-evaluate follow-ups for today (call on app foreground).
  Future<void> refreshFollowUps() async {
    if (!_wirdService.notificationsEnabled) return;
    if (_wirdService.followUpIntervalHours == 0) {
      await cancelFollowUps();
      return;
    }
    final plan = _wirdService.getPlan();
    if (plan == null) return;
    final reminderTime = _wirdService.getReminderTime();
    if (reminderTime == null) return;

    // Cancel any stale follow-ups.
    await cancelFollowUps();

    final todayIndex = plan.currentDay;
    if (!plan.isDayComplete(todayIndex)) {
      await _scheduleFollowUps(
          reminderTime['hour']!, reminderTime['minute']!);
    }
  }

  // ── Internal scheduling ───────────────────────────────────────────────────

  Future<void> _scheduleMainReminder(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idMainReminder,
      '📖 حان وقت الورد اليومي',
      'لا تنس قراءة وردك اليومي من القرآن الكريم',
      scheduled,
      _buildDetails(isFollowUp: false),
      androidScheduleMode: await _scheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time, // Repeats every day.
    );
  }

  Future<void> _scheduleFollowUps(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    final todayBase =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // "Next-day reminder" boundary — follow-ups must fire before this moment.
    final nextDayBase = todayBase.add(const Duration(days: 1));

    // Use the user-configured interval (default 4 h), up to 5 follow-ups max.
    final intervalHours = _wirdService.followUpIntervalHours;
    final maxSlots = _followUpIds.length; // 5
    final offsets = List.generate(maxSlots, (i) => (i + 1) * intervalHours);

    int scheduledCount = 0;
    for (var i = 0; i < offsets.length; i++) {
      final followUpTime =
          todayBase.add(Duration(hours: offsets[i]));

      // Only schedule if in the future AND strictly before tomorrow's main reminder.
      if (followUpTime.isBefore(now) || !followUpTime.isBefore(nextDayBase)) {
        continue;
      }

      final hoursToNext = nextDayBase.difference(followUpTime).inHours;
      final body = hoursToNext <= 2
          ? 'اغتنم ما تبقى من الوقت وأكمل وردك اليومي 🌙'
          : 'لم تسجّل وردك بعد — لا تؤخر القراءة';

      await _plugin.zonedSchedule(
        _followUpIds[i],
        '🌙 تذكير: الورد اليومي',
        body,
        followUpTime,
        _buildDetails(isFollowUp: true),
        androidScheduleMode: await _scheduleMode(),
      );
      scheduledCount++;
    }

    debugPrint(
        '📿 [Wird] Scheduled $scheduledCount follow-up notification(s) (every $intervalHours h)');
  }

  // ── Test notification ───────────────────────────────────────────────────────

  /// Send an immediate test notification so the user can verify sound/appearance.
  Future<void> sendTestNotification() async {
    if (kIsWeb) return;
    await _plugin.show(
      5999,
      '📖 حان وقت الورد اليومي',
      'هذا إشعار تجريبي — سيصلك هكذا كل يوم 🌙',
      _buildDetails(isFollowUp: false),
    );
    debugPrint('📿 [Wird] Test notification sent');
  }

  // ── Cancellation helpers ──────────────────────────────────────────────────

  /// Cancel ONLY today's follow-up reminders (when wird is marked complete).
  Future<void> cancelFollowUps() async {
    for (final id in _followUpIds) {
      await _plugin.cancel(id);
    }
    debugPrint('📿 [Wird] Follow-up notifications cancelled');
  }

  /// Cancel ALL wird notifications (on plan reset / app cleanup).
  Future<void> cancelAll() async {
    for (final id in _allIds) {
      await _plugin.cancel(id);
    }
    debugPrint('📿 [Wird] All wird notifications cancelled');
  }

  // ── Notification style ────────────────────────────────────────────────────

  NotificationDetails _buildDetails({required bool isFollowUp}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,          // device default sound
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        icon: '@drawable/ic_notification',
        color: const Color(_primaryColorInt),
        ticker: isFollowUp ? 'تذكير بالورد اليومي' : 'حان وقت الورد اليومي',
        ongoing: false,
        autoCancel: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final canExact = await android.canScheduleExactNotifications();
      return (canExact ?? false)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }
}
