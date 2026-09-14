import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_upload_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../repositories/admin_repository.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  bool _isLoading = false;

  int _selectedOption = 0; // 0: Option 1 - Single Page Payslip, 1: Option 2 - Monthly Separate Payslips

  // Live Employees & Period Selection
  final List<Map<String, dynamic>> _liveEmployees = [];
  String? _selectedEmployeeId;
  Map<String, dynamic>? _selectedEmployeeMap;

  String _payPeriodType = 'Monthly (1 Month)';
  String _payMonth = 'August';
  final List<String> _monthList = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final _payYearController = TextEditingController(text: '2026');

  // Earnings Controllers (default 0)
  final _basicSalaryController = TextEditingController(text: '0');
  final _hraController = TextEditingController(text: '0');
  final _conveyanceController = TextEditingController(text: '0');
  final _medicalController = TextEditingController(text: '0');
  final _specialController = TextEditingController(text: '0');
  final _otherAllowanceController = TextEditingController(text: '0');
  final _bonusController = TextEditingController(text: '0');
  final _overtimeController = TextEditingController(text: '0');

  // Earnings Enabled Toggles (Default OFF)
  bool _basicSalaryEnabled = false;
  bool _hraEnabled = false;
  bool _conveyanceEnabled = false;
  bool _medicalEnabled = false;
  bool _specialEnabled = false;
  bool _otherAllowanceEnabled = false;
  bool _bonusEnabled = false;
  bool _overtimeEnabled = false;

  // Deductions Controllers (default 0)
  final _pfController = TextEditingController(text: '0');
  final _esiController = TextEditingController(text: '0');
  final _profTaxController = TextEditingController(text: '0');
  final _tdsController = TextEditingController(text: '0');
  final _loanController = TextEditingController(text: '0');
  final _advanceController = TextEditingController(text: '0');
  final _otherDeductionController = TextEditingController(text: '0');

  // Deductions Enabled Toggles (Default OFF)
  bool _pfEnabled = false;
  bool _esiEnabled = false;
  bool _profTaxEnabled = false;
  bool _tdsEnabled = false;
  bool _loanEnabled = false;
  bool _advanceEnabled = false;
  bool _otherDeductionEnabled = false;

  // Payment Info
  String _paymentMode = 'Bank Transfer';
  final _paymentDateController = TextEditingController(text: '09/11/2026');
  final _bankNameController = TextEditingController(text: 'HDFC Bank');
  final _accountNumberController = TextEditingController(text: '•••••••• 1234');

  // Option 2 Filters & Search
  final _filterController = TextEditingController();
  String _filterMonth = 'All Months';
  String _filterYear = 'All Years';

  // Company Details & Signature Controllers (Screenshots 1 & 2)
  final _companyLogoUrlController = TextEditingController();
  final _signatoryNameController = TextEditingController(text: 'Authorized Signatory');
  final _signatoryDesignationController = TextEditingController(text: 'HR & Finance Director');
  final _signatureUrlController = TextEditingController();
  final _companyNameController = TextEditingController(text: 'EMPLOYEE MANAGEMENT CORP');
  final _companyAddressController = TextEditingController(
      text: '123 Innovation Tower, Tech Park, Software Zone, City - 600001');
  final _companyPhoneController = TextEditingController(text: '+91 98765 43210');
  final _companyEmailController = TextEditingController(text: 'hr@employeemanagement.com');
  final _companyWebsiteController = TextEditingController(text: 'www.employeemanagement.com');

  // Generated Payslips Storage
  final List<Map<String, dynamic>> _generatedPayslips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  String _getToken() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.token ?? '';
    }
    return '';
  }

  /// Fetches live employees, payslips, sends heartbeat, and checks unread chat
  Future<void> _loadData() async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final currentUser = authState is AuthenticatedState ? authState.user : null;
      final isEmployee = currentUser != null && !currentUser.isAdmin;

      // 4 Live APIs requested when accessing Payslip module:
      // 1. GET /api/v1/employees
      // 2. GET /api/v1/payslips
      // 3. POST /api/v1/employee/session/heartbeat
      // 4. GET /api/v1/chat/unread
      final results = await Future.wait([
        _adminRepo.getEmployees(token),
        _adminRepo.getPayslips(
          token,
          employeeId: isEmployee ? currentUser.id : null,
        ),
        _adminRepo.sendHeartbeat(token),
        _adminRepo.getChatUnreadSummary(token),
      ]);

      final employees = results[0] as List<Map<String, dynamic>>;
      final payslips = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _liveEmployees.clear();
          _liveEmployees.addAll(employees);

          _generatedPayslips.clear();
          _generatedPayslips.addAll(payslips);

          if (isEmployee) {
            _selectedEmployeeId = currentUser.id;
            _selectedEmployeeMap = _liveEmployees.firstWhere(
              (e) => e['id']?.toString() == currentUser.id,
              orElse: () => {
                'id': currentUser.id,
                'name': currentUser.name,
                'department': currentUser.department,
              },
            );
            _selectedOption = 1; // Default to Option 2 list for employee
          } else if (_selectedEmployeeId == null && _liveEmployees.isNotEmpty) {
            _selectedEmployeeId = _liveEmployees.first['id']?.toString();
            _selectedEmployeeMap = _liveEmployees.first;
          }
        });
      }
    } catch (e) {
      debugPrint('[PayslipScreen] _loadData error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Helper Getters for Payslip Card Display ---
  String _getPayslipEmployeeName(Map<String, dynamic> p) {
    if (p['employeeName'] != null && p['employeeName'].toString().isNotEmpty) {
      return p['employeeName'].toString();
    }
    if (p['employee'] is Map && p['employee']['name'] != null) {
      return p['employee']['name'].toString();
    }
    if (p['employee'] != null && p['employee'].toString().isNotEmpty) {
      return p['employee'].toString();
    }
    final empId = p['employeeId']?.toString() ?? '';
    if (empId.isNotEmpty) {
      final match = _liveEmployees.firstWhere(
        (e) => e['id']?.toString() == empId,
        orElse: () => {},
      );
      if (match.isNotEmpty && match['name'] != null) {
        return match['name'].toString();
      }
      return empId;
    }
    return 'Employee';
  }

  String _getPayslipPeriod(Map<String, dynamic> p) {
    final month = p['payMonth']?.toString() ?? '';
    final year = p['payYear']?.toString() ?? '';
    if (month.isNotEmpty || year.isNotEmpty) {
      return '$month $year'.trim();
    }
    return p['monthYear']?.toString() ?? '-';
  }

  String _getPayslipDate(Map<String, dynamic> p) {
    if (p['payment'] is Map && p['payment']['paymentDate'] != null) {
      return p['payment']['paymentDate'].toString();
    }
    if (p['paymentDate'] != null) return p['paymentDate'].toString();
    if (p['date'] != null) return p['date'].toString();
    if (p['createdAt'] != null) {
      return p['createdAt'].toString().split('T').first;
    }
    return '-';
  }

  num _getPayslipNetSalary(Map<String, dynamic> p) {
    if (p['netSalary'] != null) {
      return (p['netSalary'] as num?) ?? 0;
    }
    if (p['net'] != null) {
      return (p['net'] as num?) ?? 0;
    }
    return 0;
  }

  String _getPayslipId(Map<String, dynamic> p) {
    return p['payslipId']?.toString() ?? p['id']?.toString() ?? 'PAY';
  }

  List<Map<String, dynamic>> get _filteredPayslips {
    final query = _filterController.text.trim().toLowerCase();
    return _generatedPayslips.where((p) {
      if (_filterMonth != 'All Months' && _filterMonth != 'All Months / Period') {
        final m = p['payMonth']?.toString() ?? '';
        final my = p['monthYear']?.toString() ?? '';
        if (!m.toLowerCase().contains(_filterMonth.toLowerCase()) &&
            !my.toLowerCase().contains(_filterMonth.toLowerCase())) {
          return false;
        }
      }
      if (_filterYear != 'All Years') {
        final y = p['payYear']?.toString() ?? '';
        final my = p['monthYear']?.toString() ?? '';
        if (!y.contains(_filterYear) && !my.contains(_filterYear)) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final empName = _getPayslipEmployeeName(p).toLowerCase();
        final empId = (p['employeeId']?.toString() ?? '').toLowerCase();
        final code = _getPayslipId(p).toLowerCase();
        if (!empName.contains(query) && !empId.contains(query) && !code.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _payYearController.dispose();
    _basicSalaryController.dispose();
    _hraController.dispose();
    _conveyanceController.dispose();
    _medicalController.dispose();
    _specialController.dispose();
    _otherAllowanceController.dispose();
    _bonusController.dispose();
    _overtimeController.dispose();
    _pfController.dispose();
    _esiController.dispose();
    _profTaxController.dispose();
    _tdsController.dispose();
    _loanController.dispose();
    _advanceController.dispose();
    _otherDeductionController.dispose();
    _paymentDateController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _filterController.dispose();
    _companyLogoUrlController.dispose();
    _signatoryNameController.dispose();
    _signatoryDesignationController.dispose();
    _signatureUrlController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _companyWebsiteController.dispose();
    super.dispose();
  }

  int _parseVal(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _totalGrossEarnings {
    int total = 0;
    if (_basicSalaryEnabled) total += _parseVal(_basicSalaryController);
    if (_hraEnabled) total += _parseVal(_hraController);
    if (_conveyanceEnabled) total += _parseVal(_conveyanceController);
    if (_medicalEnabled) total += _parseVal(_medicalController);
    if (_specialEnabled) total += _parseVal(_specialController);
    if (_otherAllowanceEnabled) total += _parseVal(_otherAllowanceController);
    if (_bonusEnabled) total += _parseVal(_bonusController);
    if (_overtimeEnabled) total += _parseVal(_overtimeController);
    return total;
  }

  int get _totalDeductions {
    int total = 0;
    if (_pfEnabled) total += _parseVal(_pfController);
    if (_esiEnabled) total += _parseVal(_esiController);
    if (_profTaxEnabled) total += _parseVal(_profTaxController);
    if (_tdsEnabled) total += _parseVal(_tdsController);
    if (_loanEnabled) total += _parseVal(_loanController);
    if (_advanceEnabled) total += _parseVal(_advanceController);
    if (_otherDeductionEnabled) total += _parseVal(_otherDeductionController);
    return total;
  }

  int get _netSalary {
    final net = _totalGrossEarnings - _totalDeductions;
    return net > 0 ? net : 0;
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero Rupees Only';
    return 'Rupees $number Only';
  }

  void _resetForm() {
    setState(() {
      _basicSalaryEnabled = false;
      _hraEnabled = false;
      _conveyanceEnabled = false;
      _medicalEnabled = false;
      _specialEnabled = false;
      _otherAllowanceEnabled = false;
      _bonusEnabled = false;
      _overtimeEnabled = false;

      _pfEnabled = false;
      _esiEnabled = false;
      _profTaxEnabled = false;
      _tdsEnabled = false;
      _loanEnabled = false;
      _advanceEnabled = false;
      _otherDeductionEnabled = false;

      _basicSalaryController.text = '0';
      _hraController.text = '0';
      _conveyanceController.text = '0';
      _medicalController.text = '0';
      _specialController.text = '0';
      _otherAllowanceController.text = '0';
      _bonusController.text = '0';
      _overtimeController.text = '0';
      _pfController.text = '0';
      _esiController.text = '0';
      _profTaxController.text = '0';
      _tdsController.text = '0';
      _loanController.text = '0';
      _advanceController.text = '0';
      _otherDeductionController.text = '0';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form figures reset')),
    );
  }

  Future<void> _generatePayslip() async {
    if (_selectedEmployeeId == null || _selectedEmployeeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    final token = _getToken();
    if (token.isEmpty) return;

    final empName = _selectedEmployeeMap?['name']?.toString() ?? 'Employee';
    final dept = _selectedEmployeeMap?['department']?.toString() ?? 'General';

    final newPayslip = {
      'employeeId': _selectedEmployeeId,
      'employeeName': empName,
      'department': dept,
      'payMonth': _payMonth,
      'payYear': _payYearController.text.trim(),
      'payPeriodType': _payPeriodType,
      'earnings': {
        'basic': _basicSalaryEnabled ? _parseVal(_basicSalaryController) : 0,
        'hra': _hraEnabled ? _parseVal(_hraController) : 0,
        'conveyance': _conveyanceEnabled ? _parseVal(_conveyanceController) : 0,
        'medical': _medicalEnabled ? _parseVal(_medicalController) : 0,
        'special': _specialEnabled ? _parseVal(_specialController) : 0,
        'otherAllowance': _otherAllowanceEnabled ? _parseVal(_otherAllowanceController) : 0,
        'bonus': _bonusEnabled ? _parseVal(_bonusController) : 0,
        'overtime': _overtimeEnabled ? _parseVal(_overtimeController) : 0,
      },
      'deductions': {
        'pf': _pfEnabled ? _parseVal(_pfController) : 0,
        'esi': _esiEnabled ? _parseVal(_esiController) : 0,
        'profTax': _profTaxEnabled ? _parseVal(_profTaxController) : 0,
        'tds': _tdsEnabled ? _parseVal(_tdsController) : 0,
        'loan': _loanEnabled ? _parseVal(_loanController) : 0,
        'advance': _advanceEnabled ? _parseVal(_advanceController) : 0,
        'otherDeduction': _otherDeductionEnabled ? _parseVal(_otherDeductionController) : 0,
      },
      'payment': {
        'mode': _paymentMode,
        'paymentDate': _paymentDateController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
      },
      'status': 'Generated',
      // Legacy compatibility keys
      'employee': '$empName (${_selectedEmployeeId ?? ''})',
      'monthYear': '$_payMonth ${_payYearController.text.trim()}',
      'gross': _totalGrossEarnings,
      'net': _netSalary,
      'bank': _bankNameController.text.trim(),
      'date': _paymentDateController.text.trim(),
    };

    setState(() => _isLoading = true);
    try {
      await _adminRepo.createPayslip(token: token, data: newPayslip);
      await _loadData(); // Refresh list after creation
      if (mounted) {
        setState(() {
          _selectedOption = 1; // Switch to Option 2 list view
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payslip generated and saved successfully!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDeletePayslip(Map<String, dynamic> payslip) {
    final slipId = payslip['id']?.toString() ?? payslip['payslipId']?.toString() ?? '';
    final code = _getPayslipId(payslip);
    final empName = _getPayslipEmployeeName(payslip);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text('Delete Payslip', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete payslip $code for $empName? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final token = _getToken();
              if (token.isEmpty || slipId.isEmpty) return;
              setState(() => _isLoading = true);
              try {
                await _adminRepo.deletePayslip(token, slipId);
                setState(() {
                  _generatedPayslips.removeWhere((p) =>
                      p['id']?.toString() == slipId || p['payslipId']?.toString() == slipId);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payslip $code deleted successfully'),
                      backgroundColor: const Color(0xFF0F172A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete payslip: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCompanyDetailsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header matching Screenshot 1
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.business_center_outlined, size: 20, color: Color(0xFF0F172A)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Edit Company Details & Digital Signature',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // Scrollable Form content matching Screenshots 1 & 2
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Company Logo Section
                            _buildFieldLabel('Company Logo (Upload, Paste URL, or Ctrl+V Image)'),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      FileUploadHelper.buildPreviewThumbnail(
                                        pathOrUrl: _companyLogoUrlController.text.trim(),
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _companyLogoUrlController.text.trim().isEmpty
                                              ? 'No logo selected yet'
                                              : 'Selected: ${_companyLogoUrlController.text.trim()}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _companyLogoUrlController,
                                          style: GoogleFonts.inter(fontSize: 12),
                                          onChanged: (_) => setDialogState(() {}),
                                          decoration: InputDecoration(
                                            hintText: 'Paste logo image URL or select photo...',
                                            hintStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                            prefixIcon: const Icon(Icons.link_rounded, size: 16, color: Color(0xFF94A3B8)),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          FileUploadHelper.showImageSourcePicker(
                                            context: context,
                                            title: 'Upload Company Logo',
                                            onFileSelected: (path, name) {
                                              setDialogState(() {
                                                _companyLogoUrlController.text = path;
                                              });
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.upload_outlined, size: 14),
                                        label: Text('Upload Logo', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 2. Authorized Digital Signature Settings Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.draw_outlined, size: 17, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Authorized Digital Signature Settings',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0284C7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  _buildFieldLabel('Authorized Person Name', color: const Color(0xFF0369A1)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _signatoryNameController,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: const InputDecoration(isDense: true),
                                  ),
                                  const SizedBox(height: 12),

                                  _buildFieldLabel('Designation / Title', color: const Color(0xFF0369A1)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _signatoryDesignationController,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: const InputDecoration(isDense: true),
                                  ),
                                  const SizedBox(height: 12),

                                  _buildFieldLabel('Digital Signature Image (Upload / Paste URL / Ctrl+V Image)', color: const Color(0xFF0369A1)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      FileUploadHelper.buildPreviewThumbnail(
                                        pathOrUrl: _signatureUrlController.text.trim(),
                                        size: 38,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _signatureUrlController.text.trim().isEmpty
                                              ? 'No digital signature uploaded yet'
                                              : 'Signature: ${_signatureUrlController.text.trim()}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF0284C7),
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _signatureUrlController,
                                          style: GoogleFonts.inter(fontSize: 12),
                                          onChanged: (_) => setDialogState(() {}),
                                          decoration: InputDecoration(
                                            hintText: 'Paste signature URL or select file...',
                                            hintStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          FileUploadHelper.showImageSourcePicker(
                                            context: context,
                                            title: 'Upload Digital Signature',
                                            onFileSelected: (path, name) {
                                              setDialogState(() {
                                                _signatureUrlController.text = path;
                                              });
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.upload_outlined, size: 14, color: Color(0xFF0284C7)),
                                        label: Text('Upload Signature', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7))),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFBAE6FD)),
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 3. Company Name *
                            _buildFieldLabel('Company Name *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _companyNameController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                            ),
                            const SizedBox(height: 14),

                            // 4. Company Address *
                            _buildFieldLabel('Company Address *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _companyAddressController,
                              style: GoogleFonts.inter(fontSize: 12),
                              maxLines: 2,
                              decoration: const InputDecoration(isDense: true),
                            ),
                            const SizedBox(height: 14),

                            // 5. Phone Number
                            _buildFieldLabel('Phone Number'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _companyPhoneController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                            ),
                            const SizedBox(height: 14),

                            // 6. Email Address
                            _buildFieldLabel('Email Address'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _companyEmailController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                            ),
                            const SizedBox(height: 14),

                            // 7. Website URL
                            _buildFieldLabel('Website URL'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _companyWebsiteController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // Bottom Action Buttons matching Screenshot 2
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Company & Signature details updated!'),
                                  backgroundColor: Color(0xFF4F46E5),
                                ),
                              );
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Save Company & Signature Details',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payslip Management'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF4F46E5),
                backgroundColor: Color(0xFFEEF2FF),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bar matching Screenshot 2
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payslip Management',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Generate single-page A4 payslips or manage separate monthly payslip records.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isWide) _buildHeaderActionButtons(),
                            ],
                          ),
                          if (!isWide) ...[
                            const SizedBox(height: 12),
                            _buildHeaderActionButtons(),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Option 1 vs Option 2 Tabs matching Screenshot 2 (Responsive without overflow)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildOptionTab(0, 'Option 1 - Single Page', Icons.receipt_outlined),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildOptionTab(1, 'Option 2 - Monthly Payslips', Icons.folder_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content based on Option 1 vs Option 2
                  if (_selectedOption == 0) ...[
                    // OPTION 1: SINGLE PAGE PAYSLIP

                    // 1. Employee & Period Selection Card
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Employee & Period Selection (Single Page A4 Layout)',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 650;
                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(flex: 2, child: _buildEmployeeDropdown()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildPayPeriodDropdown()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildPayMonthDropdown()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildPayYearField()),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildEmployeeDropdown(),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildPayPeriodDropdown()),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildPayMonthDropdown()),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPayYearField(),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Gross Earnings & Total Deductions side-by-side or stacked
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildGrossEarningsCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTotalDeductionsCard()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildGrossEarningsCard(),
                              const SizedBox(height: 16),
                              _buildTotalDeductionsCard(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Payment Info & Net Salary Summary Card matching Screenshot 3
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
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Payment Info & Net Salary Summary',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 650;
                                    if (isWide) {
                                      return Row(
                                        children: [
                                          Expanded(child: _buildSimpleInput('Payment Mode', _paymentMode, (v) => setState(() => _paymentMode = v))),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildControllerInput('Payment Date', _paymentDateController)),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildControllerInput('Bank Name', _bankNameController)),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildControllerInput('Account Number', _accountNumberController)),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: _buildSimpleInput('Payment Mode', _paymentMode, (v) => setState(() => _paymentMode = v))),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildControllerInput('Payment Date', _paymentDateController)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(child: _buildControllerInput('Bank Name', _bankNameController)),
                                              const SizedBox(width: 10),
                                              Expanded(child: _buildControllerInput('Account Number', _accountNumberController)),
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Dark Bottom Net Salary Strip matching Screenshot 3
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PROMINENT NET SALARY (MONTHLY)',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white70,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'In Words: ${_numberToWords(_netSalary)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white60,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '₹ $_netSalary',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // OPTION 2: MONTHLY SEPARATE PAYSLIPS matching Screenshot 4
                    Container(
                      padding: const EdgeInsets.all(22),
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
                          Text(
                            'Monthly Separate Payslips',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Maintains distinct, month-by-month salary statements (Jan, Feb, Mar, Apr...) for each employee.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 18),

                          // Filter Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 650;
                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _filterController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          hintText: 'Filter by Employee Name, Code, or Payslip ID...',
                                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildMonthFilterDropdown()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildYearFilterDropdown()),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    TextField(
                                      controller: _filterController,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        hintText: 'Filter by Employee, Code, or ID...',
                                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildMonthFilterDropdown()),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildYearFilterDropdown()),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Empty state or generated list matching Screenshot 4
                          Builder(
                            builder: (context) {
                              final displayList = _filteredPayslips;
                              if (displayList.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.description_outlined,
                                            size: 30,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'No monthly payslips found matching the filter criteria.',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No monthly payslips match. Generate a payslip in Option 1 to save it here, or adjust filters.',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 18),
                                        ElevatedButton.icon(
                                          onPressed: () => setState(() => _selectedOption = 0),
                                          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                          label: const Text('Generate New Payslip'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF4F46E5),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayList.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final p = displayList[index];
                                  final empName = _getPayslipEmployeeName(p);
                                  final netAmount = _getPayslipNetSalary(p);
                                  final period = _getPayslipPeriod(p);
                                  final date = _getPayslipDate(p);
                                  final slipCode = _getPayslipId(p);

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, itemConstraints) {
                                        final isCompact = itemConstraints.maxWidth < 460;
                                        if (isCompact) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          empName,
                                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (slipCode.isNotEmpty)
                                                          Text(
                                                            slipCode,
                                                            style: GoogleFonts.jetBrainsMono(
                                                              fontSize: 10,
                                                              color: const Color(0xFF64748B),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '₹ $netAmount',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: const Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Period: $period • Date: $date',
                                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Downloading PDF for $slipCode...')),
                                                          );
                                                        },
                                                        icon: const Icon(Icons.download_rounded, size: 12),
                                                        label: const Text('PDF'),
                                                        style: OutlinedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          minimumSize: Size.zero,
                                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      IconButton(
                                                        onPressed: () => _confirmDeletePayslip(p),
                                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        tooltip: 'Delete Payslip',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }

                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          empName,
                                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (slipCode.isNotEmpty) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEEF2FF),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            slipCode,
                                                            style: GoogleFonts.jetBrainsMono(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: const Color(0xFF4F46E5),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Period: $period • Date: $date',
                                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '₹ $netAmount',
                                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                                                ),
                                                const SizedBox(width: 12),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Downloading PDF for $slipCode...')),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.download_rounded, size: 14),
                                                  label: const Text('PDF'),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () => _confirmDeletePayslip(p),
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                                  tooltip: 'Delete Payslip',
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.sync_rounded, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showCompanyDetailsDialog,
          icon: const Icon(Icons.business_outlined, size: 16),
          label: const Text('Company & Signature'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _resetForm,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _generatePayslip,
          icon: const Icon(Icons.description_outlined, size: 16, color: Colors.white),
          label: const Text('Generate Payslip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTab(int index, String title, IconData icon) {
    final isSelected = _selectedOption == index;
    return InkWell(
      onTap: () => setState(() => _selectedOption = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrossEarningsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gross Earnings (Monthly)',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Basic Salary (₹)',
                    controller: _basicSalaryController,
                    isEnabled: _basicSalaryEnabled,
                    onToggle: (v) {
                      setState(() {
                        _basicSalaryEnabled = v;
                        if (v && (_basicSalaryController.text.trim().isEmpty || _basicSalaryController.text.trim() == '0')) {
                          _basicSalaryController.text = '30000';
                        }
                      });
                    },
                  ),
                  _buildAmountField(
                    label: 'HRA (₹)',
                    controller: _hraController,
                    isEnabled: _hraEnabled,
                    onToggle: (v) => setState(() => _hraEnabled = v),
                  ),
                ),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Conveyance Allowance (₹)',
                    controller: _conveyanceController,
                    isEnabled: _conveyanceEnabled,
                    onToggle: (v) => setState(() => _conveyanceEnabled = v),
                  ),
                  _buildAmountField(
                    label: 'Medical Allowance (₹)',
                    controller: _medicalController,
                    isEnabled: _medicalEnabled,
                    onToggle: (v) => setState(() => _medicalEnabled = v),
                  ),
                ),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Special Allowance (₹)',
                    controller: _specialController,
                    isEnabled: _specialEnabled,
                    onToggle: (v) => setState(() => _specialEnabled = v),
                  ),
                  _buildAmountField(
                    label: 'Other Allowance (₹)',
                    controller: _otherAllowanceController,
                    isEnabled: _otherAllowanceEnabled,
                    onToggle: (v) => setState(() => _otherAllowanceEnabled = v),
                  ),
                ),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Bonus (₹)',
                    controller: _bonusController,
                    isEnabled: _bonusEnabled,
                    onToggle: (v) => setState(() => _bonusEnabled = v),
                  ),
                  _buildAmountField(
                    label: 'Overtime Pay (₹)',
                    controller: _overtimeController,
                    isEnabled: _overtimeEnabled,
                    onToggle: (v) => setState(() => _overtimeEnabled = v),
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Gross Earnings:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹ $_totalGrossEarnings',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalDeductionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Deductions (Monthly)',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'PF (Provident Fund) (₹)',
                    controller: _pfController,
                    isEnabled: _pfEnabled,
                    onToggle: (v) {
                      setState(() {
                        _pfEnabled = v;
                        if (v && (_pfController.text.trim().isEmpty || _pfController.text.trim() == '0')) {
                          _pfController.text = '3600';
                        }
                      });
                    },
                  ),
                  _buildAmountField(
                    label: 'ESI (Insurance) (₹)',
                    controller: _esiController,
                    isEnabled: _esiEnabled,
                    onToggle: (v) => setState(() => _esiEnabled = v),
                  ),
                ),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Professional Tax (₹)',
                    controller: _profTaxController,
                    isEnabled: _profTaxEnabled,
                    onToggle: (v) {
                      setState(() {
                        _profTaxEnabled = v;
                        if (v && (_profTaxController.text.trim().isEmpty || _profTaxController.text.trim() == '0')) {
                          _profTaxController.text = '200';
                        }
                      });
                    },
                  ),
                  _buildAmountField(
                    label: 'TDS (Income Tax) (₹)',
                    controller: _tdsController,
                    isEnabled: _tdsEnabled,
                    onToggle: (v) => setState(() => _tdsEnabled = v),
                  ),
                ),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Loan Deduction (₹)',
                    controller: _loanController,
                    isEnabled: _loanEnabled,
                    onToggle: (v) => setState(() => _loanEnabled = v),
                  ),
                  _buildAmountField(
                    label: 'Advance Deduction (₹)',
                    controller: _advanceController,
                    isEnabled: _advanceEnabled,
                    onToggle: (v) => setState(() => _advanceEnabled = v),
                  ),
                ),
                _buildFieldPair(
                  _buildAmountField(
                    label: 'Other Deduction (₹)',
                    controller: _otherDeductionController,
                    isEnabled: _otherDeductionEnabled,
                    onToggle: (v) => setState(() => _otherDeductionEnabled = v),
                  ),
                  null,
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Deductions:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹ $_totalDeductions',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldPair(Widget left, Widget? right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right ?? const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildAmountField({
    required String label,
    required TextEditingController controller,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Transform.scale(
              scale: 0.72,
              child: Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF22C55E),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE2E8F0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          enabled: isEnabled,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: '0',
            filled: true,
            fillColor: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDropdown() {
    final hasMatch = _selectedEmployeeId != null &&
        _liveEmployees.any((e) => e['id']?.toString() == _selectedEmployeeId);
    final currentValue = hasMatch ? _selectedEmployeeId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Select Employee *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: currentValue,
              isExpanded: true,
              hint: Text('-- Choose Employee --',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('-- Choose Employee --',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ),
                ..._liveEmployees.map((emp) {
                  final id = emp['id']?.toString() ?? '';
                  final name = emp['name']?.toString() ?? 'Employee';
                  final dept = emp['department']?.toString() ?? '';
                  final label = dept.isNotEmpty ? '$name ($id) • $dept' : '$name ($id)';
                  return DropdownMenuItem<String?>(
                    value: id,
                    child: Text(
                      label,
                      style: GoogleFonts.inter(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedEmployeeId = v;
                  if (v != null) {
                    _selectedEmployeeMap = _liveEmployees.firstWhere(
                      (e) => e['id']?.toString() == v,
                      orElse: () => {},
                    );
                  } else {
                    _selectedEmployeeMap = null;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayPeriodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Pay Period Type *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _payPeriodType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: ['Monthly (1 Month)', 'Bi-Weekly', 'Weekly']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _payPeriodType = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayMonthDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Pay Month *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _payMonth,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _monthList.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _payMonth = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayYearField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Pay Year *'),
        const SizedBox(height: 6),
        TextField(
          controller: _payYearController,
          decoration: const InputDecoration(isDense: true),
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSimpleInput(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: ['Bank Transfer', 'Cash', 'Cheque']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(fontSize: 12))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControllerInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: const InputDecoration(isDense: true),
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMonthFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterMonth,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ['All Months', ..._monthList]
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _filterMonth = v);
          },
        ),
      ),
    );
  }

  Widget _buildYearFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterYear,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ['All Years', '2026', '2025', '2024']
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y, style: GoogleFonts.inter(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _filterYear = v);
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, {Color? color}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}
