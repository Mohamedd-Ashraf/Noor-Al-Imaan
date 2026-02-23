import 'package:equatable/equatable.dart';
import '../../data/wird_service.dart';

abstract class WirdState extends Equatable {
  const WirdState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the service is queried.
class WirdInitial extends WirdState {
  const WirdInitial();
}

/// No active plan exists – show setup UI.
class WirdNoPlan extends WirdState {
  final bool notificationsEnabled;
  final int followUpIntervalHours;
  const WirdNoPlan({
    this.notificationsEnabled = true,
    this.followUpIntervalHours = 4,
  });

  @override
  List<Object?> get props => [notificationsEnabled, followUpIntervalHours];
}

/// An active plan is loaded and ready to display.
class WirdPlanLoaded extends WirdState {
  final WirdPlan plan;

  /// Current reminder time (null if not set yet).
  final int? reminderHour;
  final int? reminderMinute;

  /// Whether wird notifications are enabled.
  final bool notificationsEnabled;

  /// Hours between follow-up reminders.
  final int followUpIntervalHours;

  const WirdPlanLoaded(
    this.plan, {
    this.reminderHour,
    this.reminderMinute,
    this.notificationsEnabled = true,
    this.followUpIntervalHours = 4,
  });

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  @override
  List<Object?> get props => [
        plan.type,
        plan.startDate,
        plan.targetDays,
        plan.completedDays,
        reminderHour,
        reminderMinute,
        notificationsEnabled,
        followUpIntervalHours,
      ];
}
