import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_upload_helper.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  int _requestTab = 0; // 0: Leave, 1: Permission, 2: Work From Home

  // Leave Form
  String _leaveType = 'Casual Leave';
  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Privilege Leave', 'Compensatory Off'];
  DateTime _leaveFromDate = DateTime.now().add(const Duration(days: 1));
  DateTime _leaveToDate = DateTime.now().add(const Duration(days: 1));
  final _leaveReasonController = TextEditingController();
  String? _attachedDocName;
  String? _attachedDocPath;

  // Permission Form
  DateTime _permissionDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _fromTime = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 17, minute: 0);
  final _permissionReasonController = TextEditingController();

  // Work From Home Form matching Screenshot 1
  DateTime _wfhFromDate = DateTime.now().add(const Duration(days: 1));
  DateTime _wfhToDate = DateTime.now().add(const Duration(days: 1));
  String _wfhDurationType = 'Full Day'; // 'Full Day' or 'Half Day'
  final _wfhLocationController = TextEditingController();
  final _wfhReasonController = TextEditingController();

  // Submitted Requests List
  final List<Map<String, dynamic>> _submittedRequests = [
    {
      'id': 'REQ-1082',
      'type': 'Casual Leave',
      'dateTime': '18/09/2026 - 19/09/2026',
      'duration': '2 Days',
      'detail': 'Family function',
      'status': 'Approved',
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

  int _calculateDays(DateTime from, DateTime to) {
    final diff = to.difference(from).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  Future<void> _pickDateRange(bool isWfh, bool isFrom) async {
    final current = isWfh
        ? (isFrom ? _wfhFromDate : _wfhToDate)
        : (isFrom ? _leaveFromDate : _leaveToDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        if (isWfh) {
          if (isFrom) {
            _wfhFromDate = picked;
            if (_wfhToDate.isBefore(_wfhFromDate)) _wfhToDate = _wfhFromDate;
          } else {
            _wfhToDate = picked;
            if (_wfhToDate.isBefore(_wfhFromDate)) _wfhFromDate = _wfhToDate;
          }
        } else {
          if (isFrom) {
            _leaveFromDate = picked;
            if (_leaveToDate.isBefore(_leaveFromDate)) _leaveToDate = _leaveFromDate;
          } else {
            _leaveToDate = picked;
            if (_leaveToDate.isBefore(_leaveFromDate)) _leaveFromDate = _leaveToDate;
          }
        }
      });
    }
  }

  void _submitRequest() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final randId = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    if (_requestTab == 0) {
      // Leave
      final reason = _leaveReasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter leave reason')));
        return;
      }
      final days = _calculateDays(_leaveFromDate, _leaveToDate);
      setState(() {
        _submittedRequests.insert(0, {
          'id': randId,
          'type': _leaveType,
          'dateTime': '${dateFormat.format(_leaveFromDate)} - ${dateFormat.format(_leaveToDate)}',
          'duration': '$days Days',
          'detail': reason,
          'status': 'Pending',
        });
        _leaveReasonController.clear();
      });
    } else if (_requestTab == 1) {
      // Permission
      final reason = _permissionReasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter permission reason')));
        return;
      }
      setState(() {
        _submittedRequests.insert(0, {
          'id': randId,
          'type': 'Permission',
          'dateTime': '${dateFormat.format(_permissionDate)} (${_fromTime.format(context)} - ${_toTime.format(context)})',
          'duration': '2 Hours',
          'detail': reason,
          'status': 'Pending',
        });
        _permissionReasonController.clear();
      });
    } else {
      // Work From Home
      final location = _wfhLocationController.text.trim();
      final reason = _wfhReasonController.text.trim();
      if (location.isEmpty || reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter work location and reason')),
        );
        return;
      }
      final days = _calculateDays(_wfhFromDate, _wfhToDate);
      setState(() {
        _submittedRequests.insert(0, {
          'id': randId,
          'type': 'Work From Home ($_wfhDurationType)',
          'dateTime': '${dateFormat.format(_wfhFromDate)} - ${dateFormat.format(_wfhToDate)}',
          'duration': '$days Days',
          'detail': '$location • $reason',
          'status': 'Pending',
        });
        _wfhLocationController.clear();
        _wfhReasonController.clear();
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request submitted successfully!'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  void _deleteRequest(int index) {
    final id = _submittedRequests[index]['id'];
    setState(() {
      _submittedRequests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request $id cancelled'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'pending':
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Leave & Permission'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
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
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Apply for casual leave, sick leave, permissions, or Work From Home and track real-time approval status.',
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

                  // Section 1: Apply Request Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply Request',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3 Tab Option Buttons: [Leave] [Permission] [Work From Home]
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildRequestTabButton(0, 'Leave', Icons.calendar_today_outlined),
                            _buildRequestTabButton(1, 'Permission', Icons.access_time_rounded),
                            _buildRequestTabButton(2, 'Work From Home', Icons.home_work_outlined),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // TAB 0: LEAVE FORM
                        if (_requestTab == 0) ...[
                          _buildLeaveTypeField(),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  'From Date *',
                                  dateFormat.format(_leaveFromDate),
                                  () => _pickDateRange(false, true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDateField(
                                  'To Date *',
                                  dateFormat.format(_leaveToDate),
                                  () => _pickDateRange(false, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildDaysBadge(_calculateDays(_leaveFromDate, _leaveToDate)),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Reason *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _leaveReasonController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Enter leave reason...',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Supporting Document Upload
                          _buildFieldLabel('Supporting Document / Medical Certificate (Optional)'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_attachedDocName != null) ...[
                                FileUploadHelper.buildPreviewThumbnail(pathOrUrl: _attachedDocPath ?? '', size: 36),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _attachedDocName!,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                                  onPressed: () => setState(() {
                                    _attachedDocName = null;
                                    _attachedDocPath = null;
                                  }),
                                ),
                              ] else ...[
                                OutlinedButton.icon(
                                  onPressed: () {
                                    FileUploadHelper.showImageSourcePicker(
                                      context: context,
                                      title: 'Upload Supporting Document',
                                      onFileSelected: (path, name) {
                                        setState(() {
                                          _attachedDocPath = path;
                                          _attachedDocName = name;
                                        });
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                                  label: const Text('Upload Document / Photo'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _submitRequest,
                            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            label: const Text('Apply Leave'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ]

                        // TAB 1: PERMISSION FORM
                        else if (_requestTab == 1) ...[
                          _buildDateField(
                            'Permission Date *',
                            dateFormat.format(_permissionDate),
                            () async {
                              final p = await showDatePicker(
                                context: context,
                                initialDate: _permissionDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (p != null) setState(() => _permissionDate = p);
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimePickerField('From Time *', _fromTime.format(context), () async {
                                  final t = await showTimePicker(context: context, initialTime: _fromTime);
                                  if (t != null) setState(() => _fromTime = t);
                                }),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTimePickerField('To Time *', _toTime.format(context), () async {
                                  final t = await showTimePicker(context: context, initialTime: _toTime);
                                  if (t != null) setState(() => _toTime = t);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Reason *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _permissionReasonController,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Enter permission reason...'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _submitRequest,
                            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            label: const Text('Apply Permission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ]

                        // TAB 2: WORK FROM HOME FORM matching Screenshot 1 exactly
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateField(
                                  'From Date *',
                                  dateFormat.format(_wfhFromDate),
                                  () => _pickDateRange(true, true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDateField(
                                  'To Date *',
                                  dateFormat.format(_wfhToDate),
                                  () => _pickDateRange(true, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Days badge + WFH Duration radio buttons matching Screenshot 1
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildDaysBadge(_calculateDays(_wfhFromDate, _wfhToDate)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('WFH Duration'),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildDurationRadio('Full Day'),
                                      const SizedBox(width: 14),
                                      _buildDurationRadio('Half Day'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Work Location / Address *
                          _buildFieldLabel('Work Location / Address *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _wfhLocationController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your work-from-home location (e.g. Chennai, Home Address)...',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reason *
                          _buildFieldLabel('Reason *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _wfhReasonController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Enter reason for Work From Home...',
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _submitRequest,
                            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            label: const Text('Apply Work From Home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: My Submitted Requests
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Submitted Requests',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Total: ${_submittedRequests.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),

                        // Table or Empty State
                        if (_submittedRequests.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No leave, permission, or Work From Home requests submitted yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 750),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                  headingTextStyle: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                  dataRowMinHeight: 52,
                                  dataRowMaxHeight: 58,
                                  columns: const [
                                    DataColumn(label: Text('REQUEST ID')),
                                    DataColumn(label: Text('TYPE')),
                                    DataColumn(label: Text('DATE / TIME')),
                                    DataColumn(label: Text('DAYS / DURATION')),
                                    DataColumn(label: Text('LOCATION / DETAIL')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('ACTION')),
                                  ],
                                  rows: List.generate(_submittedRequests.length, (index) {
                                    final req = _submittedRequests[index];
                                    final status = req['status'] as String;
                                    final color = _getStatusColor(status);
                                    final bg = _getStatusBg(status);

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(req['id'] as String, style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600))),
                                        DataCell(Text(req['type'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                                        DataCell(Text(req['dateTime'] as String, style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(Text(req['duration'] as String, style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 150),
                                            child: Text(
                                              req['detail'] as String,
                                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: color.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              status,
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                            onPressed: () => _deleteRequest(index),
                                            tooltip: 'Cancel Request',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRequestTabButton(int index, String label, IconData icon) {
    final isSelected = _requestTab == index;
    return InkWell(
      onTap: () => setState(() => _requestTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '[ $label ]',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Leave Type *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _leaveType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _leaveTypes.map((t) {
                return DropdownMenuItem<String>(
                  value: t,
                  child: Text(t, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _leaveType = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String formattedDate, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField(String label, String formattedTime, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formattedTime,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysBadge(int days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          Text(
            '$days Days (Auto-calculated)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationRadio(String value) {
    final isSelected = _wfhDurationType == value;
    return InkWell(
      onTap: () => setState(() => _wfhDurationType = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                width: isSelected ? 4.5 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
