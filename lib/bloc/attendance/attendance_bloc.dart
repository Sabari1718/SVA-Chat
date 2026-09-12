import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/session_model.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc() : super(AttendanceState.initial()) {
    on<AddSessionRecord>((event, emit) {
      final updatedHistory = <SessionModel>[event.session, ...state.sessionHistory];
      emit(state.copyWith(
        sessionHistory: updatedHistory,
        totalSessions: state.totalSessions + 1,
        totalWorkingSeconds: state.totalWorkingSeconds + event.session.durationSeconds,
        lastLogout: event.session.logoutTime.isNotEmpty ? event.session.logoutTime : state.lastLogout,
        firstLogin: state.firstLogin == '--:--' ? event.session.loginTime : state.firstLogin,
      ));
    });
    
    on<SyncAttendanceHistory>((event, emit) {
      emit(state.copyWith(
        firstLogin: event.firstLogin,
        lastLogout: event.lastLogout,
        totalSessions: event.totalSessions,
        totalWorkingSeconds: event.totalWorkingSeconds,
        sessionHistory: event.sessions,
        todayDate: DateTime.now().toIso8601String().split('T').first,
      ));
    });
  }
}
