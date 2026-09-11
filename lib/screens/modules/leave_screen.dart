import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  // Top Level Mode: 0 = Admin Approval Portal, 1 = My Applications
  int _topTab = 0;

  // Admin Portal Filters
  String _selectedEmpFilter = 'All Employees';
  String _selectedTypeFilter = 'All Types';
  String _selectedStatusFilter = 'All Statuses';

  // Sample Admin Requests matching Screenshot 5
  final List<Map<String, dynamic>> _adminRequests = [
    {
      'id': 'LV-00001',
      'employeeName': 'Sri Hari',
      'employeeRole': 'Full Stack Developer',
      'employeeAvatar': 'S',
      'avatarColor': const Color(0xFF06B6D4),
      'requestType': 'CASUAL LEAVE',
      'dates': '14/08/2026 → 15/08/2026',
      'duration': '2 Day(s)',
      'reason': 'independence Day and Sunday',
      'status': 'APPROVED',
      'adminRemarks': 'Approved by Owner',
    },
    {
      'id': 'LV-00002',
      'employeeName': 'Sabarishwaran',
      'employeeRole': 'App Developer',
      'employeeAvatar': 'S',
      'avatarColor': const Color(0xFF3B82F6),
      'requestType': 'WORK FROM HOME',
      'dates': '18/09/2026 → 19/09/2026',
      'duration': '2 Day(s)',
      'reason': 'Project sprint deployment',
      'status': 'PENDING',
      'adminRemarks': '',
    },
    {
      'id': 'LV-00003',
      'employeeName': 'Kannan',
      'employeeRole': 'App web developer',
      'employeeAvatar': 'K',
      'avatarColor': const Color(0xFFEF4444),
      'requestType': 'PERMISSION',
      'dates': '12/09/2026 (03:00 PM - 05:00 PM)',
      'duration': '2 Hours',
      'reason': 'Medical consultation',
      'status': 'PENDING',
      'adminRemarks': '',
    },
  ];

  // Employee Forms & State
  int _requestTab = 0; // 0: Leave, 1: Permission, 2: Work From Home
  String _leaveType = 'Casual Leave';
  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Privilege Leave', 'Compensatory Off'];
  final _leaveReasonController = TextEditingController();
  final _permissionReasonController = TextEditingController();
  final _wfhLocationController = TextEditingController();
  final _wfhReasonController = TextEditingController();

  // Employee Submitted Requests
  final List<Map<String, dynamic>> _myRequests = [
    {
      'id': 'LV-00002',
      'type': 'Work From Home',
      'dateTime': '18/09/2026 → 19/09/2026',
      'duration': '2 Day(s)',
      'detail': 'Project sprint deployment',
      'status': 'Pending',
    },
  ];

  @override
  void dispose() {
    _leaveReasonController.dispose();
    _permissionReasonController.dispose();
    _wfhLocationController.dispose();
    _wfhReasonController.dispose();
    super.dispose();
  }

  void _showEditStatusModal(Map<String, dynamic> req, int index) {
    String currentStatus = req['status'] as String;
    final remarksController = TextEditingController(text: req['adminRemarks'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Action: Review Request',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${req['id']} • ${req['employeeName']}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status Radio Pills: APPROVED, PENDING, REJECTED, CANCELLED
                    Text(
                      'Select Status *',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChoiceChip('APPROVED', const Color(0xFF10B981), const Color(0xFFECFDF5), currentStatus, (val) {
                          setModalState(() => currentStatus = val);
                        }),
                        _buildStatusChoiceChip('PENDING', const Color(0xFFF59E0B), const Color(0xFFFFFBEB), currentStatus, (val) {
                          setModalState(() => currentStatus = val);
                        }),
                        _buildStatusChoiceChip('REJECTED', const Color(0xFFEF4444), const Color(0xFFFEF2F2), currentStatus, (val) {
                          setModalState(() => currentStatus = val);
                        }),
                        _buildStatusChoiceChip('CANCELLED', const Color(0xFF64748B), const Color(0xFFF1F5F9), currentStatus, (val) {
                          setModalState(() => currentStatus = val);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Optional Remarks
                    Text(
                      'Admin Remarks (Optional)',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Approved for weekend duty, or specify reason...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _adminRequests[index]['status'] = currentStatus;
                            _adminRequests[index]['adminRemarks'] = remarksController.text.trim();
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Request ${req['id']} updated to $currentStatus'),
                              backgroundColor: const Color(0xFF0F172A),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Update & Save Decision',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChoiceChip(
    String status,
    Color color,
    Color bg,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = current == status;
    return InkWell(
      onTap: () => onSelected(status),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelRequest(int index) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Cancel Request?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Text(
            'Are you sure you want to cancel request ${_adminRequests[index]['id']}?',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('No, Keep'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _adminRequests[index]['status'] = 'CANCELLED';
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request cancelled successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('Yes, Cancel Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthenticatedState ? authState.user : null;
        final isAdmin = user?.isAdmin ?? false;

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
                    'Leave & Permission Management',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Section matching Screenshot 5
                      _buildPageHeader(),
                      const SizedBox(height: 16),

                      // 2. Tab Navigation Pills: [Admin Approval Portal] [My Applications]
                      _buildTopNavigationTabs(isAdmin),
                      const SizedBox(height: 18),

                      // 3. View content based on selected tab
                      if (_topTab == 0 && isAdmin)
                        _buildAdminApprovalPortal()
                      else
                        _buildMyApplicationsPortal(),

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

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF4F46E5), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave & Permission Management',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Apply for casual leave, sick leave, permissions, or Work From Home and track real-time approval status.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopNavigationTabs(bool isAdmin) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (isAdmin) ...[
            _buildTopTabItem(
              index: 0,
              icon: Icons.shield_outlined,
              label: 'Admin Approval Portal',
            ),
            const SizedBox(width: 10),
          ],
          _buildTopTabItem(
            index: 1,
            icon: Icons.person_outline_rounded,
            label: 'My Applications',
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabItem({required int index, required IconData icon, required String label}) {
    final isSelected = _topTab == index;
    return InkWell(
      onTap: () => setState(() => _topTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ADMIN APPROVAL PORTAL =================
  Widget _buildAdminApprovalPortal() {
    final filtered = _adminRequests.where((req) {
      if (_selectedEmpFilter != 'All Employees' && req['employeeName'] != _selectedEmpFilter) {
        return false;
      }
      if (_selectedTypeFilter != 'All Types' && req['requestType'] != _selectedTypeFilter.toUpperCase()) {
        return false;
      }
      if (_selectedStatusFilter != 'All Statuses' && req['status'] != _selectedStatusFilter.toUpperCase()) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Count Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Admin Approval Portal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Total Requests: ${filtered.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter Pods Card (Screenshot 5)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Filter Dropdown
              _buildFilterLabel('EMPLOYEE'),
              const SizedBox(height: 4),
              _buildDropdown(
                value: _selectedEmpFilter,
                items: ['All Employees', 'Sri Hari', 'Sabarishwaran', 'Kannan', 'Kavin Kumar'],
                onChanged: (val) => setState(() => _selectedEmpFilter = val!),
              ),
              const SizedBox(height: 10),

              // Request Type & Status Dropdowns in Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterLabel('REQUEST TYPE'),
                        const SizedBox(height: 4),
                        _buildDropdown(
                          value: _selectedTypeFilter,
                          items: ['All Types', 'Casual Leave', 'Work From Home', 'Permission'],
                          onChanged: (val) => setState(() => _selectedTypeFilter = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterLabel('STATUS'),
                        const SizedBox(height: 4),
                        _buildDropdown(
                          value: _selectedStatusFilter,
                          items: ['All Statuses', 'Approved', 'Pending', 'Rejected', 'Cancelled'],
                          onChanged: (val) => setState(() => _selectedStatusFilter = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Requests Feed (Screenshot 5)
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Text(
              'No requests match the selected filters',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = filtered[index];
              return _buildAdminRequestCard(req, index);
            },
          ),
      ],
    );
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: items.map((it) {
            return DropdownMenuItem<String>(
              value: it,
              child: Text(it, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAdminRequestCard(Map<String, dynamic> req, int index) {
    final status = (req['status'] as String).toUpperCase();
    Color statusColor;
    Color statusBg;

    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        break;
      case 'PENDING':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        break;
      default:
        statusColor = const Color(0xFF475569);
        statusBg = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          // Row 1: Request ID + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req['id'] as String,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Employee Profile Info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: req['avatarColor'] as Color,
                child: Text(
                  req['employeeAvatar'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['employeeName'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      req['employeeRole'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  req['requestType'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Row 3: Dates & Duration + Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req['dates']} • ${req['duration']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reason: ${req['reason']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 4: Action Buttons (Edit & Cancel)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditStatusModal(req, index),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(
                    'Edit Status',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelRequest(index),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= MY APPLICATIONS (EMPLOYEE VIEW) =================
  Widget _buildMyApplicationsPortal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Application Form Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Sub-Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildSubTabItem(0, 'Leave Request'),
                    _buildSubTabItem(1, 'Permission'),
                    _buildSubTabItem(2, 'Work From Home'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Form based on sub-tab
              if (_requestTab == 0) ...[
                _buildFieldLabel('Leave Type *'),
                const SizedBox(height: 6),
                _buildDropdown(
                  value: _leaveType,
                  items: _leaveTypes,
                  onChanged: (val) => setState(() => _leaveType = val!),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Reason *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _leaveReasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Enter reason for leave...'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitMyLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit Leave Request'),
                ),
              ] else if (_requestTab == 1) ...[
                _buildFieldLabel('Reason *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _permissionReasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Enter reason for permission (e.g. 2 hours)...'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitMyPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit Permission Request'),
                ),
              ] else ...[
                _buildFieldLabel('Location *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _wfhLocationController,
                  decoration: const InputDecoration(hintText: 'e.g. Home, Chennai...'),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Reason *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _wfhReasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Enter reason for WFH...'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitMyWfh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply Work From Home'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // My Submitted Requests Feed
        Text(
          'My Submitted Requests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _myRequests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final req = _myRequests[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${req['type']} • ${req['duration']}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          req['dateTime'] as String,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      req['status'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubTabItem(int index, String label) {
    final isSelected = _requestTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _requestTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  void _submitMyLeave() {
    final reason = _leaveReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter leave reason')));
      return;
    }
    setState(() {
      _myRequests.insert(0, {
        'id': 'LV-0000${_myRequests.length + 5}',
        'type': _leaveType,
        'dateTime': '18/09/2026 → 19/09/2026',
        'duration': '2 Day(s)',
        'detail': reason,
        'status': 'Pending',
      });
      _leaveReasonController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application submitted!')));
  }

  void _submitMyPermission() {
    final reason = _permissionReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter permission reason')));
      return;
    }
    setState(() {
      _myRequests.insert(0, {
        'id': 'LV-0000${_myRequests.length + 5}',
        'type': 'Permission',
        'dateTime': '15/09/2026 (03:00 PM - 05:00 PM)',
        'duration': '2 Hours',
        'detail': reason,
        'status': 'Pending',
      });
      _permissionReasonController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission application submitted!')));
  }

  void _submitMyWfh() {
    final reason = _wfhReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter WFH reason')));
      return;
    }
    setState(() {
      _myRequests.insert(0, {
        'id': 'LV-0000${_myRequests.length + 5}',
        'type': 'Work From Home',
        'dateTime': '21/09/2026 → 22/09/2026',
        'duration': '2 Day(s)',
        'detail': reason,
        'status': 'Pending',
      });
      _wfhReasonController.clear();
      _wfhLocationController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work From Home application submitted!')));
  }
}
