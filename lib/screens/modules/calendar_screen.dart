import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

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
                'Shift Calendar',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header matching Screenshot 5
                  Row(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work & Attendance Calendar',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'View daily login / logout sessions, working hours, and Work From Home status for each day.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5 Metric Summary Cards in responsive layout
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
                          _buildSummaryCard('2', 'Working Days', Icons.calendar_today_outlined, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
                          _buildSummaryCard('9h 02m', 'Normal Hours', Icons.access_time_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                          _buildSummaryCard('134h 16m', 'Extra Hours', Icons.timer_outlined, const Color(0xFFF97316), const Color(0xFFFFF7ED)),
                          _buildSummaryCard('71h 39m', 'Avg / Day', Icons.bar_chart_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                          _buildSummaryCard('1', 'Overtime Days', Icons.bolt_rounded, const Color(0xFFF43F5E), const Color(0xFFFFF1F2)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Calendar Container
                  Container(
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
                        // Calendar Controls Row: < Prev, September 2026, Next >, Today
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Previous month',
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'September 2026',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Next month',
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Today', style: TextStyle(fontSize: 11, color: Colors.white)),
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

                        // Calendar Month Matrix matching Screenshot 5
                        _buildCalendarGrid(),

                        const Divider(height: 1, color: Color(0xFFE2E8F0)),

                        // Bottom Legend matching Screenshot 5
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 18,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
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

  Widget _buildCalendarGrid() {
    // 5 rows of 7 days
    final List<List<Map<String, dynamic>>> weeks = [
      // Week 1
      [
        {'day': 30, 'isFaded': true},
        {'day': 31, 'isFaded': true},
        {'day': 1},
        {'day': 2},
        {'day': 3},
        {'day': 4},
        {
          'day': 5,
          'hours': '142h 16m',
          'extra': '+134h 16m',
          'dots': [const Color(0xFF10B981), const Color(0xFFF97316)],
        },
      ],
      // Week 2
      [
        {'day': 6},
        {'day': 7},
        {'day': 8},
        {'day': 9},
        {'day': 10},
        {
          'day': 11,
          'isToday': true,
          'hours': '1h 02m',
          'dots': [const Color(0xFF8B5CF6)],
        },
        {'day': 12},
      ],
      // Week 3
      [
        {'day': 13},
        {'day': 14},
        {'day': 15},
        {'day': 16},
        {'day': 17},
        {'day': 18},
        {'day': 19},
      ],
      // Week 4
      [
        {'day': 20},
        {'day': 21},
        {'day': 22},
        {'day': 23},
        {'day': 24},
        {'day': 25},
        {'day': 26},
      ],
      // Week 5
      [
        {'day': 27},
        {'day': 28},
        {'day': 29},
        {'day': 30},
        {'day': 1, 'isFaded': true},
        {'day': 2, 'isFaded': true},
        {'day': 3, 'isFaded': true},
      ],
    ];

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
                final isFaded = dayData['isFaded'] == true;
                final isToday = dayData['isToday'] == true;
                final hours = dayData['hours'] as String?;
                final extra = dayData['extra'] as String?;
                final dots = dayData['dots'] as List<Color>?;

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    constraints: const BoxConstraints(minHeight: 70),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${dayData['day']}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${dayData['day']}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isFaded ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
                            ),
                          ),
                        const Spacer(),
                        if (hours != null)
                          Text(
                            hours,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        if (extra != null)
                          Text(
                            extra,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        if (dots != null && dots.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: dots
                                  .map(
                                    (c) => Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.only(right: 3),
                                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
