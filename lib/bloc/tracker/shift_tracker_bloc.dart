import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'shift_tracker_event.dart';
import 'shift_tracker_state.dart';

class ShiftTrackerBloc extends Bloc<ShiftTrackerEvent, ShiftTrackerState> {
  Timer? _tickerTimer;

  ShiftTrackerBloc() : super(ShiftTrackerState.initial()) {
    on<StartShiftEvent>((event, emit) {
      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        add(TimerTickEvent());
      });

      emit(state.copyWith(
        status: ShiftStatus.working,
        loginSessionsCount: state.isOffline ? state.loginSessionsCount + 1 : state.loginSessionsCount,
      ));
    });

    on<PauseShiftEvent>((event, emit) {
      _tickerTimer?.cancel();
      emit(state.copyWith(status: ShiftStatus.paused));
    });

    on<ResumeShiftEvent>((event, emit) {
      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        add(TimerTickEvent());
      });
      emit(state.copyWith(status: ShiftStatus.working));
    });

    on<StopShiftEvent>((event, emit) {
      _tickerTimer?.cancel();
      emit(state.copyWith(
        status: ShiftStatus.offline,
        currentSessionSeconds: 0,
      ));
    });

    on<TimerTickEvent>((event, emit) {
      if (state.status != ShiftStatus.working) return;

      int newNormal = state.normalWorkingSeconds;
      int newExtra = state.extraWorkingSeconds;

      if (newNormal < ShiftTrackerState.maxNormalSeconds) {
        newNormal += 1;
      } else if (newExtra < ShiftTrackerState.maxExtraSeconds) {
        newExtra += 1;
      }

      final newTotal = newNormal + newExtra;
      final newRemaining = ShiftTrackerState.maxTotalSeconds - newTotal;
      final newCurrentSession = state.currentSessionSeconds + 1;

      emit(state.copyWith(
        normalWorkingSeconds: newNormal,
        extraWorkingSeconds: newExtra,
        totalWorkingSeconds: newTotal,
        remainingSeconds: newRemaining > 0 ? newRemaining : 0,
        currentSessionSeconds: newCurrentSession,
      ));
    });

    on<SyncWithServerEvent>((event, emit) {
      if (event.status == ShiftStatus.working && _tickerTimer == null) {
        _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          add(TimerTickEvent());
        });
      } else if (event.status != ShiftStatus.working) {
        _tickerTimer?.cancel();
        _tickerTimer = null;
      }

      emit(state.copyWith(
        status: event.status,
        currentSessionSeconds: event.currentSessionSeconds,
        normalWorkingSeconds: event.normalWorkingSeconds,
        extraWorkingSeconds: event.extraWorkingSeconds,
        totalWorkingSeconds: event.totalWorkingSeconds,
        remainingSeconds: event.remainingSeconds,
        loginSessionsCount: event.loginSessionsCount,
      ));
    });
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }
}
