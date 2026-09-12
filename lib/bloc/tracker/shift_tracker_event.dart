import 'package:equatable/equatable.dart';
import 'shift_tracker_state.dart';

abstract class ShiftTrackerEvent extends Equatable {
  const ShiftTrackerEvent();

  @override
  List<Object?> get props => [];
}

class StartShiftEvent extends ShiftTrackerEvent {}

class PauseShiftEvent extends ShiftTrackerEvent {}

class ResumeShiftEvent extends ShiftTrackerEvent {}

class StopShiftEvent extends ShiftTrackerEvent {}

class TimerTickEvent extends ShiftTrackerEvent {}

class SyncWithServerEvent extends ShiftTrackerEvent {
  final int currentSessionSeconds;
  final int normalWorkingSeconds;
  final int extraWorkingSeconds;
  final int totalWorkingSeconds;
  final int remainingSeconds;
  final ShiftStatus status;
  final int loginSessionsCount;

  const SyncWithServerEvent({
    required this.currentSessionSeconds,
    required this.normalWorkingSeconds,
    required this.extraWorkingSeconds,
    required this.totalWorkingSeconds,
    required this.remainingSeconds,
    required this.status,
    required this.loginSessionsCount,
  });

  @override
  List<Object?> get props => [
        currentSessionSeconds,
        normalWorkingSeconds,
        extraWorkingSeconds,
        totalWorkingSeconds,
        remainingSeconds,
        status,
        loginSessionsCount,
      ];
}
