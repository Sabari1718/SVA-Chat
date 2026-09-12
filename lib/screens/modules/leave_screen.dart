import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/admin_repository.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  bool _isLoading = false;

  // Top Level Mode: 0 = Admin Approval Portal, 1 = My Applications
  int _topTab = 0;

  // Admin Portal Filters (Screenshots 3 & 4)
  List<String> _employeeNames = ['All Employees'];
  String _selectedEmpFilter = 'All Employees';
  String _selectedTypeFilter = 'All Types';
  String _selectedStatusFilter = 'All Statuses';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Live Admin Requests
  List<Map<String, dynamic>> _adminRequests = [];

  // Employee Apply Form Dates
  DateTime? _applyFromDate;
  DateTime? _applyToDate;
  DateTime? _permissionDate;

  // Employee Forms & State
  int _requestTab = 0; // 0: Leave, 1: Permission, 2: Work From Home
  String _leaveType = 'Casual Leave';
  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Privilege Leave', 'Compensatory Off'];
  final _leaveReasonController = TextEditingController();
  
  final _permissionFromTimeController = TextEditingController();
  final _permissionToTimeController = TextEditingController();
  final _permissionReasonController = TextEditingController();
  
  String _wfhDurationType = 'Full Day';
  final List<String> _wfhDurationTypes = ['Full Day', 'Half Day'];
  String _wfhSession = 'First Half (Morning)';
  final List<String> _wfhSessions = ['First Half (Morning)', 'Second Half (Afternoon)'];
  final _wfhLocationController = TextEditingController();
  final _wfhReasonController = TextEditingController();

  // Employee Submitted Requests
  List<Map<String, dynamic>> _myRequests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _leaveReasonController.dispose();
    _permissionFromTimeController.dispose();
    _permissionToTimeController.dispose();
    _permissionReasonController.dispose();
    _wfhLocationController.dispose();
    _wfhReasonController.dispose();
    super.dispose();
  }

  String _getToken() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.token ?? '';
    }
    return '';
  }

  String _mapRequestTypeToApi(String type) {
    switch (type) {
      case 'Leave Only':
        return 'leave';
      case 'Permission Only':
        return 'permission';
      case 'Work From Home Only':
        return 'work_from_home';
      default:
        return 'all';
    }
  }

  String _mapStatusToApi(String status) {
    switch (status) {
      case 'Pending':
        return 'pending';
      case 'Approved':
        return 'approved';
      case 'Rejected':
        return 'rejected';
      case 'Cancelled':
        return 'cancelled';
      default:
        return 'all';
    }
  }

  Map<String, dynamic> _normalizeRequest(Map<String, dynamic> item, Set<String> empNames) {
    final empName = (item['employeeName'] as String?)?.trim() ?? 'Employee';
    empNames.add(empName);

    final reqType = (item['requestType'] as String? ?? 'leave').toLowerCase();
    final lType = (item['leaveType'] as String? ?? 'Casual Leave').trim();

    String displayType;
    if (reqType == 'permission') {
      displayType = 'PERMISSION';
    } else if (reqType == 'work_from_home') {
      displayType = 'WORK FROM HOME';
    } else {
      displayType = lType.toUpperCase();
    }

    DateTime? startDt;
    DateTime? endDt;
    if (reqType == 'permission') {
      startDt = _parseDate(item['permissionDate'] ?? item['fromDate']);
      endDt = startDt;
    } else {
      startDt = _parseDate(item['fromDate']);
      endDt = _parseDate(item['toDate']) ?? startDt;
    }

    String datesStr;
    if (reqType == 'permission') {
      final pDate = item['permissionDate'] ?? item['fromDate'] ?? '';
      final fTime = item['fromTime'] ?? '';
      final tTime = item['toTime'] ?? '';
      if (fTime.isNotEmpty || tTime.isNotEmpty) {
        datesStr = '$pDate ($fTime - $tTime)';
      } else {
        datesStr = pDate.toString();
      }
    } else {
      final fDate = item['fromDate'] ?? '';
      final tDate = item['toDate'] ?? '';
      datesStr = (tDate.isNotEmpty && tDate != fDate) ? '$fDate → $tDate' : fDate.toString();
    }

    String durationStr;
    if (reqType == 'permission') {
      final mins = item['durationMinutes'];
      if (mins != null && mins is num && mins > 0) {
        final hrs = (mins / 60).toStringAsFixed(mins % 60 == 0 ? 0 : 1);
        durationStr = '$hrs Hour(s)';
      } else {
        durationStr = 'Permission';
      }
    } else {
      final days = item['totalDays'];
      if (days != null && days is num && days > 0) {
        durationStr = '$days Day(s)';
      } else {
        durationStr = '1 Day(s)';
      }
    }

    final reqId = item['requestId'] ?? item['id'] ?? 'LV-00000';
    final statusStr = (item['status'] as String? ?? 'pending').toUpperCase();

    // Map for "My Requests" specific UI keys
    String typeForMyReq;
    if (reqType == 'permission') {
      typeForMyReq = 'Permission';
    } else if (reqType == 'work_from_home') {
      typeForMyReq = 'Work From Home';
    } else {
      typeForMyReq = lType;
    }
    
    // Convert status to Title Case for My Requests UI
    String myReqStatus = statusStr.toLowerCase();
    if (myReqStatus.isNotEmpty) {
      myReqStatus = myReqStatus[0].toUpperCase() + myReqStatus.substring(1);
    }

    return {
      'id': reqId,
      'dbId': item['id'],
      'requestId': reqId,
      'employeeName': empName,
      'employeeRole': item['employeeDepartment'] ?? item['employeeRole'] ?? 'Employee',
      'employeeAvatar': empName.isNotEmpty ? empName[0].toUpperCase() : 'E',
      'avatarColor': _getAvatarColor(empName),
      'requestType': displayType,
      'rawRequestType': reqType,
      'leaveType': lType,
      'fromDate': item['fromDate'] as String?,
      'toDate': item['toDate'] as String?,
      'permissionDate': item['permissionDate'] as String?,
      'fromTime': item['fromTime'] as String?,
      'toTime': item['toTime'] as String?,
      'workLocation': item['workLocation'] as String?,
      'durationMinutes': item['durationMinutes'],
      'totalDays': item['totalDays'],
      'startDate': startDt,
      'endDate': endDt,
      'dates': datesStr,
      'duration': durationStr,
      'reason': item['reason'] as String? ?? '',
      'status': statusStr,
      'adminRemarks': item['rejectionReason'] as String? ?? '',
      'raw': item,
      
      // Keys specifically used by `_myRequests` list view:
      'type': typeForMyReq,
      'dateTime': datesStr,
      'detail': item['reason'] as String? ?? '',
      'myReqStatus': myReqStatus, 
    };
  }

  Future<void> _loadData() async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _adminRepo.getAdminLeaveRequests(
          token: token,
          requestType: _mapRequestTypeToApi(_selectedTypeFilter),
          status: _mapStatusToApi(_selectedStatusFilter),
        ),
        _adminRepo.getEmployees(token),
        _adminRepo.getMyLeaveRequests(token),
      ]);

      final rawRequests = results[0];
      final rawEmployees = results[1];
      final rawMyRequests = results[2];

      // Build employee names list
      final Set<String> empNames = {'All Employees'};
      for (final emp in rawEmployees) {
        final name = emp['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          empNames.add(name.trim());
        }
      }

      final normalizedRequests = <Map<String, dynamic>>[];
      for (final item in rawRequests) {
        normalizedRequests.add(_normalizeRequest(item, empNames));
      }

      final normalizedMyRequests = <Map<String, dynamic>>[];
      for (final item in rawMyRequests) {
        normalizedMyRequests.add(_normalizeRequest(item, empNames));
      }

      setState(() {
        _employeeNames = empNames.toList();
        _adminRequests = normalizedRequests;
        _myRequests = normalizedMyRequests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[LeaveScreen] _loadData error: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _formatDateForApi(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  void _showEditRequestModal(Map<String, dynamic> req) {
    String currentStatus = (req['status'] as String? ?? 'PENDING').toUpperCase();
    final rawType = (req['rawRequestType'] as String? ?? 'leave').toLowerCase();

    final reasonController = TextEditingController(text: req['reason'] as String? ?? '');
    final fromTimeController = TextEditingController(text: req['fromTime'] as String? ?? '02:00 PM');
    final toTimeController = TextEditingController(text: req['toTime'] as String? ?? '04:00 PM');
    final locationController = TextEditingController(text: req['workLocation'] as String? ?? 'Home');

    String leaveTypeVal = req['leaveType'] as String? ?? 'Casual Leave';
    if (!_leaveTypes.contains(leaveTypeVal)) {
      leaveTypeVal = _leaveTypes.first;
    }

    DateTime? editFromDate = req['startDate'] as DateTime? ?? _parseDate(req['fromDate'] ?? req['permissionDate']) ?? DateTime.now();
    DateTime? editToDate = req['endDate'] as DateTime? ?? _parseDate(req['toDate'] ?? req['permissionDate']) ?? editFromDate;
    DateTime? editPermissionDate = _parseDate(req['permissionDate'] ?? req['fromDate']) ?? DateTime.now();

    bool isSaving = false;

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
                child: SingleChildScrollView(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Request: ${req['requestId'] ?? req['id']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${req['employeeName']} • ${req['employeeRole']}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Status Selection Chips
                      Text(
                        'Select Status *',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 14),

                      // 2. Dynamic fields based on rawType
                      if (rawType == 'permission') ...[
                        Text(
                          'Permission Date *',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        _buildDatePickerField(
                          date: editPermissionDate,
                          hint: 'dd-mm-yyyy',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editPermissionDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() => editPermissionDate = picked);
                            }
                          },
                          onClear: () {},
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From Time *',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: fromTimeController,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: '02:00 PM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To Time *',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: toTimeController,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: '04:00 PM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        if (rawType == 'leave') ...[
                          Text(
                            'Leave Type *',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          _buildDropdown(
                            value: leaveTypeVal,
                            items: _leaveTypes,
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => leaveTypeVal = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ] else if (rawType == 'work_from_home') ...[
                          Text(
                            'Work Location *',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: locationController,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'e.g. Home, Chennai',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // From Date & To Date Pickers
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From Date *',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildDatePickerField(
                                    date: editFromDate,
                                    hint: 'dd-mm-yyyy',
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: editFromDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          editFromDate = picked;
                                          if (editToDate != null && editToDate!.isBefore(editFromDate!)) {
                                            editToDate = editFromDate;
                                          }
                                        });
                                      }
                                    },
                                    onClear: () {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To Date *',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildDatePickerField(
                                    date: editToDate,
                                    hint: 'dd-mm-yyyy',
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: editToDate ?? editFromDate ?? DateTime.now(),
                                        firstDate: editFromDate ?? DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => editToDate = picked);
                                      }
                                    },
                                    onClear: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      Text(
                        'Reason *',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter reason...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions: [ Cancel ] [ Save Changes ]
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final token = _getToken();
                                      if (token.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Error: Not authenticated')),
                                        );
                                        return;
                                      }

                                      setModalState(() => isSaving = true);

                                      final reqId = req['requestId'] ?? req['id'];
                                      final fromStr = editFromDate != null ? _formatDateForApi(editFromDate!) : '';
                                      final toStr = editToDate != null ? _formatDateForApi(editToDate!) : fromStr;
                                      final pDateStr = editPermissionDate != null ? _formatDateForApi(editPermissionDate!) : '';

                                      final payload = <String, dynamic>{
                                        "status": currentStatus.toLowerCase(),
                                        "reason": reasonController.text.trim(),
                                        "fromDate": rawType == 'permission' ? pDateStr : fromStr,
                                        "toDate": rawType == 'permission' ? pDateStr : toStr,
                                        "permissionDate": rawType == 'permission' ? pDateStr : '',
                                        "fromTime": fromTimeController.text.trim(),
                                        "toTime": toTimeController.text.trim(),
                                        "leaveType": leaveTypeVal,
                                        if (rawType == 'work_from_home')
                                          "workLocation": locationController.text.trim(),
                                      };

                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await _adminRepo.updateLeaveRequest(
                                          token: token,
                                          requestId: reqId.toString(),
                                          data: payload,
                                        );

                                        if (ctx.mounted) Navigator.of(ctx).pop();
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Request $reqId updated successfully.'),
                                              backgroundColor: const Color(0xFF059669),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          _loadData();
                                        }
                                      } catch (e) {
                                        setModalState(() => isSaving = false);
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to update: $e'),
                                              backgroundColor: const Color(0xFFDC2626),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _quickUpdateStatus(Map<String, dynamic> req, String newStatus) async {
    final token = _getToken();
    if (token.isEmpty) return;

    final reqId = req['requestId'] ?? req['id'];

    if (newStatus == 'cancelled' || newStatus == 'rejected') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            newStatus == 'cancelled' ? 'Cancel Request?' : 'Reject Request?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to mark request $reqId as ${newStatus.toUpperCase()}?',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: Text(
                'Yes, ${newStatus.toUpperCase()}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final payload = <String, dynamic>{
        "status": newStatus.toLowerCase(),
        "reason": req['reason'] ?? '',
        "fromDate": req['fromDate'] ?? '',
        "toDate": req['toDate'] ?? '',
        "permissionDate": req['permissionDate'] ?? '',
        "fromTime": req['fromTime'] ?? '',
        "toTime": req['toTime'] ?? '',
        "leaveType": req['leaveType'] ?? '',
        if (req['workLocation'] != null) "workLocation": req['workLocation'],
      };

      await _adminRepo.updateLeaveRequest(
        token: token,
        requestId: reqId.toString(),
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $reqId marked as ${newStatus.toUpperCase()}.'),
            backgroundColor: newStatus == 'approved' ? const Color(0xFF059669) : const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
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
      final rawType = (req['rawRequestType'] as String? ?? '').toLowerCase();
      if (_selectedTypeFilter == 'Leave Only' && rawType != 'leave') return false;
      if (_selectedTypeFilter == 'Permission Only' && rawType != 'permission') return false;
      if (_selectedTypeFilter == 'Work From Home Only' && rawType != 'work_from_home') return false;

      final reqStatus = (req['status'] as String? ?? '').toUpperCase();
      if (_selectedStatusFilter != 'All Statuses' && reqStatus != _selectedStatusFilter.toUpperCase()) {
        return false;
      }
      if (_fromDate != null || _toDate != null) {
        final reqStart = req['startDate'] as DateTime?;
        final reqEnd = req['endDate'] as DateTime? ?? reqStart;
        if (reqStart != null) {
          if (_fromDate != null && reqEnd != null) {
            final fromBoundary = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
            final endBoundary = DateTime(reqEnd.year, reqEnd.month, reqEnd.day);
            if (endBoundary.isBefore(fromBoundary)) return false;
          }
          if (_toDate != null) {
            final toBoundary = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
            final startBoundary = DateTime(reqStart.year, reqStart.month, reqStart.day);
            if (startBoundary.isAfter(toBoundary)) return false;
          }
        }
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

        // Filter Pods Card (Screenshots 3, 4 & 5)
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
              // Employee Filter Dropdown (All Employees from API)
              _buildFilterLabel('EMPLOYEE'),
              const SizedBox(height: 4),
              _buildDropdown(
                value: _employeeNames.contains(_selectedEmpFilter) ? _selectedEmpFilter : 'All Employees',
                items: _employeeNames,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedEmpFilter = val);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Request Type & Status Dropdowns in Row (Screenshots 3 & 4)
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
                          items: const ['All Types', 'Leave Only', 'Permission Only', 'Work From Home Only'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTypeFilter = val);
                              _loadData();
                            }
                          },
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
                          items: const ['All Statuses', 'Pending', 'Approved', 'Rejected', 'Cancelled'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatusFilter = val);
                              _loadData();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // From Date & To Date Pickers in Row (Screenshot 5)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterLabel('FROM DATE'),
                        const SizedBox(height: 4),
                        _buildDatePickerField(
                          date: _fromDate,
                          hint: 'dd-mm-yyyy',
                          onTap: _pickFromDate,
                          onClear: () => setState(() => _fromDate = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterLabel('TO DATE'),
                        const SizedBox(height: 4),
                        _buildDatePickerField(
                          date: _toDate,
                          hint: 'dd-mm-yyyy',
                          onTap: _pickToDate,
                          onClear: () => setState(() => _toDate = null),
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

        // Requests Feed with Live API Loading State
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          )
        else if (filtered.isEmpty)
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

  Widget _buildDatePickerField({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final formatted = date != null
        ? '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}'
        : hint;
    final isSelected = date != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.textPrimary : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),
            const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = _fromDate;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
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

          // Row 4: Action Buttons (Approve, Reject, Edit, Cancel)
          if ((req['status'] as String? ?? '').toUpperCase() == 'PENDING') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _quickUpdateStatus(req, 'approved'),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _quickUpdateStatus(req, 'rejected'),
                    icon: const Icon(Icons.highlight_off_rounded, size: 15),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditRequestModal(req),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickUpdateStatus(req, 'cancelled'),
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
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditRequestModal(req),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text(
                      'Edit Request',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                if ((req['status'] as String? ?? '').toUpperCase() != 'CANCELLED') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _quickUpdateStatus(req, 'cancelled'),
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
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('From Date *'),
                          const SizedBox(height: 6),
                          _buildDatePickerField(
                            date: _applyFromDate,
                            hint: 'dd-mm-yyyy',
                            onTap: _pickApplyFromDate,
                            onClear: () => setState(() => _applyFromDate = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('To Date *'),
                          const SizedBox(height: 6),
                          _buildDatePickerField(
                            date: _applyToDate,
                            hint: 'dd-mm-yyyy',
                            onTap: _pickApplyToDate,
                            onClear: () => setState(() => _applyToDate = null),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                _buildFieldLabel('Permission Date *'),
                const SizedBox(height: 6),
                _buildDatePickerField(
                  date: _permissionDate,
                  hint: 'dd-mm-yyyy',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _permissionDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _permissionDate = picked);
                    }
                  },
                  onClear: () => setState(() => _permissionDate = null),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('From Time *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _permissionFromTimeController,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: '02:00 PM',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('To Time *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _permissionToTimeController,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: '04:00 PM',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Reason *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _permissionReasonController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter reason for permission (e.g. 2 hours)...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
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
                _buildFieldLabel('WFH Duration *'),
                const SizedBox(height: 6),
                _buildDropdown(
                  value: _wfhDurationType,
                  items: _wfhDurationTypes,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _wfhDurationType = val);
                    }
                  },
                ),
                if (_wfhDurationType == 'Half Day') ...[
                  const SizedBox(height: 12),
                  _buildFieldLabel('Half Day Session *'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _wfhSession,
                    items: _wfhSessions,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _wfhSession = val);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 12),
                _buildFieldLabel('Work Location *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _wfhLocationController,
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'e.g. Home, Chennai...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('From Date *'),
                          const SizedBox(height: 6),
                          _buildDatePickerField(
                            date: _applyFromDate,
                            hint: 'dd-mm-yyyy',
                            onTap: _pickApplyFromDate,
                            onClear: () => setState(() => _applyFromDate = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('To Date *'),
                          const SizedBox(height: 6),
                          _buildDatePickerField(
                            date: _applyToDate,
                            hint: 'dd-mm-yyyy',
                            onTap: _pickApplyToDate,
                            onClear: () => setState(() => _applyToDate = null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Reason *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _wfhReasonController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter reason for WFH...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      if ((req['status'] as String? ?? '').toUpperCase() == 'PENDING') ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _cancelMyRequest(req['id'] as String),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
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

  Future<void> _pickApplyFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _applyFromDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _applyFromDate = picked;
        if (_applyToDate != null && _applyToDate!.isBefore(_applyFromDate!)) {
          _applyToDate = _applyFromDate;
        }
      });
    }
  }

  Future<void> _pickApplyToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _applyToDate ?? _applyFromDate ?? DateTime.now(),
      firstDate: _applyFromDate ?? DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _applyToDate = picked);
    }
  }

  Future<void> _submitMyLeave() async {
    final reason = _leaveReasonController.text.trim();
    if (reason.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter leave reason')));
      return;
    }

    final from = _applyFromDate ?? DateTime.now();
    final to = _applyToDate ?? from;
    final token = _getToken();

    try {
      await _adminRepo.submitLeaveRequest(
        token: token,
        data: {
          'requestType': 'leave',
          'leaveType': _leaveType,
          'fromDate': _formatDateForApi(from),
          'toDate': _formatDateForApi(to),
          'reason': reason,
        },
      );

      if (mounted) {
        setState(() {
          _leaveReasonController.clear();
          _applyFromDate = null;
          _applyToDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application submitted!')));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitMyPermission() async {
    final reason = _permissionReasonController.text.trim();
    final fromTime = _permissionFromTimeController.text.trim();
    final toTime = _permissionToTimeController.text.trim();
    
    if (reason.isEmpty || fromTime.isEmpty || toTime.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final token = _getToken();
    final pDate = _permissionDate ?? DateTime.now();
    
    try {
      await _adminRepo.submitLeaveRequest(
        token: token,
        data: {
          'requestType': 'permission',
          'permissionDate': _formatDateForApi(pDate),
          'fromTime': fromTime,
          'toTime': toTime,
          'reason': reason,
        },
      );

      if (mounted) {
        setState(() {
          _permissionReasonController.clear();
          _permissionFromTimeController.clear();
          _permissionToTimeController.clear();
          _permissionDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission application submitted!')));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitMyWfh() async {
    final reason = _wfhReasonController.text.trim();
    final location = _wfhLocationController.text.trim();
    if (reason.isEmpty || location.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final from = _applyFromDate ?? DateTime.now();
    final to = _applyToDate ?? from;
    final token = _getToken();

    try {
      final isHalfDay = _wfhDurationType == 'Half Day';
      await _adminRepo.submitWfhRequest(
        token: token,
        data: {
          'from_date': _formatDateForApi(from),
          'to_date': _formatDateForApi(to),
          'duration_type': isHalfDay ? 'half_day' : 'full_day',
          if (isHalfDay) 'half_day_session': _wfhSession == 'First Half (Morning)' ? 'first_half' : 'second_half',
          'work_location': location,
          'reason': reason,
        },
      );

      if (mounted) {
        setState(() {
          _wfhReasonController.clear();
          _wfhLocationController.clear();
          _applyFromDate = null;
          _applyToDate = null;
          _wfhDurationType = 'Full Day';
          _wfhSession = 'First Half (Morning)';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work From Home application submitted!')));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancelMyRequest(String requestId) async {
    try {
      final token = _getToken();
      await _adminRepo.cancelLeaveRequest(token: token, requestId: requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled successfully')));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cancelling request: $e')));
      }
    }
  }
}

