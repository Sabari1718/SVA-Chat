import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/tracker/shift_tracker_bloc.dart';
import '../../../bloc/tracker/shift_tracker_event.dart';
import '../../../bloc/tracker/shift_tracker_state.dart';
import '../../../bloc/attendance/attendance_bloc.dart';
import '../../../bloc/attendance/attendance_event.dart';
import '../../../models/session_model.dart';
import '../../../core/theme/app_colors.dart';

class HeaderProfileCard extends StatelessWidget {
  const HeaderProfileCard({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = authState is AuthenticatedState ? authState.user.name : 'Sabarishwaran';
        final initials = authState is AuthenticatedState ? authState.user.avatarInitials : 'S';
        final formattedDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

        return BlocBuilder<ShiftTrackerBloc, ShiftTrackerState>(
          builder: (context, trackerState) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar + Welcome + Status Pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with glowing ring
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.accentGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: trackerState.isWorking
                                    ? const Color(0xFF10B981)
                                    : (trackerState.isPaused ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                border: Border.all(color: const Color(0xFF0F172A), width: 2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // User Greeting & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${_getGreeting()}, $userName 👋',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formattedDate,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Badge
                      _buildStatusBadge(trackerState.status),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Divider with subtle glow
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Bar: Working Shift, Pause Shift, End Shift
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Start/Resume Button
                      InkWell(
                        onTap: trackerState.isWorking
                            ? null
                            : () {
                                if (trackerState.isPaused) {
                                  context.read<ShiftTrackerBloc>().add(ResumeShiftEvent());
                                } else {
                                  context.read<ShiftTrackerBloc>().add(StartShiftEvent());
                                }
                              },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: trackerState.isWorking
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                                  ),
                            color: trackerState.isWorking
                                ? Colors.white.withValues(alpha: 0.08)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: trackerState.isWorking
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                            border: Border.all(
                              color: trackerState.isWorking
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: trackerState.isWorking ? Colors.white38 : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                trackerState.isPaused ? 'Resume Shift' : 'Working Shift',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: trackerState.isWorking ? Colors.white38 : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pause Shift Button
                      InkWell(
                        onTap: trackerState.isWorking
                            ? () => context.read<ShiftTrackerBloc>().add(PauseShiftEvent())
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: trackerState.isWorking
                                ? const LinearGradient(
                                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                  )
                                : null,
                            color: trackerState.isWorking
                                ? null
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: trackerState.isWorking
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                            border: Border.all(
                              color: trackerState.isWorking
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pause_rounded,
                                size: 18,
                                color: trackerState.isWorking ? Colors.white : Colors.white38,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pause Shift',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: trackerState.isWorking ? Colors.white : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // End Shift Button
                      if (!trackerState.isOffline)
                        InkWell(
                          onTap: () {
                            final now = DateTime.now();
                            final timeFormat = DateFormat('hh:mm a');
                            final logoutTime = timeFormat.format(now);

                            context.read<AttendanceBloc>().add(
                                  AddSessionRecord(
                                    SessionModel(
                                      sessionId: 'sess-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}',
                                      loginTime: '11:15 AM',
                                      logoutTime: logoutTime,
                                      durationSeconds: trackerState.currentSessionSeconds,
                                      reasonOrStatus: 'manual',
                                    ),
                                  ),
                                );

                            context.read<ShiftTrackerBloc>().add(StopShiftEvent());
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stop_circle_outlined, size: 18, color: Color(0xFFF87171)),
                                const SizedBox(width: 6),
                                Text(
                                  'End Shift',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFFF87171),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(ShiftStatus status) {
    Color dotColor;
    Color bg;
    Color border;
    String text;

    switch (status) {
      case ShiftStatus.working:
        dotColor = const Color(0xFF10B981);
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        border = const Color(0xFF10B981).withValues(alpha: 0.35);
        text = 'Active';
        break;
      case ShiftStatus.paused:
        dotColor = const Color(0xFFF59E0B);
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        border = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        text = 'Paused';
        break;
      case ShiftStatus.offline:
        dotColor = const Color(0xFFEF4444);
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        border = const Color(0xFFEF4444).withValues(alpha: 0.35);
        text = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

