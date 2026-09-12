import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/admin/admin_dashboard_bloc.dart';
import '../../bloc/admin/admin_dashboard_state.dart';
import '../../bloc/admin/admin_dashboard_event.dart';
import '../../models/admin_dashboard_model.dart';
import 'activity_report_detail_screen.dart';

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

  List<Map<String, dynamic>> _employeeReports = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthenticatedState) {
        context.read<AdminDashboardBloc>().add(FetchAdminDashboardData(token: auth.user.token ?? ''));
      }
      _updateEmployeesFromBloc();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetailModal(Map<String, dynamic> emp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityReportDetailScreen(employee: emp),
      ),
    );
  }

  void _updateEmployeesFromBloc() {
    final state = context.read<AdminDashboardBloc>().state;
    AdminDashboardModel? data;
    if (state is AdminDashboardLoaded) {
      data = state.data;
    } else if (state is AdminDashboardLoading && state.previousData != null) {
      data = state.previousData;
    } else if (state is AdminDashboardError && state.fallbackData != null) {
      data = state.fallbackData;
    }

    if (data != null) {
      final dashboardData = data;
      final rawEmps = dashboardData.rawEmployees;
      final onlineUserIds = <String>{};
      
      for (final s in dashboardData.rawSessions) {
        final status = (s['status'] as String? ?? '').toUpperCase();
        final sessionStatus = (s['sessionStatus'] as String? ?? '').toLowerCase();
        final logoutAt = s['logoutAt'];
        final isWorking = status == 'WORKING' || sessionStatus == 'active' || (logoutAt == null && status != 'LOGGED_OUT' && status != 'COMPLETED');
        if (isWorking) {
          final empId = (s['employeeId'] as String? ?? '').trim();
          final empName = (s['employeeName'] ?? s['userName'] ?? s['name'] ?? '').toString().toLowerCase().trim();
          if (empId.isNotEmpty) onlineUserIds.add(empId);
          if (empName.isNotEmpty) onlineUserIds.add(empName);
        }
      }

      final mapped = rawEmps.map((emp) {
        final id = (emp['id'] as String? ?? '').trim();
        final name = (emp['name'] as String? ?? 'Unknown').trim();
        final email = (emp['email'] as String? ?? 'N/A').trim();
        final idLower = id.toLowerCase();
        final nameLower = name.toLowerCase();
        final emailLower = email.toLowerCase();

        bool matchEntity(dynamic val) {
          if (val == null) return false;
          final str = val.toString().toLowerCase().trim();
          if (str.isEmpty) return false;
          return str == idLower ||
              str == nameLower ||
              (emailLower.isNotEmpty && str == emailLower) ||
              (nameLower.isNotEmpty && (str.contains(nameLower) || nameLower.contains(str))) ||
              (idLower.isNotEmpty && str.contains(idLower));
        }

        // 1. Online status
        bool isOnline = onlineUserIds.contains(id) || onlineUserIds.contains(nameLower);
        if (!isOnline) {
          for (final s in dashboardData.rawSessions) {
            if (matchEntity(s['employeeId']) || matchEntity(s['employeeName']) || matchEntity(s['userName']) || matchEntity(s['name']) || matchEntity(s['email'])) {
              final status = (s['status'] as String? ?? '').toUpperCase();
              final sessionStatus = (s['sessionStatus'] as String? ?? '').toLowerCase();
              final logoutAt = s['logoutAt'];
              if (status == 'WORKING' || sessionStatus == 'active' || (logoutAt == null && status != 'LOGGED_OUT' && status != 'COMPLETED')) {
                isOnline = true;
                break;
              }
            }
          }
        }
        if (!isOnline && (emp['online'] == true || emp['isOnline'] == true)) {
          isOnline = true;
        }

        // 2. Count tasks
        final empTasks = dashboardData.rawTasks.where((t) {
          final assigned = t['assignedTo'] ?? t['assignee'] ?? t['assignedEmployee'];
          if (assigned is List) {
            for (final a in assigned) {
              if (matchEntity(a)) return true;
            }
          } else if (assigned != null) {
            if (matchEntity(assigned)) return true;
          }
          if (matchEntity(t['employeeId']) || matchEntity(t['employeeName']) || matchEntity(t['userId']) || matchEntity(t['userName'])) {
            return true;
          }
          return false;
        }).toList();
        final completedTasks = empTasks.where((t) => (t['status'] ?? '').toString().toLowerCase() == 'completed').length;
        
        // 3. Count projects
        final empProjects = dashboardData.rawProjects.where((p) {
          final members = p['teamMembers'] ?? p['members'];
          if (members is List) {
            for (final m in members) {
              if (matchEntity(m)) return true;
            }
          } else if (members != null) {
            if (matchEntity(members)) return true;
          }
          if (matchEntity(p['projectLeader']) || matchEntity(p['leader']) || matchEntity(p['createdBy'])) {
            return true;
          }
          return false;
        }).toList();

        // 4. Count leaves (from adminPendingLeaves)
        final empLeaves = dashboardData.rawPendingLeaves.where((l) {
          return matchEntity(l['employeeId']) || matchEntity(l['employeeName']) || matchEntity(l['employeeEmail']) || matchEntity(l['userId']);
        }).length;

        // 5. Calculate login hours
        int totalMinutes = 0;
        for (final s in dashboardData.rawSessions) {
          if (matchEntity(s['employeeId']) || matchEntity(s['employeeName']) || matchEntity(s['userName']) || matchEntity(s['name']) || matchEntity(s['email'])) {
            final dur = s['durationMinutes'] ?? s['totalMinutes'];
            if (dur is num && dur > 0) {
              totalMinutes += dur.toInt();
            } else {
              final loginAtStr = s['loginAt'] ?? s['loginTime'] ?? s['createdAt'];
              final logoutAtStr = s['logoutAt'] ?? s['logoutTime'];
              if (loginAtStr != null) {
                final start = DateTime.tryParse(loginAtStr.toString());
                if (start != null) {
                  final end = logoutAtStr != null ? DateTime.tryParse(logoutAtStr.toString()) : DateTime.now();
                  if (end != null && end.isAfter(start)) {
                    totalMinutes += end.difference(start).inMinutes;
                  }
                }
              }
            }
          }
        }
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;

        final avatar = emp['avatar'] as String?;

        return {
          'id': id,
          'name': name,
          'role': emp['role'] ?? 'employee',
          'department': emp['department'] ?? emp['role'] ?? 'Employee',
          'email': email,
          'isOnline': isOnline,
          'status': isOnline ? 'Online' : 'Logged Out',
          'loginHrs': '${hours}h ${mins}m',
          'tasks': '$completedTasks/${empTasks.length}',
          'projects': '${empProjects.length}',
          'leaves': '${empLeaves}d',
          'avatar': avatar,
          ...emp,
        };
      }).toList();

      setState(() {
        _employeeReports = mapped;
      });
    }
  }

  String? _getAvatarUrl(dynamic avatar) {
    if (avatar == null) return null;
    final str = avatar.toString().trim();
    if (str.isEmpty || str == 'null' || str.length <= 2) return null;
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    const base = 'https://employee-management.srivagroups.in';
    if (str.startsWith('/api/v1')) return '$base$str';
    if (str.startsWith('/')) return '$base/api/v1$str';
    return '$base/api/v1/$str';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoaded || state is AdminDashboardLoading || state is AdminDashboardError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateEmployeesFromBloc();
          });
        }

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
                      // 1. Page Header matching Screenshot 1
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
                                  'Employee Activity & Attendance Reports',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select any employee card to view their complete executive activity, attendance, task, project, chat, and timeline report.',
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

                      // 4. Status Filter Chips
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

                      // Date Navigation & Refresh Cards Row
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
                                  'Sep 12, 2026',
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
                              final auth = context.read<AuthBloc>().state;
                              if (auth is AuthenticatedState) {
                                context.read<AdminDashboardBloc>().add(
                                  FetchAdminDashboardData(token: auth.user.token ?? '', isRefresh: true),
                                );
                              }
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

                      // 5. Responsive Activity Cards Grid/Feed
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          int crossAxisCount = 1;
                          double aspectRatio = 0.95;
                          if (width > 850) {
                            crossAxisCount = 3;
                            aspectRatio = 0.85;
                          } else if (width > 550) {
                            crossAxisCount = 2;
                            aspectRatio = 0.88;
                          }

                          if (crossAxisCount > 1) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredReports.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: aspectRatio,
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
      },
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
    final name = (emp['name'] as String? ?? 'Unknown').trim();
    final avatar = emp['avatar'];
    final avatarUrl = _getAvatarUrl(avatar);
    final avatarLetter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    final dept = emp['department'] ?? emp['role'] ?? 'Employee';
    final email = emp['email'] ?? 'N/A';
    final empId = emp['id'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Banner area (Photo or Letter Circle) + Status Pill on Top Right
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                if (avatarUrl != null)
                  Image.network(
                    avatarUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(avatarLetter),
                  )
                else
                  _buildFallbackBanner(avatarLetter),

                // Status Pill on top right
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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
                          isOnline ? 'Online' : 'Logged Out',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isOnline ? const Color(0xFF059669) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Info area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Blue Dot + Employee ID
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        empId,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$dept • $email',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // 4 Metric Pods: Login Hrs | Tasks | Projects | Leaves
                Row(
                  children: [
                    Expanded(child: _buildMiniStat(emp['loginHrs'] as String? ?? '0h 0m', 'Login Hrs')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildMiniStat(emp['tasks'] as String? ?? '0/0', 'Tasks')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildMiniStat(emp['projects'] as String? ?? '0', 'Projects')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildMiniStat(emp['leaves'] as String? ?? '0d', 'Leaves')),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Button: View Activity Report
                InkWell(
                  onTap: () => _showDetailModal(emp),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'View Activity Report',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(String letter) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
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
