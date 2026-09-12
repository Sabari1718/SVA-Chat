import 'package:equatable/equatable.dart';

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchAdminDashboardData extends AdminDashboardEvent {
  final String token;
  final bool isRefresh;

  const FetchAdminDashboardData({
    required this.token,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [token, isRefresh];
}

class TriggerAdminHeartbeat extends AdminDashboardEvent {
  final String token;

  const TriggerAdminHeartbeat({required this.token});

  @override
  List<Object?> get props => [token];
}

class StartEmployeeSession extends AdminDashboardEvent {
  final String token;

  const StartEmployeeSession({required this.token});

  @override
  List<Object?> get props => [token];
}
