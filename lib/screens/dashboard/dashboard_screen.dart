import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/header_profile_card.dart';
import 'widgets/working_time_tracker_card.dart';
import 'widgets/metric_status_grid.dart';
import 'widgets/attendance_history_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
