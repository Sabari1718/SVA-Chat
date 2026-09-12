import 'package:equatable/equatable.dart';
import '../../models/admin_dashboard_model.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  final AdminDashboardModel? previousData;

  const AdminDashboardLoading({this.previousData});

  @override
  List<Object?> get props => [previousData];
}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminDashboardModel data;
  final DateTime lastUpdated;
  final Map<String, dynamic>? employeeSessionData;
  final Map<String, dynamic>? employeeDailyData;

  const AdminDashboardLoaded({
    required this.data,
    required this.lastUpdated,
    this.employeeSessionData,
    this.employeeDailyData,
  });

  @override
  List<Object?> get props => [
        data,
        lastUpdated,
        employeeSessionData,
        employeeDailyData,
      ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  final AdminDashboardModel? fallbackData;
  final bool isSessionExpired;

  const AdminDashboardError({
    required this.message,
    this.fallbackData,
    this.isSessionExpired = false,
  });

  @override
  List<Object?> get props => [message, fallbackData, isSessionExpired];
}
