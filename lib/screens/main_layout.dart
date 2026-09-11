import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/tracker/shift_tracker_bloc.dart';
import '../bloc/tracker/shift_tracker_event.dart';
import '../bloc/tracker/shift_tracker_state.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/time_formatter.dart';
import 'dashboard/dashboard_screen.dart';
import 'modules/task_screen.dart';
import 'modules/project_screen.dart';
import 'modules/chat_screen.dart';
import 'modules/calendar_screen.dart';
import 'modules/leave_screen.dart';
import 'modules/payslip_screen.dart';
import 'widgets/session_logout_dialog.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TaskScreen(),
    ChatScreen(),
    CalendarScreen(),
  ];

  void _onSelectDrawerItem(int index) {
    Navigator.of(context).pop(); // Close drawer
    if (index < 4) {
      setState(() => _currentIndex = index);
    } else if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProjectScreen()),
      );
    } else if (index == 5) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LeaveScreen()),
      );
    } else if (index == 6) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PayslipScreen()),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const SessionLogoutDialog(),
    );
  }

  void _showMoreHubModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
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
                      'Executive Hub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(ctx).pop(),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2x2 Bento Quick Links
                Row(
                  children: [
                    Expanded(
                      child: _buildHubCard(
                        title: 'Projects',
                        subtitle: '6 Active projects',
                        icon: Icons.folder_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHubCard(
                        title: 'Leave & WFH',
                        subtitle: 'Requests & balance',
                        icon: Icons.beach_access_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaveScreen()));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildHubCard(
                        title: 'Payslips',
                        subtitle: 'A4 & monthly breakdown',
                        icon: Icons.receipt_long_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PayslipScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHubCard(
                        title: 'Session Logout',
                        subtitle: 'Manual or QR terminate',
                        icon: Icons.logout_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showLogoutDialog();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftTrackerBloc, ShiftTrackerState>(
      builder: (context, trackerState) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: _currentIndex == 0
                ? Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 22),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
                    tooltip: 'Back to Dashboard',
                    onPressed: () => setState(() => _currentIndex = 0),
                  ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    _currentIndex == 3
                        ? Icons.calendar_month_rounded
                        : (_currentIndex == 1
                            ? Icons.task_alt_rounded
                            : (_currentIndex == 2 ? Icons.forum_rounded : Icons.domain_rounded)),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentIndex == 3
                            ? 'Shift Calendar'
                            : (_currentIndex == 1
                                ? 'Task Management'
                                : (_currentIndex == 2 ? 'Team Chat' : 'Employee Portal')),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SRIVA Enterprise',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Live Pulse Shift Pill
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trackerState.isWorking ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: trackerState.isWorking ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trackerState.isWorking ? const Color(0xFF10B981) : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      TimeFormatter.formatHms(trackerState.normalWorkingSeconds),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trackerState.isWorking ? const Color(0xFF047857) : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // One-Tap Play/Pause Quick Shift Button
              if (trackerState.isWorking)
                IconButton(
                  tooltip: 'Pause Shift',
                  icon: const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFF59E0B), size: 24),
                  onPressed: () => context.read<ShiftTrackerBloc>().add(PauseShiftEvent()),
                )
              else
                IconButton(
                  tooltip: 'Start / Resume Shift',
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 24),
                  onPressed: () {
                    if (trackerState.isPaused) {
                      context.read<ShiftTrackerBloc>().add(ResumeShiftEvent());
                    } else {
                      context.read<ShiftTrackerBloc>().add(StartShiftEvent());
                    }
                  },
                ),

              const SizedBox(width: 8),
            ],
          ),
          drawer: _buildDrawer(context),
          body: PopScope(
            canPop: _currentIndex == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (_currentIndex != 0) {
                setState(() => _currentIndex = 0);
              }
            },
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
                    _buildNavItem(1, Icons.task_alt_rounded, 'Tasks'),
                    _buildNavItem(2, Icons.forum_rounded, 'Chat', badge: '3'),
                    _buildNavItem(3, Icons.calendar_today_rounded, 'Calendar'),
                    _buildMoreNavItem(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {String? badge}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreNavItem() {
    return InkWell(
      onTap: _showMoreHubModal,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: const Icon(
                Icons.apps_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'More',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.domain_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Portal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'SRIVA Enterprise Groups',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _buildDrawerTile(0, 'Dashboard', Icons.grid_view_rounded),
                  _buildDrawerTile(1, 'Task Management', Icons.task_alt_rounded),
                  _buildDrawerTile(2, 'Chat & Team', Icons.forum_rounded, badge: '3'),
                  _buildDrawerTile(3, 'Shift Calendar', Icons.calendar_today_rounded),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildDrawerTile(4, 'Projects', Icons.folder_rounded),
                  _buildDrawerTile(5, 'Leave & Permission', Icons.beach_access_rounded),
                  _buildDrawerTile(6, 'Payslip Management', Icons.receipt_long_rounded),
                ],
              ),
            ),

            // Profile footer
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthenticatedState ? state.user : null;
                final name = user?.name ?? 'Sabarishwaran';
                final role = user?.role ?? 'Employee';
                final initials = user?.avatarInitials ?? 'S';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF0F172A),
                            child: Text(
                              initials,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  role,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
                          label: Text(
                            'Log Out Session',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, String title, IconData icon, {String? badge}) {
    final isSelected = _currentIndex == index && index < 4;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _onSelectDrawerItem(index),
          dense: true,
          leading: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 20),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          trailing: badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white24 : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
