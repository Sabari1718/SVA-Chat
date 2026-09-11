import 'package:equatable/equatable.dart';

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
