import 'package:equatable/equatable.dart';
import '../../models/session_model.dart';

class AttendanceState extends Equatable {
  final String firstLogin;
  final String lastLogout;
  final int totalSessions;
  final int totalWorkingSeconds;
  final List<SessionModel> sessionHistory;
  final String todayDate;

  const AttendanceState({
    required this.firstLogin,
    required this.lastLogout,
    required this.totalSessions,
    required this.totalWorkingSeconds,
    required this.sessionHistory,
    required this.todayDate,
  });

  factory AttendanceState.initial() {
    return const AttendanceState(
      firstLogin: '10:35 AM',
      lastLogout: '11:10 AM',
      totalSessions: 1,
      totalWorkingSeconds: 2100, // 35m
      todayDate: '11/09/2026',
      sessionHistory: [
        SessionModel(
          sessionId: 'sess-1789103118245-839',
          loginTime: '10:35 AM',
          logoutTime: '11:10 AM',
          durationSeconds: 2100,
          reasonOrStatus: 'manual',
        ),
      ],
    );
  }

  AttendanceState copyWith({
    String? firstLogin,
    String? lastLogout,
    int? totalSessions,
    int? totalWorkingSeconds,
    List<SessionModel>? sessionHistory,
    String? todayDate,
  }) {
    return AttendanceState(
      firstLogin: firstLogin ?? this.firstLogin,
      lastLogout: lastLogout ?? this.lastLogout,
      totalSessions: totalSessions ?? this.totalSessions,
      totalWorkingSeconds: totalWorkingSeconds ?? this.totalWorkingSeconds,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      todayDate: todayDate ?? this.todayDate,
    );
  }

  @override
  List<Object?> get props => [
        firstLogin,
        lastLogout,
        totalSessions,
        totalWorkingSeconds,
        sessionHistory,
        todayDate,
      ];
}
