import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/admin/admin_dashboard_bloc.dart';
import '../../bloc/admin/admin_dashboard_event.dart';
import '../../bloc/admin/admin_dashboard_state.dart';
import '../../bloc/tracker/shift_tracker_bloc.dart';
import '../../bloc/tracker/shift_tracker_event.dart';
import '../../bloc/tracker/shift_tracker_state.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../models/session_model.dart';
import 'widgets/admin_dashboard_view.dart';
import 'widgets/header_profile_card.dart';
import 'widgets/working_time_tracker_card.dart';
import 'widgets/metric_status_grid.dart';
import 'widgets/attendance_history_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final user = authState.user;
        final token = user.token ?? '';
        if (token.isNotEmpty && !user.isAdmin) {
          context.read<AdminDashboardBloc>().add(StartEmployeeSession(token: token));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthenticatedState ? authState.user : null;
        final isAdmin = user?.isAdmin ?? false;

        if (isAdmin) {
          return const AdminDashboardView();
        }

        return BlocListener<AdminDashboardBloc, AdminDashboardState>(
          listener: (context, state) {
            if (state is AdminDashboardLoaded) {
              final currentData = state.employeeSessionData;
              final dailyData = state.employeeDailyData;

              if (currentData != null) {
                final statusStr = (currentData['status'] as String? ?? '').toUpperCase();
                final currentSeconds = currentData['currentWorkingSeconds'] as int? ?? 0;
                final normalSeconds = currentData['normalWorkingSeconds'] as int? ?? 0;
                final extraSeconds = currentData['extraWorkingSeconds'] as int? ?? 0;
                final totalSeconds = currentData['totalWorkingSeconds'] as int? ?? 0;
                final remainingSeconds = currentData['remainingSeconds'] as int? ?? 0;

                final sessionsCount = dailyData?['totalSessions'] as int? ?? 0;

                ShiftStatus mappedStatus = ShiftStatus.offline;
                if (statusStr == 'WORKING') {
                  mappedStatus = ShiftStatus.working;
                } else if (statusStr == 'PAUSED') {
                  mappedStatus = ShiftStatus.paused;
                }

                context.read<ShiftTrackerBloc>().add(
                      SyncWithServerEvent(
                        currentSessionSeconds: currentSeconds,
                        normalWorkingSeconds: normalSeconds,
                        extraWorkingSeconds: extraSeconds,
                        totalWorkingSeconds: totalSeconds,
                        remainingSeconds: remainingSeconds,
                        status: mappedStatus,
                        loginSessionsCount: sessionsCount,
                      ),
                    );
                if (dailyData != null) {
                  final rawSessions = dailyData['sessions'] as List<dynamic>? ?? [];
                  final sessions = rawSessions.map((s) {
                    return SessionModel(
                      sessionId: s['sessionId'] ?? '',
                      loginTime: s['loginTime'] ?? '',
                      logoutTime: s['logoutTime'] ?? '',
                      durationSeconds: s['durationSeconds'] ?? 0,
                      reasonOrStatus: s['logoutReason'] ?? s['status'] ?? '',
                    );
                  }).toList();

                  context.read<AttendanceBloc>().add(
                    SyncAttendanceHistory(
                      sessions: sessions,
                      firstLogin: dailyData['firstLogin'] ?? '--:--',
                      lastLogout: dailyData['lastLogout'] ?? '--:--',
                      totalWorkingSeconds: dailyData['totalWorkingSeconds'] ?? 0,
                      totalSessions: dailyData['totalSessions'] ?? 0,
                    ),
                  );
                }

              }
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // 1. Header Profile & Status Card
                  const HeaderProfileCard()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // 2. Daily Working Time Tracker Card (4 Timers)
                  const WorkingTimeTrackerCard()
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // 3. Status Overview 4-Card Grid
                  const MetricStatusGrid()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // 4. Daily Attendance / Login History
                  const AttendanceHistoryCard()
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 30),
                ],
              ), // Column
            ), // ConstrainedBox
          ), // Center
        ), // SingleChildScrollView
      ), // SafeArea
    ), // Scaffold
  ); // BlocListener
  },
); // BlocBuilder
}
}
