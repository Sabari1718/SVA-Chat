import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../modules/employee_screen.dart';
import '../../modules/report_screen.dart';
import '../../modules/project_screen.dart';
import '../../modules/task_screen.dart';
import '../../modules/leave_screen.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthenticatedState ? authState.user : null;
        final adminName = user?.name ?? 'Kalaivani';
        final adminRole = user?.department ?? user?.role ?? 'Owner';
        final initials = user?.avatarInitials ?? 'K';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Admin Welcome Hero Banner
                      _buildAdminHero(context, adminName, adminRole, initials)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 18),

                      // 2. Dashboard Title Section (Exact match to web portal screenshot)
                      _buildTitleSection()
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 300.ms)
                          .slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 18),

                      // 3. The 6 Administration Bento Metric Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 550;
                          if (isWide) {
                            return GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.35,
                              children: _buildBentoCards(context),
                            );
                          } else {
                            return GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 0.95,
                              children: _buildBentoCards(context),
                            );
                          }
                        },
                      ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                      const SizedBox(height: 20),

                      // 4. Quick Action Shortcuts
                      _buildQuickActions(context)
                          .animate()
                          .fadeIn(delay: 220.ms, duration: 350.ms),
                      const SizedBox(height: 20),

                      // 5. System Operational Status Pod
                      _buildSystemStatusPod()
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 350.ms),
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

  Widget _buildAdminHero(BuildContext context, String name, String role, String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'ADMIN',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDDD6FE),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$role • Master Control Access',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Administration Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time operational monitoring, employee presence, and system activity summary.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBentoCards(BuildContext context) {
    return [
      // 1. Employees Card
      _buildBentoCard(
        pillLabel: 'Employees',
        pillIcon: Icons.people_outline_rounded,
        pillColor: const Color(0xFF3B82F6),
        pillBg: const Color(0xFFEFF6FF),
        statTitle: 'TOTAL EMPLOYEES',
        statValue: '11',
        subtitle: 'Active staff employees',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmployeeScreen()),
          );
        },
      ),

      // 2. Managers Card
      _buildBentoCard(
        pillLabel: 'Managers',
        pillIcon: Icons.badge_outlined,
        pillColor: const Color(0xFF8B5CF6),
        pillBg: const Color(0xFFF5F3FF),
        statTitle: 'TOTAL MANAGERS',
        statValue: '0',
        subtitle: 'Management leads',
        onTap: () {},
      ),

      // 3. Active Sessions Card
      _buildBentoCard(
        pillLabel: 'Active Sessions',
        pillIcon: Icons.wifi_rounded,
        pillColor: const Color(0xFF10B981),
        pillBg: const Color(0xFFECFDF5),
        statTitle: 'ONLINE STAFF',
        statValue: '6',
        subtitle: 'Employees & managers online',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          );
        },
      ),

      // 4. Action Required Card
      _buildBentoCard(
        pillLabel: 'Action Required',
        pillIcon: Icons.calendar_month_outlined,
        pillColor: const Color(0xFFF59E0B),
        pillBg: const Color(0xFFFFFBEB),
        statTitle: 'PENDING LEAVES',
        statValue: '0',
        subtitle: 'Awaiting admin approval',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LeaveScreen()),
          );
        },
      ),

      // 5. Task Queue Card
      _buildBentoCard(
        pillLabel: 'Task Queue',
        pillIcon: Icons.format_list_bulleted_rounded,
        pillColor: const Color(0xFF475569),
        pillBg: const Color(0xFFF1F5F9),
        statTitle: 'PENDING TASKS',
        statValue: '8',
        subtitle: 'Active in-progress tasks',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskScreen()),
          );
        },
      ),

      // 6. Projects Card
      _buildBentoCard(
        pillLabel: 'Projects',
        pillIcon: Icons.folder_outlined,
        pillColor: const Color(0xFF0284C7),
        pillBg: const Color(0xFFF0F9FF),
        statTitle: 'ACTIVE PROJECTS',
        statValue: '9',
        subtitle: 'Ongoing system projects',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProjectScreen()),
          );
        },
      ),
    ];
  }

  Widget _buildBentoCard({
    required String pillLabel,
    required IconData pillIcon,
    required Color pillColor,
    required Color pillBg,
    required String statTitle,
    required String statValue,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Pill Header
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: pillColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pillColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        pillLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pillColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Metric Value & Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statTitle,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      statValue,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Description Subtitle
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                'Quick Administrative Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmployeeScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text(
                    'Add Employee',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    );
                  },
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: Text(
                    'View Reports',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusPod() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Real-Time Sync Active • All microservices operational',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF065F46),
              ),
            ),
          ),
          Text(
            '200 OK',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }
}
