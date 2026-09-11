import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<String> _employeeList = [
    'Sabarishwaran (employee)',
    'Kannan (employee)',
    'Kalaivani (admin)',
    'Kavin Kumar (employee)',
    'Sachin (employee)',
    'Dhanush (employee)',
    'Lohit (employee)',
    'Aruna (employee)',
    'Iniya (employee)',
    'Sri Hari (employee)',
    'Yudesh Prasath (employee)',
    'Krishna (employee)',
    'Kavin (admin)',
  ];

  String? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthenticatedState ? authState.user : null;
        final isAdmin = user?.isAdmin ?? false;

        // If regular employee, automatically view their own calendar
        final effectiveEmployee = isAdmin ? _selectedEmployee : (user?.name ?? 'Sabarishwaran');
        final hasSelected = effectiveEmployee != null;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Page Header matching Screenshots
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Admin Employee Selector Dropdown (Screenshots 2, 3, 4)
                      if (isAdmin) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                        'Showing: ${_cleanName(effectiveEmployee)}',
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
                                  child: DropdownButton<String?>(
                                    value: _selectedEmployee,
                                    isExpanded: true,
                                    hint: Text(
                                      '— Select an Employee —',
                                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          '— Select an Employee —',
                                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                        ),
                                      ),
                                      ..._employeeList.map((emp) {
                                        return DropdownMenuItem<String?>(
                                          value: emp,
                                          child: Text(emp, style: GoogleFonts.inter(fontSize: 13)),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedEmployee = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 3. 5 Metric Summary Pods (Screenshots 2 & 4)
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
                                hasSelected ? '2' : '0',
                                'Working Days',
                                Icons.calendar_today_outlined,
                                const Color(0xFF8B5CF6),
                                const Color(0xFFF5F3FF),
                              ),
                              _buildSummaryCard(
                                hasSelected ? '11h 36m' : '0h 00m',
                                'Normal Hours',
                                Icons.access_time_rounded,
                                const Color(0xFF3B82F6),
                                const Color(0xFFEFF6FF),
                              ),
                              _buildSummaryCard(
                                hasSelected ? '134h 16m' : '0h 00m',
                                'Extra Hours',
                                Icons.timer_outlined,
                                const Color(0xFFF97316),
                                const Color(0xFFFFF7ED),
                              ),
                              _buildSummaryCard(
                                hasSelected ? '72h 56m' : '0h 00m',
                                'Avg / Day',
                                Icons.bar_chart_rounded,
                                const Color(0xFF10B981),
                                const Color(0xFFECFDF5),
                              ),
                              _buildSummaryCard(
                                hasSelected ? '1' : '0',
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

                      // 4. Calendar Container OR Empty State (Screenshots 2 & 4)
                      if (!hasSelected && isAdmin)
                        _buildEmptySelectionPlaceholder()
                      else
                        _buildCalendarView(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _cleanName(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll('(employee)', '').replaceAll('(admin)', '').trim();
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
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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

  Widget _buildCalendarView() {
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
          // Calendar Controls Row: < Prev, September 2026, Next >, Today
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () {},
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
                      'September 2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
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
                  onPressed: () {},
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

          // Calendar Month Matrix matching Screenshot 4
          _buildCalendarGrid(),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Bottom Legend matching Screenshot 4
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

  Widget _buildCalendarGrid() {
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
          'hasWorkedDot': true,
          'hasOvertimeDot': true,
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
          'hours': '3h 36m',
          'isToday': true,
          'hasActiveDot': true,
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
              children: week.map((dayData) => Expanded(child: _buildDayCell(dayData))).toList(),
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
