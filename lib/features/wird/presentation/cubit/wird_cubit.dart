import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/wird_service.dart';
import '../../services/wird_notification_service.dart';
import 'wird_state.dart';

class WirdCubit extends Cubit<WirdState> {
  final WirdService _wirdService;
  final WirdNotificationService _notifService;

  WirdCubit(this._wirdService, this._notifService)
      : super(const WirdInitial());

  // ── Test notification ─────────────────────────────────────────────────

  Future<void> testNotification() => _notifService.sendTestNotification();

  // ── Load ────────────────────────────────────────────────────────────

  /// Load (or reload) the plan from SharedPreferences.
  void load() {
    final plan = _wirdService.getPlan();
    final notifEnabled = _wirdService.notificationsEnabled;
    final followUpInterval = _wirdService.followUpIntervalHours;
    if (plan == null) {
      emit(WirdNoPlan(
        notificationsEnabled: notifEnabled,
        followUpIntervalHours: followUpInterval,
      ));
    } else {
      final rt = _wirdService.getReminderTime();
      emit(WirdPlanLoaded(
        plan,
        reminderHour: rt?['hour'],
        reminderMinute: rt?['minute'],
        notificationsEnabled: notifEnabled,
        followUpIntervalHours: followUpInterval,
        lastReadSurah: _wirdService.lastReadSurah,
        lastReadAyah: _wirdService.lastReadAyah,
      ));
    }
  }

  // ── Plan setup ──────────────────────────────────────────────────

  /// Create a new wird plan (generic, also used by regular plans).
  Future<void> setupPlan({
    required WirdType type,
    required int targetDays,
    required DateTime startDate,
    List<int> completedDays = const [],
    int? reminderHour,
    int? reminderMinute,
  }) async {
    await _wirdService.initPlan(
      type: type,
      targetDays: targetDays,
      startDate: startDate,
      completedDays: completedDays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    load();
    if (reminderHour != null && reminderMinute != null) {
      await _notifService.scheduleForPlan();
    }
  }

  // ── Day completion ─────────────────────────────────────────────

  /// Toggle the completion state of a specific day (1-indexed).
  Future<void> toggleDayComplete(int day) async {
    final currentState = state;
    if (currentState is! WirdPlanLoaded) return;

    final wasComplete = currentState.plan.isDayComplete(day);
    if (wasComplete) {
      await _wirdService.markDayIncomplete(day);
      // If un-completing today, re-schedule follow-ups.
      final todayDay = currentState.plan.currentDay;
      if (day == todayDay) {
        await _notifService.refreshFollowUps();
      }
    } else {
      await _wirdService.markDayComplete(day);
      // If completing today, cancel follow-up reminders + clear reading bookmark.
      final todayDay = currentState.plan.currentDay;
      if (day == todayDay) {
        await _notifService.cancelFollowUps();
        await _wirdService.clearLastRead();
      }
    }
    load();
  }

  // ── Reminder time ───────────────────────────────────────────────

  Future<void> updateReminderTime(int hour, int minute) async {
    await _wirdService.setReminderTime(hour, minute);
    load();
    await _notifService.scheduleForPlan();
  }

  // ── App lifecycle ─────────────────────────────────────────────

  /// Call when app returns to foreground to refresh today's follow-up notifications.
  Future<void> refreshNotificationsIfNeeded() async {
    final plan = _wirdService.getPlan();
    if (plan == null) return;
    if (_wirdService.hasReminder) {
      await _notifService.refreshFollowUps();
    }
  }

  // ── Plan deletion ─────────────────────────────────────────────

  Future<void> deletePlan() async {
    await _notifService.cancelAll();
    await _wirdService.clearPlan();
    emit(WirdNoPlan(notificationsEnabled: _wirdService.notificationsEnabled));
  }

  // ── Follow-up interval ─────────────────────────────────────────────────────

  Future<void> setFollowUpIntervalHours(int hours) async {
    await _wirdService.setFollowUpIntervalHours(hours);
    if (_wirdService.notificationsEnabled && _wirdService.hasReminder) {
      await _notifService.scheduleForPlan();
    }
    load();
  }

  // ── Notifications toggle ──────────────────────────────────────────────────

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _wirdService.setNotificationsEnabled(enabled);
    if (!enabled) {
      await _notifService.cancelAll();
    } else {
      // Re-schedule if a plan with a reminder time already exists.
      if (_wirdService.hasReminder) {
        await _notifService.scheduleForPlan();
      }
    }
    load();
  }
  // ── Reading bookmark (last-read position) ─────────────────────────────────

  /// Saves the user’s current reading position (called when they tap “حدّث موضعي”).
  Future<void> saveLastRead(int surah, int ayah) async {
    await _wirdService.saveLastRead(surah, ayah);
    load();
  }

  /// Clears the reading bookmark (also called automatically when day is marked complete).
  Future<void> clearLastRead() async {
    await _wirdService.clearLastRead();
    load();
  }}
