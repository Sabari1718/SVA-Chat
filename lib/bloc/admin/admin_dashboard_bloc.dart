import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/admin_dashboard_model.dart';
import '../../repositories/admin_repository.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminRepository _repository;
  Timer? _heartbeatTimer;

  AdminDashboardBloc({AdminRepository? repository})
      : _repository = repository ?? AdminRepository(),
        super(const AdminDashboardInitial()) {
    on<FetchAdminDashboardData>(_onFetchDashboard);
    on<TriggerAdminHeartbeat>(_onTriggerHeartbeat);
    on<StartEmployeeSession>(_onStartEmployeeSession);
  }

  Future<void> _onStartEmployeeSession(
    StartEmployeeSession event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    
    // We run initEmployeeSession to trigger heartbeat and unread, but we also fetch session data
    await _repository.initEmployeeSession(event.token);
    final sessionCurrent = await _repository.fetchEmployeeSessionCurrent(event.token);
    final sessionDaily = await _repository.fetchEmployeeSessionDaily(event.token, DateTime.now().toIso8601String().split('T').first);

    emit(AdminDashboardLoaded(
      data: AdminDashboardModel.defaultFallback, // Dummy data for employee since they don't see admin stats
      lastUpdated: DateTime.now(),
      employeeSessionData: sessionCurrent,
      employeeDailyData: sessionDaily,
    ));

    _startHeartbeatTimer(event.token);
  }

  Future<void> _onFetchDashboard(
    FetchAdminDashboardData event,
    Emitter<AdminDashboardState> emit,
  ) async {
    AdminDashboardModel? currentData;
    if (state is AdminDashboardLoaded) {
      currentData = (state as AdminDashboardLoaded).data;
    }

    if (!event.isRefresh) {
      emit(AdminDashboardLoading(previousData: currentData));
    }

    try {
      final freshData = await _repository.fetchAdminDashboardData(event.token);
      emit(AdminDashboardLoaded(
        data: freshData,
        lastUpdated: DateTime.now(),
      ));

      // Start periodic heartbeat every 60 seconds if not already running
      _startHeartbeatTimer(event.token);
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AdminDashboardError(
        message: cleanMsg,
        fallbackData: currentData ?? AdminDashboardModel.defaultFallback,
      ));
    }
  }

  Future<void> _onTriggerHeartbeat(
    TriggerAdminHeartbeat event,
    Emitter<AdminDashboardState> emit,
  ) async {
    final status = await _repository.sendHeartbeat(event.token);
    if (status == 401 || status == 403) {
      _heartbeatTimer?.cancel();
      emit(const AdminDashboardError(
        message: 'Session expired. Please log in again.',
        isSessionExpired: true,
      ));
      return;
    }

    if (state is AdminDashboardLoaded) {
      final currentState = state as AdminDashboardLoaded;
      final sessionCurrent = await _repository.fetchEmployeeSessionCurrent(event.token);
      final sessionDaily = await _repository.fetchEmployeeSessionDaily(event.token, DateTime.now().toIso8601String().split('T').first);

      emit(AdminDashboardLoaded(
        data: currentState.data,
        lastUpdated: DateTime.now(),
        employeeSessionData: sessionCurrent,
        employeeDailyData: sessionDaily,
      ));
    }
  }

  void _startHeartbeatTimer(String token) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      add(TriggerAdminHeartbeat(token: token));
    });
  }

  @override
  Future<void> close() {
    _heartbeatTimer?.cancel();
    return super.close();
  }
}
