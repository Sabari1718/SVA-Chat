import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool _isCreateView = false; // Default to List view matching screenshot
  int _viewMode = 1; // Default to Card Grid view for mobile-first experience

  int? _editingIndex;
  final _projectNameController = TextEditingController();
  String _selectedStatus = 'In Progress';
  final List<String> _statusOptions = [
    'Not Started',
    'In Progress',
    'Completed',
    'On Hold',
  ];

  final List<String> _allMembers = [
    'Krishna',
    'Dhanush',
    'Yudesh Prasath',
    'Lohit',
    'Sabarishwaran',
    'Kannan',
    'Kavin',
    'Aruna',
  ];
  List<String> _selectedMembers = ['Krishna'];

  // Project dataset matching Screenshot 3 & 4
  final List<Map<String, dynamic>> _projects = [
    {
      'name': 'Business setup',
      'members': ['Krishna'],
      'status': 'In Progress',
    },
    {
      'name': 'validation Form',
      'members': ['Dhanush'],
      'status': 'In Progress',
    },
    {
      'name': 'OX',
      'members': ['Yudesh Prasath', 'Lohit'],
      'status': 'In Progress',
    },
    {
      'name': 'User',
      'members': ['Yudesh Prasath', 'Lohit', 'Sabarishwaran'],
      'status': 'In Progress',
    },
    {
      'name': 'Billing',
      'members': ['Krishna'],
      'status': 'In Progress',
    },
    {
      'name': 'Chat',
      'members': ['Lohit', 'Kannan'],
      'status': 'Completed',
    },
    {
      'name': 'Manage',
      'members': ['Yudesh Prasath', 'Lohit'],
      'status': 'In Progress',
    },
    {
      'name': 'Mobile Authenticator',
      'members': ['Kannan'],
      'status': 'In Progress',
    },
    {
      'name': 'Billing App',
      'members': ['Kannan'],
      'status': 'In Progress',
    },
  ];

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'on hold':
        return const Color(0xFFF59E0B);
      case 'not started':
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFECFDF5);
      case 'in progress':
        return const Color(0xFFEFF6FF);
      case 'on hold':
        return const Color(0xFFFFFBEB);
      case 'not started':
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  void _startCreateProject() {
    setState(() {
      _editingIndex = null;
      _projectNameController.clear();
      _selectedStatus = 'In Progress';
      _selectedMembers = ['Krishna'];
      _isCreateView = true;
    });
  }

  void _startEditProject(int index) {
    final project = _projects[index];
    setState(() {
      _editingIndex = index;
      _projectNameController.text = project['name'] as String;
      _selectedStatus = project['status'] as String;
      _selectedMembers = List<String>.from(project['members'] as List<String>);
      _isCreateView = true;
    });
  }

  void _deleteProject(int index) {
    final name = _projects[index]['name'];
    setState(() {
      _projects.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project "$name" deleted'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _saveProject() {
    final name = _projectNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Project Name')),
      );
      return;
    }

    setState(() {
      if (_editingIndex != null && _editingIndex! < _projects.length) {
        _projects[_editingIndex!] = {
          'name': name,
          'members': List<String>.from(_selectedMembers),
          'status': _selectedStatus,
        };
      } else {
        _projects.insert(0, {
          'name': name,
          'members': List<String>.from(_selectedMembers),
          'status': _selectedStatus,
        });
      }
      _isCreateView = false;
      _editingIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project saved successfully!'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  void _showMemberSelectDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Team Members', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _allMembers.map((member) {
                    final isChecked = _selectedMembers.contains(member);
                    return CheckboxListTile(
                      title: Text(member, style: GoogleFonts.inter(fontSize: 14)),
                      value: isChecked,
                      activeColor: const Color(0xFF0F172A),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedMembers.add(member);
                          } else {
                            _selectedMembers.remove(member);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ],
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
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Project Management',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header matching Screenshot 3
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_outlined, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Management',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Create and manage your projects & teams.',
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
                  const SizedBox(height: 18),

                  // Top Action Bar: [List] vs [+ Create Project] on LEFT, [Table] vs [Grid] on RIGHT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: List vs Create toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            _buildLeftToggleOption(
                              label: 'List',
                              icon: Icons.format_list_bulleted_rounded,
                              isSelected: !_isCreateView,
                              onTap: () => setState(() => _isCreateView = false),
                            ),
                            const SizedBox(width: 4),
                            _buildLeftToggleOption(
                              label: 'Create Project',
                              icon: Icons.add_circle_outline_rounded,
                              isSelected: _isCreateView,
                              onTap: _startCreateProject,
                            ),
                          ],
                        ),
                      ),

                      // Right: Table View vs Grid View Switcher Box Icons
                      if (!_isCreateView)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            children: [
                              _buildViewSwitcherIcon(
                                icon: Icons.table_rows_rounded,
                                isSelected: _viewMode == 0,
                                onTap: () => setState(() => _viewMode = 0),
                                tooltip: 'Table View',
                              ),
                              const SizedBox(width: 4),
                              _buildViewSwitcherIcon(
                                icon: Icons.grid_view_rounded,
                                isSelected: _viewMode == 1,
                                onTap: () => setState(() => _viewMode = 1),
                                tooltip: 'Card Grid View',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // View Mode 1: Create or Edit Form
                  if (_isCreateView) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingIndex != null ? 'Edit Project' : 'Create New Project',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the form below to launch a new project item.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel('Project Name *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _projectNameController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Website Development',
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildFieldLabel('Team Members *'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _showMemberSelectDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _selectedMembers.isEmpty
                                        ? Text(
                                            'Select team members...',
                                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                                          )
                                        : Text(
                                            _selectedMembers.join(', '),
                                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildFieldLabel('Status *'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                items: _statusOptions.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedStatus = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => setState(() => _isCreateView = false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _saveProject,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  _editingIndex != null ? 'Update Project' : 'Save Project',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // View Mode 2: Table or Grid View
                    if (_viewMode == 0) _buildTableView() else _buildGridView(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Table View matching Screenshot 3
  Widget _buildTableView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(label: Text('S.NO')),
                DataColumn(label: Text('PROJECT NAME')),
                DataColumn(label: Text('TEAM MEMBERS')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: List.generate(_projects.length, (index) {
                final project = _projects[index];
                final status = project['status'] as String;
                final color = _getStatusColor(status);
                final bg = _getStatusBg(status);
                final members = project['members'] as List<String>;

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)))),
                    DataCell(
                      Text(
                        project['name'] as String,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: members.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => _startEditProject(index),
                            tooltip: 'Edit Project',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _deleteProject(index),
                            tooltip: 'Delete Project',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // Grid / Card View matching Screenshot 4
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 520 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _projects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final project = _projects[index];
            final status = project['status'] as String;
            final color = _getStatusColor(status);
            final bg = _getStatusBg(status);
            final members = project['members'] as List<String>;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: PROJECT #ID | Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROJECT #${index + 1}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
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
                    ],
                  ),

                  // Project Name
                  Text(
                    project['name'] as String,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Team Members
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team Members:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: members.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Bottom Action Buttons matching Screenshot 4: [Edit] and [Delete]
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _startEditProject(index),
                          icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteProject(index),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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

  Widget _buildLeftToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSwitcherIcon({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
