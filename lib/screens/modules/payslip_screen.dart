import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_upload_helper.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  int _selectedOption = 0; // 0: Option 1 - Single Page Payslip, 1: Option 2 - Monthly Separate Payslips

  // Employee & Period Selection
  String _selectedEmployee = 'Sabarishwaran (EMP-9824)';
  final List<String> _employeeList = [
    '-- Choose Employee --',
    'Sabarishwaran (EMP-9824)',
    'Krishna (EMP-8412)',
    'Lohit (EMP-7321)',
    'Dhanush (EMP-9021)',
    'Kavin (EMP-1024)',
  ];
  String _payPeriodType = 'Monthly (1 Month)';
  String _payMonth = 'August';
  final List<String> _monthList = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final _payYearController = TextEditingController(text: '2026');

  // Earnings Controllers
  final _basicSalaryController = TextEditingController(text: '45000');
  final _hraController = TextEditingController(text: '15000');
  final _conveyanceController = TextEditingController(text: '3000');
  final _medicalController = TextEditingController(text: '2500');
  final _specialController = TextEditingController(text: '5000');
  final _otherAllowanceController = TextEditingController(text: '0');
  final _bonusController = TextEditingController(text: '0');
  final _overtimeController = TextEditingController(text: '0');

  // Deductions Controllers
  final _pfController = TextEditingController(text: '3600');
  final _esiController = TextEditingController(text: '750');
  final _profTaxController = TextEditingController(text: '200');
  final _tdsController = TextEditingController(text: '550');
  final _loanController = TextEditingController(text: '0');
  final _advanceController = TextEditingController(text: '0');
  final _otherDeductionController = TextEditingController(text: '0');

  // Payment Info
  String _paymentMode = 'Bank Transfer';
  final _paymentDateController = TextEditingController(text: '09/11/2026');
  final _bankNameController = TextEditingController(text: 'HDFC Bank');
  final _accountNumberController = TextEditingController(text: '•••••••• 1234');

  // Option 2 Filter
  final _filterController = TextEditingController();

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
    return _parseVal(_basicSalaryController) +
        _parseVal(_hraController) +
        _parseVal(_conveyanceController) +
        _parseVal(_medicalController) +
        _parseVal(_specialController) +
        _parseVal(_otherAllowanceController) +
        _parseVal(_bonusController) +
        _parseVal(_overtimeController);
  }

  int get _totalDeductions {
    return _parseVal(_pfController) +
        _parseVal(_esiController) +
        _parseVal(_profTaxController) +
        _parseVal(_tdsController) +
        _parseVal(_loanController) +
        _parseVal(_advanceController) +
        _parseVal(_otherDeductionController);
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

  void _generatePayslip() {
    if (_selectedEmployee == '-- Choose Employee --') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    final newPayslip = {
      'id': 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'employee': _selectedEmployee,
      'monthYear': '$_payMonth ${_payYearController.text}',
      'gross': _totalGrossEarnings,
      'deductions': _totalDeductions,
      'net': _netSalary,
      'bank': _bankNameController.text,
      'date': _paymentDateController.text,
    };

    setState(() {
      _generatedPayslips.insert(0, newPayslip);
      _selectedOption = 1; // Switch to Option 2 list view
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payslip generated and saved successfully!'),
        backgroundColor: Color(0xFF0F172A),
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
                                        decoration: const InputDecoration(
                                          hintText: 'Filter by Employee Name, Code, or Payslip ID...',
                                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildFilterDropdown('All Months / Period')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildFilterDropdown('All Years')),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    TextField(
                                      controller: _filterController,
                                      decoration: const InputDecoration(
                                        hintText: 'Filter by Employee, Code, or ID...',
                                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildFilterDropdown('All Months')),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildFilterDropdown('All Years')),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Empty state or generated list matching Screenshot 4
                          if (_generatedPayslips.isEmpty)
                            Center(
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
                                      'No monthly payslips have been created yet. Generate a payslip in Option 1 to save it here.',
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
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _generatedPayslips.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final p = _generatedPayslips[index];
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
                                                  child: Text(
                                                    p['employee'],
                                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '₹ ${p['net']}',
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
                                                    'Period: ${p['monthYear']} • Date: ${p['date']}',
                                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Downloading PDF for ${p['id']}...')),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.download_rounded, size: 13),
                                                  label: const Text('PDF'),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
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
                                                Text(
                                                  p['employee'],
                                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Period: ${p['monthYear']} • Date: ${p['date']}',
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
                                                '₹ ${p['net']}',
                                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                                              ),
                                              const SizedBox(width: 12),
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Downloading PDF for ${p['id']}...')),
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
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
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
    );
  }

  Widget _buildHeaderActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
                _buildAmountRow('Basic Salary (₹)', _basicSalaryController),
                _buildAmountRow('HRA (₹)', _hraController),
                _buildAmountRow('Conveyance Allowance (₹)', _conveyanceController),
                _buildAmountRow('Medical Allowance (₹)', _medicalController),
                _buildAmountRow('Special Allowance (₹)', _specialController),
                _buildAmountRow('Other Allowance (₹)', _otherAllowanceController),
                _buildAmountRow('Bonus (₹)', _bonusController),
                _buildAmountRow('Overtime Pay (₹)', _overtimeController),
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
                _buildAmountRow('PF (Provident Fund) (₹)', _pfController),
                _buildAmountRow('ESI (Insurance) (₹)', _esiController),
                _buildAmountRow('Professional Tax (₹)', _profTaxController),
                _buildAmountRow('TDS (Income Tax) (₹)', _tdsController),
                _buildAmountRow('Loan Deduction (₹)', _loanController),
                _buildAmountRow('Advance Deduction (₹)', _advanceController),
                _buildAmountRow('Other Deduction (₹)', _otherDeductionController),
                const SizedBox(height: 48), // align heights
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

  Widget _buildAmountRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
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
            child: DropdownButton<String>(
              value: _selectedEmployee,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _employeeList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedEmployee = v);
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

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [DropdownMenuItem(value: label, child: Text(label, style: GoogleFonts.inter(fontSize: 12)))],
          onChanged: (_) {},
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
