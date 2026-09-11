import 'package:equatable/equatable.dart';

class SessionModel extends Equatable {
  final String sessionId;
  final String loginTime;
  final String logoutTime;
  final int durationSeconds;
  final String reasonOrStatus;

  const SessionModel({
    required this.sessionId,
    required this.loginTime,
    required this.logoutTime,
    required this.durationSeconds,
    required this.reasonOrStatus,
  });

  @override
  List<Object?> get props => [sessionId, loginTime, logoutTime, durationSeconds, reasonOrStatus];
}
