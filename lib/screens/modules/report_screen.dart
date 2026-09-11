import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _searchController = TextEditingController();
  int _timeTab = 0; // 0: Today, 1: This Week, 2: This Month, 3: Custom Date
  int _statusFilter = 0; // 0: All, 1: Online, 2: Logged Out, 3: On Leave, 4: Permission

  final List<String> _timeTabs = ['Today', 'This Week', 'This Month', 'Custom Date'];

  // Sample report dataset matching Screenshot 3 & 4
  final List<Map<String, dynamic>> _employeeReports = [
    {
      'id': 'emp-11',
      'name': 'Sabarishwaran',
      'role': 'App Developer',
      'email': 'sabarishwaran1718@gmail.com',
      'isOnline': true,
      'status': 'Online',
      'loginHrs': '3h 31m',
      'tasks': '0/0',
      'projects': '2',
      'leaves': '0d',
      'avatar': 'S',
      'gradient': const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      ),
    },
    {
      'id': 'emp-10',
      'name': 'Kannan',
      'role': 'App web developer',
      'email': 'kannannsenthil@gmail.com',
      'isOnline': false,
      'status': 'Logged Out',
      'loginHrs': '0h 0m',
      'tasks': '0/1',
      'projects': '1',
      'leaves': '0d',
      'avatar': 'K',
      'gradient': const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ),
    },
    {
      'id': 'emp-09',
      'name': 'Kavin Kumar',
      'role': 'Full Stack Developer',
      'email': 'skavinshanmugavel@gmail.com',
      'isOnline': true,
      'status': 'Online',
      'loginHrs': '0h 0m',
      'tasks': '0/1',
      'projects': '1',
      'leaves': '0d',
      'avatar': 'KK',
      'gradient': const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
      ),
    },
    {
      'id': 'emp-08',
      'name': 'Sachin',
      'role': 'Data entry',
      'email': 'sachinsachin0707s@gmail.com',
      'isOnline': true,
      'status': 'Online',
      'loginHrs': '2h 15m',
      'tasks': '1/2',
      'projects': '1',
      'leaves': '0d',
      'avatar': 'S',
      'gradient': const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
      ),
    },
    {
      'id': 'emp-07',
      'name': 'Dhanush',
      'role': 'Full Stack Developer',
      'email': 'dhanusjd@gmail.com',
      'isOnline': true,
      'status': 'Online',
      'loginHrs': '4h 10m',
      'tasks': '2/3',
      'projects': '3',
      'leaves': '0d',
      'avatar': 'D',
      'gradient': const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      ),
    },
    {
      'id': 'emp-06',
      'name': 'Lohit',
      'role': 'Full Stack Developer',
      'email': 'lovelylohit004@gmail.com',
      'isOnline': false,
      'status': 'Logged Out',
      'loginHrs': '1h 45m',
      'tasks': '1/1',
      'projects': '2',
      'leaves': '0d',
      'avatar': 'L',
      'gradient': const LinearGradient(
        colors: [Color(0xFF334155), Color(0xFF1E293B)],
      ),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetailModal(Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Executive Activity Report',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Employee Quick Profile
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF0F172A),
                        child: Text(
                          emp['avatar'] as String,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp['name'] as String,
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${emp['role']} • ${emp['id']}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: emp['isOnline'] == true ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          emp['status'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: emp['isOnline'] == true ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Metrics Bento Grid
                Row(
                  children: [
                    Expanded(child: _buildModalStatBox('LOGIN HOURS', emp['loginHrs'] as String, const Color(0xFF3B82F6))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildModalStatBox('TASKS', emp['tasks'] as String, const Color(0xFF10B981))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildModalStatBox('PROJECTS', emp['projects'] as String, const Color(0xFF6366F1))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildModalStatBox('LEAVES', emp['leaves'] as String, const Color(0xFFF97316))),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close Report', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredReports = _employeeReports.where((e) {
      final name = (e['name'] as String).toLowerCase();
      final id = (e['id'] as String).toLowerCase();
      final email = (e['email'] as String).toLowerCase();
      final matchesQuery = name.contains(query) || id.contains(query) || email.contains(query);

      if (!matchesQuery) return false;

      if (_statusFilter == 1) return e['isOnline'] == true;
      if (_statusFilter == 2) return e['isOnline'] == false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Reports & Analytics',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Page Header matching Screenshot 3
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employee Activity & Reports',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'View complete executive activity, attendance, task, and project reports.',
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

                  // 2. Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search employee by name, email, ID...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Time Filter Tabs: [Today] [This Week] [This Month] [Custom Date]
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_timeTabs.length, (index) {
                        final isSelected = _timeTab == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _timeTab = index),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                _timeTabs[index],
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Status Filter Chips: [All Employees (11)] [Online] [Logged Out] [On Leave]
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusFilterChip(0, 'All Employees (${_employeeReports.length})', null),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(1, 'Online', const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(2, 'Logged Out', const Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(3, 'On Leave', const Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(4, 'Permission', const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date Navigation & Refresh Cards Row (Matches Screenshot 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              'Sep 11, 2026',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cards refreshed'), duration: Duration(seconds: 1)),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                'Refresh Cards',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Responsive Activity Cards Grid/Feed (Guaranteed No Overflow!)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;

                      if (isWide) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReports.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                          itemBuilder: (context, index) {
                            return _buildActivityCard(filteredReports[index]);
                          },
                        );
                      } else {
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReports.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildActivityCard(filteredReports[index]);
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(int index, String label, Color? dotColor) {
    final isSelected = _statusFilter == index;
    return InkWell(
      onTap: () => setState(() => _statusFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> emp) {
    final isOnline = emp['isOnline'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner area with Avatar & Status Pill
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: emp['gradient'] as LinearGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        emp['status'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOnline ? const Color(0xFF047857) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -24,
                left: 16,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emp['avatar'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Employee Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              emp['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        emp['id'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${emp['role']} • ${emp['email']}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // 4 Metric Pods: Login Hrs | Tasks | Projects | Leaves
                Row(
                  children: [
                    Expanded(child: _buildMiniStat(emp['loginHrs'] as String, 'Login Hrs')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMiniStat(emp['tasks'] as String, 'Tasks')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMiniStat(emp['projects'] as String, 'Projects')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildMiniStat(emp['leaves'] as String, 'Leaves')),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Button: View Activity Report
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDetailModal(emp),
                    icon: const Icon(Icons.description_outlined, size: 15),
                    label: Text(
                      'View Activity Report',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
