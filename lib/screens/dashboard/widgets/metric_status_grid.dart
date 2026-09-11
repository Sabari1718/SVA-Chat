import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/tracker/shift_tracker_bloc.dart';
import '../../../bloc/tracker/shift_tracker_state.dart';
import '../../../bloc/attendance/attendance_bloc.dart';
import '../../../bloc/attendance/attendance_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_formatter.dart';

class MetricStatusGrid extends StatelessWidget {
  const MetricStatusGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftTrackerBloc, ShiftTrackerState>(
      builder: (context, trackerState) {
        return BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, attendanceState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.35 : 1.18,
                  children: [
                    // Card 1: Working Hours
                    _buildBentoMetricCard(
                      icon: Icons.access_time_filled_rounded,
                      iconGradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      tagText: 'Target: 8h',
                      tagBg: const Color(0xFFEFF6FF),
                      tagTextColor: const Color(0xFF2563EB),
                      value: TimeFormatter.formatHoursMinutes(trackerState.totalWorkingSeconds),
                      label: 'WORKING HOURS',
                      subtitle: "Today's shift duration",
                    ),

                    // Card 2: Login Sessions
                    _buildBentoMetricCard(
                      icon: Icons.stacked_line_chart_rounded,
                      iconGradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      ),
                      tagText: '${trackerState.loginSessionsCount} Active',
                      tagBg: const Color(0xFFEEF2FF),
                      tagTextColor: const Color(0xFF4F46E5),
                      value: '${trackerState.loginSessionsCount}',
                      label: 'LOGIN SESSIONS',
                      subtitle: "Total sessions logged",
                    ),

                    // Card 3: Current Session
                    _buildBentoMetricCard(
                      icon: Icons.timer_outlined,
                      iconGradient: LinearGradient(
                        colors: trackerState.isWorking
                            ? [const Color(0xFF10B981), const Color(0xFF047857)]
                            : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                      ),
                      tagText: trackerState.isWorking ? 'Live Clock' : 'Stopped',
                      tagBg: trackerState.isWorking ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      tagTextColor: trackerState.isWorking ? const Color(0xFF059669) : const Color(0xFF64748B),
                      value: TimeFormatter.formatFullText(trackerState.currentSessionSeconds),
                      label: 'CURRENT SESSION',
                      subtitle: trackerState.isWorking ? 'Active session ticking' : 'No active session',
                    ),

                    // Card 4: Shift Status
                    _buildBentoMetricCard(
                      icon: trackerState.isWorking
                          ? Icons.check_circle_rounded
                          : (trackerState.isPaused ? Icons.pause_circle_filled_rounded : Icons.offline_bolt_rounded),
                      iconGradient: LinearGradient(
                        colors: trackerState.isWorking
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : (trackerState.isPaused
                                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                : [const Color(0xFFEF4444), const Color(0xFFDC2626)]),
                      ),
                      tagText: trackerState.status.name.toUpperCase(),
                      tagBg: trackerState.isWorking
                          ? const Color(0xFFECFDF5)
                          : (trackerState.isPaused ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2)),
                      tagTextColor: trackerState.isWorking
                          ? const Color(0xFF059669)
                          : (trackerState.isPaused ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                      value: trackerState.isWorking
                          ? 'Working'
                          : (trackerState.isPaused ? 'Paused' : 'Offline'),
                      label: "TODAY'S STATUS",
                      subtitle: trackerState.isWorking ? 'Attendance logged' : 'Shift not active',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBentoMetricCard({
    required IconData icon,
    required LinearGradient iconGradient,
    required String tagText,
    required Color tagBg,
    required Color tagTextColor,
    required String value,
    required String label,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Gradient Icon + Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: iconGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tagText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tagTextColor,
                  ),
                ),
              ),
            ],
          ),

          // Bottom Content: Label, Value, Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

