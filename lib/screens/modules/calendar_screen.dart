import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/tracker/shift_tracker_bloc.dart';
import '../../bloc/tracker/shift_tracker_event.dart';
import '../../bloc/tracker/shift_tracker_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import '../../repositories/admin_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AdminRepository _adminRepo = AdminRepository();

  bool _isLoading = false;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _allSessions = [];
  Map<int, Map<String, dynamic>> _attendanceByDay = {};

  Map<String, dynamic>? _selectedEmployee;
  DateTime _displayedMonth = DateTime(2026, 9, 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData();
    });
  }

  String _getToken() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.token ?? '';
    }
    return '';
  }

  Future<void> _loadCalendarData() async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final monthStr = DateFormat('yyyy-MM').format(_displayedMonth);
      final empId = _selectedEmployee?['id'] as String?;

      final results = await Future.wait([
        _adminRepo.getEmployees(token),
        _adminRepo.getEmployeeAttendance(token, monthStr, employeeId: empId),
      ]);

      if (mounted) {
        final emps = results[0] as List<Map<String, dynamic>>;
        final attendanceMap = results[1] as Map<String, dynamic>?;

        final Map<int, Map<String, dynamic>> attByDay = {};
        final List<Map<String, dynamic>> sessions = [];

        if (attendanceMap != null && attendanceMap['attendance'] is List) {
          final attList = attendanceMap['attendance'] as List;
          for (var item in attList) {
            if (item is Map) {
              final dayMap = Map<String, dynamic>.from(item);
              final dateStr = dayMap['date'] as String?;
              if (dateStr != null) {
                try {
                  final dt = DateTime.parse(dateStr);
                  if (dt.year == _displayedMonth.year && dt.month == _displayedMonth.month) {
                    attByDay[dt.day] = dayMap;
                  }
                } catch (_) {}
              }
              if (dayMap['sessions'] is List) {
                for (var s in dayMap['sessions']) {
                  if (s is Map) {
                    sessions.add(Map<String, dynamic>.from(s));
                  }
                }
              }
            }
          }
        }

        final authState = context.read<AuthBloc>().state;
        final currentUser = authState is AuthenticatedState ? authState.user : null;
        final isAdmin = currentUser?.isAdmin ?? false;

        Map<String, dynamic>? autoSelect = _selectedEmployee;
        if (autoSelect == null) {
          if (!isAdmin && currentUser != null) {
            autoSelect = emps.firstWhere(
              (e) => e['id'] == currentUser.id || (e['email'] as String? ?? '').toLowerCase() == currentUser.email.toLowerCase(),
              orElse: () => {'id': currentUser.id, 'name': currentUser.name, 'role': currentUser.role},
            );
          } else if (attendanceMap != null && attendanceMap['employee'] is Map) {
            final apiEmp = Map<String, dynamic>.from(attendanceMap['employee']);
            final apiEmpId = apiEmp['id'] as String? ?? '';
            if (apiEmpId.isNotEmpty) {
              autoSelect = emps.firstWhere(
                (e) => e['id'] == apiEmpId,
                orElse: () => apiEmp,
              );
            }
          } else if (emps.isNotEmpty) {
            autoSelect = emps.first;
          }
        } else {
          // Keep existing selection matched from updated emps list
          final currentId = autoSelect['id'];
          autoSelect = emps.firstWhere(
            (e) => e['id'] == currentId,
            orElse: () => autoSelect!,
          );
        }

        setState(() {
          _employees = emps;
          _allSessions = sessions;
          _attendanceByDay = attByDay;
          _selectedEmployee = autoSelect;
        });
      }
    } catch (e) {
      debugPrint('[CalendarScreen] error loading calendar data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filter sessions for the selected employee in the displayed month
  List<Map<String, dynamic>> _getFilteredSessions() {
    if (_selectedEmployee == null) return [];

    final empId = _selectedEmployee!['id'] as String? ?? '';
    final empName = (_selectedEmployee!['name'] as String? ?? '').trim().toLowerCase();

    return _allSessions.where((s) {
      final sEmpId = s['employeeId'] as String? ?? s['userId'] as String? ?? '';
      final sUserName = (s['userName'] as String? ?? '').trim().toLowerCase();

      final matchesEmp = (empId.isNotEmpty && sEmpId == empId) || (empName.isNotEmpty && sUserName == empName);
      if (!matchesEmp) return false;

      final loginStr = s['loginAt'] as String? ?? s['workStartTime'] as String?;
      if (loginStr == null) return false;

      try {
        final dt = DateTime.parse(loginStr);
        return dt.year == _displayedMonth.year && dt.month == _displayedMonth.month;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // Sessions grouped by calendar day (1..31)
  Map<int, List<Map<String, dynamic>>> _getSessionsByDay(List<Map<String, dynamic>> sessions) {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final s in sessions) {
      final loginStr = s['loginAt'] as String? ?? s['workStartTime'] as String?;
      if (loginStr == null) continue;
      try {
        final dt = DateTime.parse(loginStr);
        map.putIfAbsent(dt.day, () => []).add(s);
      } catch (_) {}
    }
    return map;
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _formatTimeStr(dynamic val) {
    if (val == null) return '--:--';
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null') return '--:--';
    try {
      final dt = DateTime.parse(str);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return str;
    }
  }

  void _showDaySessionsSheet(int day, List<Map<String, dynamic>> daySessions) {
    final monthName = DateFormat('MMMM yyyy').format(_displayedMonth);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$monthName $day Sessions',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (daySessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No recorded sessions on this date.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: daySessions.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, idx) {
                        final s = daySessions[idx];
                        final rawLogin = s['loginTime'] ?? s['login_time'] ?? s['loginAt'] ?? s['workStartTime'];
                        final rawLogout = s['logoutTime'] ?? s['logout_time'] ?? s['logoutAt'];
                        final loginTime = _formatTimeStr(rawLogin);
                        final logoutTime = rawLogout == null ? 'Active' : _formatTimeStr(rawLogout);
                        final duration = s['session_duration'] ?? s['durationFormatted'] ?? s['totalWorkingHours'] ?? (s['durationSeconds'] != null ? _formatDuration(s['durationSeconds'] as int) : (s['totalSeconds'] != null ? _formatDuration(s['totalSeconds'] as int) : '--'));
                        final status = (s['status'] as String? ?? (rawLogout == null ? 'Active' : 'Logged Out'));
                        final isWorking = status.toUpperCase() == 'WORKING' || status.toUpperCase() == 'ACTIVE';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isWorking ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isWorking ? Icons.timer_outlined : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: isWorking ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session #${idx + 1} ($duration)',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      'Login: $loginTime  •  Logout: $logoutTime',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isWorking ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isWorking ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveTimerPill() {
    return BlocBuilder<ShiftTrackerBloc, ShiftTrackerState>(
      builder: (context, trackerState) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF3B82F6)),
              const SizedBox(width: 4),
              Text(
                'Time: ${TimeFormatter.formatHms(trackerState.normalWorkingSeconds)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              if (trackerState.isWorking)
                InkWell(
                  onTap: () => context.read<ShiftTrackerBloc>().add(PauseShiftEvent()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_rounded, size: 10, color: Color(0xFFD97706)),
                        const SizedBox(width: 2),
                        Text(
                          'Pause',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trackerState.isWorking ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trackerState.isWorking ? const Color(0xFF10B981) : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trackerState.isWorking ? 'Working' : (trackerState.isPaused ? 'Paused' : 'Shift Off'),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: trackerState.isWorking ? const Color(0xFF047857) : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthenticatedState ? authState.user : null;
        final isAdmin = user?.isAdmin ?? false;

        final sessions = _getFilteredSessions();
        final sessionsByDay = _getSessionsByDay(sessions);

        // Metrics calculations prioritizing _attendanceByDay
        int workingDaysCount = 0;
        int normalMsSum = 0;
        int extraMsSum = 0;
        int totalMsSum = 0;
        int overtimeDaysCount = 0;

        if (_attendanceByDay.isNotEmpty) {
          for (final entry in _attendanceByDay.entries) {
            final dayData = entry.value;
            final worked = dayData['worked'] == true || (dayData['totalMs'] as num? ?? 0) > 0;
            if (worked) {
              workingDaysCount++;
            }
            normalMsSum += (dayData['normalMs'] as num? ?? 0).toInt();
            extraMsSum += (dayData['extraMs'] as num? ?? 0).toInt();
            totalMsSum += (dayData['totalMs'] as num? ?? 0).toInt();
            if (dayData['hasOvertime'] == true || (dayData['extraMs'] as num? ?? 0) > 0) {
              overtimeDaysCount++;
            }
          }
        } else {
          workingDaysCount = sessionsByDay.keys.length;
          for (final entry in sessionsByDay.entries) {
            int dailySeconds = 0;
            for (final s in entry.value) {
              dailySeconds += (s['totalSeconds'] as int? ?? 0);
            }
            totalMsSum += dailySeconds * 1000;
            if (dailySeconds > 8 * 3600) {
              normalMsSum += (8 * 3600) * 1000;
              extraMsSum += (dailySeconds - 8 * 3600) * 1000;
              overtimeDaysCount++;
            } else {
              normalMsSum += dailySeconds * 1000;
            }
          }
        }

        final normalHoursStr = _formatDuration(normalMsSum ~/ 1000);
        final extraHoursStr = _formatDuration(extraMsSum ~/ 1000);
        final avgDailySeconds = workingDaysCount > 0 ? ((totalMsSum ~/ 1000) ~/ workingDaysCount) : 0;
        final avgDailyStr = _formatDuration(avgDailySeconds);

        final hasSelected = _selectedEmployee != null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: canPop
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  title: Text(
                    'Work & Attendance Calendar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF4F46E5),
                    backgroundColor: Color(0xFFEEF2FF),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadCalendarData,
                    color: const Color(0xFF4F46E5),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Page Header matching Web DevTools
                        LayoutBuilder(
                          builder: (context, headerConstraints) {
                            final isWide = headerConstraints.maxWidth > 650;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_month_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Work & Attendance Calendar',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'View daily login / logout sessions, working hours, and Work From Home status for each day.',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isWide) ...[
                                      const SizedBox(width: 12),
                                      _buildLiveTimerPill(),
                                    ],
                                  ],
                                ),
                                if (!isWide) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildLiveTimerPill(),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // 2. Admin Employee Selector Dropdown (Screenshots 3, 4, 5)
                        if (isAdmin) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF4F46E5)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Viewing Employee:',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (hasSelected)
                                      Expanded(
                                        child: Text(
                                          'Showing: ${_selectedEmployee!['name']}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF4F46E5),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<Map<String, dynamic>?>(
                                      value: _selectedEmployee,
                                      isExpanded: true,
                                      hint: Text(
                                        '— Select an Employee —',
                                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                      ),
                                      items: [
                                        DropdownMenuItem<Map<String, dynamic>?>(
                                          value: null,
                                          child: Text(
                                            '— Select an Employee —',
                                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                          ),
                                        ),
                                        ..._employees.map((emp) {
                                          final name = emp['name'] as String? ?? 'Employee';
                                          final role = emp['role'] as String? ?? '';
                                          return DropdownMenuItem<Map<String, dynamic>?>(
                                            value: emp,
                                            child: Text('$name ($role)', style: GoogleFonts.inter(fontSize: 13)),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() => _selectedEmployee = val);
                                        _loadCalendarData();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. 5 Metric Summary Pods (Screenshots 3 & 4)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return GridView.count(
                              crossAxisCount: isWide ? 5 : (constraints.maxWidth > 500 ? 3 : 2),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: isWide ? 1.6 : 1.4,
                              children: [
                                _buildSummaryCard(
                                  hasSelected ? '$workingDaysCount' : '0',
                                  'Working Days',
                                  Icons.calendar_today_outlined,
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFFF5F3FF),
                                ),
                                _buildSummaryCard(
                                  hasSelected ? normalHoursStr : '0h 00m',
                                  'Normal Hours',
                                  Icons.access_time_rounded,
                                  const Color(0xFF3B82F6),
                                  const Color(0xFFEFF6FF),
                                ),
                                _buildSummaryCard(
                                  hasSelected ? extraHoursStr : '0h 00m',
                                  'Extra Hours',
                                  Icons.timer_outlined,
                                  const Color(0xFFF97316),
                                  const Color(0xFFFFF7ED),
                                ),
                                _buildSummaryCard(
                                  hasSelected ? avgDailyStr : '0h 00m',
                                  'Avg / Day',
                                  Icons.bar_chart_rounded,
                                  const Color(0xFF10B981),
                                  const Color(0xFFECFDF5),
                                ),
                                _buildSummaryCard(
                                  hasSelected ? '$overtimeDaysCount' : '0',
                                  'Overtime Days',
                                  Icons.bolt_rounded,
                                  const Color(0xFFF43F5E),
                                  const Color(0xFFFFF1F2),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. Calendar Container OR Empty State
                        if (!hasSelected && isAdmin)
                          _buildEmptySelectionPlaceholder()
                        else
                          _buildCalendarView(sessionsByDay),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
},
);
}

  Widget _buildEmptySelectionPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Select an Employee',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use the Viewing Employee dropdown above to select an employee and view their attendance calendar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(Map<int, List<Map<String, dynamic>>> sessionsByDay) {
    final monthTitle = DateFormat('MMMM yyyy').format(_displayedMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar Controls Row: < Prev, Month Year, Next >, Today
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                    });
                    _loadCalendarData();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 2),
                        Text('Prev', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                    });
                    _loadCalendarData();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _displayedMonth = DateTime(now.year, now.month, 1);
                    });
                    _loadCalendarData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Weekdays Header (SUN to SAT)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Dynamic Calendar Matrix
          _buildDynamicCalendarGrid(sessionsByDay),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Bottom Legend matching Web
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Worked', const Color(0xFF10B981)),
                _buildLegendItem('Work From Home', const Color(0xFF0284C7)),
                _buildLegendItem('Leave', const Color(0xFFEF4444)),
                _buildLegendItem('Currently Active', const Color(0xFF8B5CF6)),
                _buildLegendItem('Overtime', const Color(0xFFF97316)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicCalendarGrid(Map<int, List<Map<String, dynamic>>> sessionsByDay) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1 ...

    final prevMonthLastDay = DateTime(year, month, 0).day;

    final List<List<Map<String, dynamic>>> weeks = [];
    List<Map<String, dynamic>> currentWeek = [];

    // Faded days from previous month
    for (int i = startingWeekday - 1; i >= 0; i--) {
      currentWeek.add({
        'day': prevMonthLastDay - i,
        'isFaded': true,
      });
    }

    final now = DateTime.now();

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final dayAtt = _attendanceByDay[day];
      final daySessions = (dayAtt != null && dayAtt['sessions'] is List)
          ? List<Map<String, dynamic>>.from(dayAtt['sessions'])
          : (sessionsByDay[day] ?? []);

      final isToday = now.year == year && now.month == month && now.day == day;

      bool worked = false;
      bool hasOvertime = false;
      bool hasActive = false;
      String? hoursStr;
      String? extraStr;

      if (dayAtt != null) {
        worked = dayAtt['worked'] == true || (dayAtt['totalMs'] as num? ?? 0) > 0;
        hasOvertime = dayAtt['hasOvertime'] == true || (dayAtt['extraMs'] as num? ?? 0) > 0;
        hasActive = dayAtt['isActive'] == true || dayAtt['status'] == 'Active';

        if (worked) {
          final tHours = dayAtt['totalWorkingHours'] as String?;
          if (tHours != null && tHours.isNotEmpty && tHours != '0h 00m') {
            hoursStr = tHours;
          } else {
            final tSec = ((dayAtt['totalMs'] as num? ?? 0) ~/ 1000).toInt();
            if (tSec > 0) hoursStr = _formatDuration(tSec);
          }
        }

        if (hasOvertime) {
          final eHours = dayAtt['extraWorkingHours'] as String?;
          if (eHours != null && eHours.isNotEmpty && eHours != '0h 00m') {
            extraStr = '+$eHours';
          } else {
            final eSec = ((dayAtt['extraMs'] as num? ?? 0) ~/ 1000).toInt();
            if (eSec > 0) extraStr = '+${_formatDuration(eSec)}';
          }
        }
      } else {
        int dailySeconds = 0;
        for (final s in daySessions) {
          dailySeconds += (s['totalSeconds'] as int? ?? 0);
          final status = (s['status'] as String? ?? '').toUpperCase();
          if (status == 'WORKING' || s['sessionStatus'] == 'active' || s['logoutAt'] == null) {
            hasActive = true;
          }
        }

        worked = dailySeconds > 0;
        hasOvertime = dailySeconds > 8 * 3600;
        final extraSeconds = hasOvertime ? (dailySeconds - 8 * 3600) : 0;
        hoursStr = worked ? _formatDuration(dailySeconds) : null;
        extraStr = hasOvertime ? '+${_formatDuration(extraSeconds)}' : null;
      }

      currentWeek.add({
        'day': day,
        'isToday': isToday,
        'hours': hoursStr,
        'extra': extraStr,
        'hasWorkedDot': worked,
        'hasActiveDot': hasActive,
        'hasOvertimeDot': hasOvertime,
        'sessions': daySessions,
      });

      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Faded days for next month to complete the row
    if (currentWeek.isNotEmpty) {
      int nextDay = 1;
      while (currentWeek.length < 7) {
        currentWeek.add({
          'day': nextDay++,
          'isFaded': true,
        });
      }
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) {
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: week.map((dayData) {
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      final day = dayData['day'] as int;
                      final isFaded = dayData['isFaded'] == true;
                      if (!isFaded) {
                        final sessions = (dayData['sessions'] as List<Map<String, dynamic>>?) ?? [];
                        _showDaySessionsSheet(day, sessions);
                      }
                    },
                    child: _buildDayCell(dayData),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(Map<String, dynamic> data) {
    final int day = data['day'] as int;
    final bool isFaded = data['isFaded'] == true;
    final bool isToday = data['isToday'] == true;
    final String? hours = data['hours'] as String?;
    final String? extra = data['extra'] as String?;
    final bool hasWorkedDot = data['hasWorkedDot'] == true;
    final bool hasOvertimeDot = data['hasOvertimeDot'] == true;
    final bool hasActiveDot = data['hasActiveDot'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Day number
          if (isToday)
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isFaded ? FontWeight.w400 : FontWeight.w600,
                color: isFaded ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
              ),
            ),

          // Working hours badge if present
          if (hours != null) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hours,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),
            if (extra != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  extra,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ),
          ],

          // Indicator dots row
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasWorkedDot)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
              if (hasOvertimeDot)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF97316),
                  ),
                ),
              if (hasActiveDot)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
