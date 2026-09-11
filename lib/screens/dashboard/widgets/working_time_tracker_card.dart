import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/tracker/shift_tracker_bloc.dart';
import '../../../bloc/tracker/shift_tracker_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_formatter.dart';

class WorkingTimeTrackerCard extends StatelessWidget {
  const WorkingTimeTrackerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftTrackerBloc, ShiftTrackerState>(
      builder: (context, state) {
        // Normal shift is 8 hours (28800s), Total max shift is 13 hours (46800s)
        final normalProgress = (state.normalWorkingSeconds / 28800).clamp(0.0, 1.0);
        final totalProgress = (state.totalWorkingSeconds / 46800).clamp(0.0, 1.0);
        final extraProgress = (state.extraWorkingSeconds / 18000).clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.timer_rounded,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Daily Working Time Tracker',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '13h Shift Cap',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 2. Hero Shift Live Arc Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular Arc Progress
                      SizedBox(
                        width: 86,
                        height: 86,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 86,
                              height: 86,
                              child: CircularProgressIndicator(
                                value: totalProgress,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  state.extraWorkingSeconds > 0
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF10B981),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(totalProgress * 100).toInt()}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Shift',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Live Digital Clock & Shift Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: state.isWorking
                                        ? const Color(0xFF10B981)
                                        : (state.isPaused ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8)),
                                    boxShadow: state.isWorking
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  state.isWorking
                                      ? 'LIVE SHIFT DURATION'
                                      : (state.isPaused ? 'SHIFT PAUSED' : 'OFFLINE / SHIFT ENDED'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: state.isWorking
                                        ? const Color(0xFF34D399)
                                        : (state.isPaused ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                TimeFormatter.formatHms(state.totalWorkingSeconds),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.extraWorkingSeconds > 0
                                  ? 'Extra hours active (+${TimeFormatter.formatHoursMinutes(state.extraWorkingSeconds)})'
                                  : 'Regular shift in progress (Target: 8h 00m)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 4 Bento Sub-Cards (2x2 Grid)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.4 : 1.22,
                      children: [
                        // Sub-card 1: Normal Working Time
                        _buildSubTimerCard(
                          title: 'Normal Working',
                          time: TimeFormatter.formatHms(state.normalWorkingSeconds),
                          subtitle: 'Max 8h (08:00:00)',
                          progress: normalProgress,
                          icon: Icons.check_circle_rounded,
                          accentColor: const Color(0xFF10B981),
                          bgGradient: const LinearGradient(
                            colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: const Color(0xFFBBF7D0),
                        ),

                        // Sub-card 2: Extra Working Time
                        _buildSubTimerCard(
                          title: 'Extra Working',
                          time: TimeFormatter.formatHms(state.extraWorkingSeconds),
                          subtitle: 'Max 5h (05:00:00)',
                          progress: extraProgress,
                          icon: Icons.local_fire_department_rounded,
                          accentColor: const Color(0xFFF97316),
                          bgGradient: const LinearGradient(
                            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: const Color(0xFFFED7AA),
                        ),

                        // Sub-card 3: Total Working Time
                        _buildSubTimerCard(
                          title: 'Total Working',
                          time: TimeFormatter.formatHms(state.totalWorkingSeconds),
                          subtitle: 'Cumulative Today',
                          progress: totalProgress,
                          icon: Icons.all_inclusive_rounded,
                          accentColor: const Color(0xFF4F46E5),
                          bgGradient: const LinearGradient(
                            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: const Color(0xFFC7D2FE),
                        ),

                        // Sub-card 4: Remaining Time
                        _buildSubTimerCard(
                          title: 'Remaining Time',
                          time: TimeFormatter.formatHms(state.remainingSeconds),
                          subtitle: 'Until Auto-Logout',
                          progress: (1.0 - totalProgress).clamp(0.0, 1.0),
                          icon: Icons.hourglass_top_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                          bgGradient: const LinearGradient(
                            colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: const Color(0xFFDDD6FE),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubTimerCard({
    required String title,
    required String time,
    required String subtitle,
    required double progress,
    required IconData icon,
    required Color accentColor,
    required LinearGradient bgGradient,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  time,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Micro Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
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

