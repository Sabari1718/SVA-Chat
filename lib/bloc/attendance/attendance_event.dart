import 'package:equatable/equatable.dart';
import '../../models/session_model.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceHistory extends AttendanceEvent {}

class SyncAttendanceHistory extends AttendanceEvent {
  final List<SessionModel> sessions;
  final String firstLogin;
  final String lastLogout;
  final int totalWorkingSeconds;
  final int totalSessions;

  const SyncAttendanceHistory({
    required this.sessions,
    required this.firstLogin,
    required this.lastLogout,
    required this.totalWorkingSeconds,
    required this.totalSessions,
  });

  @override
  List<Object?> get props => [sessions, firstLogin, lastLogout, totalWorkingSeconds, totalSessions];
}

class AddSessionRecord extends AttendanceEvent {
  final SessionModel session;

  const AddSessionRecord(this.session);

  @override
  List<Object?> get props => [session];
}
