import 'package:flutter_bloc/flutter_bloc.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc() : super(AttendanceState.initial()) {
    on<AddSessionRecord>((event, emit) {
      final updatedList = [event.session, ...state.sessionHistory];
      emit(state.copyWith(
        sessionHistory: updatedList,
        totalSessions: updatedList.length,
        lastLogout: event.session.logoutTime,
        totalWorkingSeconds: state.totalWorkingSeconds + event.session.durationSeconds,
      ));
    });
  }
}
