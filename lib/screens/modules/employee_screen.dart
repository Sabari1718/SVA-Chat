import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  bool _isCreateExpanded = false;
  final _searchController = TextEditingController();

  // Create form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController(text: 'Engineering');
  String _selectedRole = 'Employee';
  bool _obscurePassword = true;

  final List<String> _roleOptions = ['Employee', 'Admin'];

  // Sample employee directory matching screenshot exactly
  final List<Map<String, dynamic>> _employees = [
    {
      'id': 'emp-11',
      'name': 'Sabarishwaran',
      'dept': 'App Developer',
      'email': 'sabarishwaran1718@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 14, 2026',
      'avatar': 'S',
      'avatarColor': const Color(0xFF3B82F6),
    },
    {
      'id': 'emp-10',
      'name': 'Kannan',
      'dept': 'App web developer',
      'email': 'kannannsenthil@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 14, 2026',
      'avatar': 'K',
      'avatarColor': const Color(0xFFEF4444),
    },
    {
      'id': 'admin-102',
      'name': 'Kalaivani',
      'dept': 'Owner',
      'email': 'kalaivanissd@gmail.com',
      'role': 'Admin',
      'status': 'Active',
      'createdAt': 'Aug 13, 2026',
      'avatar': 'K',
      'avatarColor': const Color(0xFF8B5CF6),
    },
    {
      'id': 'emp-09',
      'name': 'Kavin Kumar',
      'dept': 'Full Stack Developer',
      'email': 'skavinshanmugavel@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'K',
      'avatarColor': const Color(0xFF10B981),
    },
    {
      'id': 'emp-08',
      'name': 'Sachin',
      'dept': 'Data entry',
      'email': 'sachinsachin0707s@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'S',
      'avatarColor': const Color(0xFFF97316),
    },
    {
      'id': 'emp-07',
      'name': 'Dhanush',
      'dept': 'Full Stack Developer',
      'email': 'dhanusjd@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'D',
      'avatarColor': const Color(0xFF6366F1),
    },
    {
      'id': 'emp-06',
      'name': 'Lohit',
      'dept': 'Full Stack Developer',
      'email': 'lovelylohit004@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'L',
      'avatarColor': const Color(0xFFEC4899),
    },
    {
      'id': 'emp-05',
      'name': 'Aruna',
      'dept': 'Data Entry',
      'email': 'arunamaraj23@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'A',
      'avatarColor': const Color(0xFFEAB308),
    },
    {
      'id': 'emp-04',
      'name': 'Iniya',
      'dept': 'Data entry',
      'email': 'sriniya2123@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'I',
      'avatarColor': const Color(0xFF14B8A6),
    },
    {
      'id': 'emp-03',
      'name': 'Sri Hari',
      'dept': 'Full Stack Developer',
      'email': 'srihari8489@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'S',
      'avatarColor': const Color(0xFF06B6D4),
    },
    {
      'id': 'emp-02',
      'name': 'Yudesh Prasath',
      'dept': 'Full Stack Developer',
      'email': 'yudeshprasath@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'Y',
      'avatarColor': const Color(0xFF84CC16),
    },
    {
      'id': 'emp-01',
      'name': 'Krishna',
      'dept': 'Full stack developer',
      'email': 'krishnankrishnaks12@gmail.com',
      'role': 'Employee',
      'status': 'Active',
      'createdAt': 'Aug 12, 2026',
      'avatar': 'K',
      'avatarColor': const Color(0xFFF43F5E),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _departmentController.text = 'Engineering';
      _selectedRole = 'Employee';
    });
  }

  void _createEmployee() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (Name, Email, Password)'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final newId = _selectedRole == 'Admin'
        ? 'admin-${100 + _employees.length}'
        : 'emp-${_employees.length + 1 < 10 ? '0${_employees.length + 1}' : '${_employees.length + 1}'}';

    setState(() {
      _employees.insert(0, {
        'id': newId,
        'name': name,
        'dept': _departmentController.text.trim(),
        'email': email,
        'role': _selectedRole,
        'status': 'Active',
        'createdAt': 'Sep 11, 2026',
        'avatar': name[0].toUpperCase(),
        'avatarColor': _selectedRole == 'Admin' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
      });
      _resetForm();
      _isCreateExpanded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Employee "$name" created successfully!'),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredEmployees = _employees.where((e) {
      final name = (e['name'] as String).toLowerCase();
      final email = (e['email'] as String).toLowerCase();
      final dept = (e['dept'] as String).toLowerCase();
      final id = (e['id'] as String).toLowerCase();
      return name.contains(query) || email.contains(query) || dept.contains(query) || id.contains(query);
    }).toList();

    final totalUsers = _employees.length;
    final adminsCount = _employees.where((e) => e['role'] == 'Admin').length;
    final activeCount = _employees.where((e) => e['status'] == 'Active').length;

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
          'Employee Management',
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
                  // 1. Header with Stats Pods matching Screenshot 1
                  _buildHeaderSection(totalUsers, adminsCount, activeCount),
                  const SizedBox(height: 16),

                  // 2. Create New Employee Card / Accordion
                  _buildCreateEmployeeCard(),
                  const SizedBox(height: 20),

                  // 3. Employee Directory Title & Search
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Directory',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage accounts, roles, and status of organization members',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or department...',
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
                  const SizedBox(height: 14),

                  // 4. Employee Directory Feed (Mobile-Optimized Cards)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredEmployees.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      return _buildEmployeeCard(emp, index);
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

  Widget _buildHeaderSection(int total, int admins, int active) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee Management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Admin Portal - Create, configure roles, and manage team member access.',
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

          // 3 Metric Stat Pods
          Row(
            children: [
              Expanded(child: _buildStatPod('TOTAL USERS', '$total', const Color(0xFF4F46E5), const Color(0xFFEEF2FF))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatPod('ADMINS', '$admins', const Color(0xFF8B5CF6), const Color(0xFFF5F3FF))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatPod('ACTIVE', '$active', const Color(0xFF10B981), const Color(0xFFECFDF5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPod(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEmployeeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isCreateExpanded,
          onExpansionChanged: (val) => setState(() => _isCreateExpanded = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF4F46E5), size: 18),
          ),
          title: Text(
            'Create New Employee',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Add a new team member and assign system permissions',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Name
                  _buildInputLabel('Employee Name *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Yudesh Prasath',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Work Email ID
                  _buildInputLabel('Work Email ID *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'name@company.com',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF94A3B8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  _buildInputLabel('Password *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Min 6 characters',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Role Dropdown & Department
                  Row(
                    children: [
                      // Role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Role *'),
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
                                  value: _selectedRole,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                  items: _roleOptions.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(role, style: GoogleFonts.inter(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRole = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Department
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Department'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _departmentController,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Engineering',
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons: Reset & Create Employee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text('Reset', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _createEmployee,
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: Text('Create Employee', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp, int index) {
    final isAdmin = emp['role'] == 'Admin';
    final roleBg = isAdmin ? const Color(0xFFF5F3FF) : const Color(0xFFECFDF5);
    final roleColor = isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF059669);
    final roleBorder = isAdmin ? const Color(0xFFDDD6FE) : const Color(0xFFA7F3D0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Role Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: emp['avatarColor'] as Color,
                child: Text(
                  emp['avatar'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            emp['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
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
                      emp['dept'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Role Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: roleBorder),
                ),
                child: Text(
                  emp['role'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Bottom Details: Email + Status + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        emp['email'] as String,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: () {},
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: () {
                      setState(() => _employees.removeAt(index));
                    },
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
