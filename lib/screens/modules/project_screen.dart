import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/admin/admin_dashboard_bloc.dart';
import '../../bloc/admin/admin_dashboard_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/admin_repository.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final _adminRepo = AdminRepository();

  bool _isCreateView = false;
  int _viewMode = 1; // 0: Table, 1: Card Grid
  bool _isLoading = false;
  bool _isSaving = false;

  int? _editingIndex;
  final _projectNameController = TextEditingController();
  String _selectedStatus = 'In Progress';
  final List<String> _statusOptions = [
    'Not Started',
    'In Progress',
    'Completed',
    'On Hold',
  ];

  List<String> _allMembers = [
    'Krishna',
    'Dhanush',
    'Yudesh Prasath',
    'Lohit',
    'Sabarishwaran',
    'Kannan',
    'Kavin',
    'Aruna',
    'Iniya',
    'Sachin',
    'Sri Hari',
    'Kavin Kumar',
  ];
  List<String> _selectedMembers = ['Krishna'];

  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final token = authState.user.token ?? '';
      if (token.isNotEmpty) {
        _fetchProjects(token);
        _fetchEmployees(token);
      }
    }
  }

  Future<void> _fetchProjects(String token) async {
    setState(() => _isLoading = true);
    try {
      final rawList = await _adminRepo.getProjects(token);
      if (mounted) {
        setState(() {
          _projects = rawList.map((item) => _normalizeProject(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees(String token) async {
    try {
      final rawEmployees = await _adminRepo.getEmployees(token);
      final names = rawEmployees
          .map((e) => e['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      if (names.isNotEmpty && mounted) {
        setState(() {
          _allMembers = names;
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic> _normalizeProject(Map<String, dynamic> item) {
    final name = item['projectName'] as String? ?? item['name'] as String? ?? 'Untitled Project';
    final rawMembers = item['teamMembers'] ?? item['members'];
    List<String> members = [];
    if (rawMembers is List) {
      members = rawMembers.map((m) => m.toString()).toList();
    }
    final status = item['status'] as String? ?? 'In Progress';
    final id = item['id'] as String? ?? '';

    return {
      'id': id,
      'name': name,
      'members': members,
      'status': status,
      'raw': item,
    };
  }

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
      _selectedMembers = _allMembers.isNotEmpty ? [_allMembers.first] : ['Admin'];
      _isCreateView = true;
    });
  }

  void _startEditProject(int index) {
    final project = _projects[index];
    setState(() {
      _editingIndex = index;
      _projectNameController.text = project['name'] as String? ?? '';
      _selectedStatus = project['status'] as String? ?? 'In Progress';
      final rawM = project['members'];
      if (rawM is List) {
        _selectedMembers = List<String>.from(rawM.map((m) => m.toString()));
      } else {
        _selectedMembers = _allMembers.isNotEmpty ? [_allMembers.first] : ['Admin'];
      }
      _isCreateView = true;
    });
  }

  Future<void> _confirmDeleteProject(int index) async {
    final project = _projects[index];
    final projectId = project['id'] as String? ?? '';
    final name = project['name'] as String? ?? 'Project';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Project?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This will immediately remove it from both Mobile and Web portal.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    final token = authState is AuthenticatedState ? authState.user.token ?? '' : '';

    setState(() => _isLoading = true);

    try {
      if (token.isNotEmpty && projectId.isNotEmpty) {
        await _adminRepo.deleteProject(token: token, projectId: projectId);
        await _fetchProjects(token);
        if (mounted) {
          context.read<AdminDashboardBloc>().add(FetchAdminDashboardData(token: token, isRefresh: true));
        }
      } else {
        setState(() {
          _projects.removeAt(index);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "$name" deleted successfully (Synced to Web)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $cleanMsg'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProject() async {
    final name = _projectNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Project Name')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final token = authState is AuthenticatedState ? authState.user.token ?? '' : '';

    // EXACT payload matching backend schema:
    // { "projectName": name, "teamMembers": _selectedMembers, "status": _selectedStatus }
    final projectPayload = {
      'projectName': name,
      'teamMembers': _selectedMembers,
      'status': _selectedStatus,
    };

    setState(() => _isSaving = true);

    try {
      if (token.isNotEmpty) {
        if (_editingIndex != null &&
            _editingIndex! < _projects.length &&
            (_projects[_editingIndex!]['id'] as String? ?? '').isNotEmpty) {
          final projectId = _projects[_editingIndex!]['id'] as String;
          await _adminRepo.updateProject(token: token, projectId: projectId, data: projectPayload);
        } else {
          await _adminRepo.createProject(token: token, data: projectPayload);
        }

        // Re-fetch all projects directly from server DB
        await _fetchProjects(token);
        if (mounted) {
          context.read<AdminDashboardBloc>().add(FetchAdminDashboardData(token: token, isRefresh: true));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingIndex != null
                ? 'Project "$name" updated successfully (Synced to Web)'
                : 'Project "$name" created successfully (Synced to Web)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving project: $cleanMsg'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isCreateView = false;
          _editingIndex = null;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final token = authState.user.token ?? '';
      if (token.isNotEmpty) {
        await _fetchProjects(token);
        await _fetchEmployees(token);
      }
    }
  }

  void _showMemberSelectDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Select Team Members',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done', style: TextStyle(color: Colors.white)),
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF7C3AED),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                                'Live synced projects from the central database.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7C3AED),
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
                                label: 'List (${_projects.length})',
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

                        // Right: View Switcher Icons
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
                              _editingIndex != null
                                  ? 'Update details below. Saved changes will immediately reflect on the Web portal.'
                                  : 'Fill in the details. Project will immediately show on the Web portal.',
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
                                hintText: 'e.g. Mobile Authenticator App',
                              ),
                            ),
                            const SizedBox(height: 18),

                            _buildFieldLabel('Project Status *'),
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
                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildFieldLabel('Team Members *'),
                                TextButton.icon(
                                  onPressed: _showMemberSelectDialog,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Manage Members'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedMembers.map((member) {
                                return Chip(
                                  label: Text(member, style: GoogleFonts.inter(fontSize: 12)),
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () {
                                    if (_selectedMembers.length > 1) {
                                      setState(() => _selectedMembers.remove(member));
                                    }
                                  },
                                );
                              }).toList(),
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
                                  onPressed: _isSaving ? null : _saveProject,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text(
                                          _editingIndex != null ? 'Update Project' : 'Save Project',
                                          style: GoogleFonts.inter(
                                              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // View Mode 2: Table / Grid View
                      if (_projects.isEmpty && !_isLoading)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text('No projects found.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else if (_viewMode == 0)
                        _buildTableView()
                      else
                        _buildGridView(),
                    ],
                  ],
                ),
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
                final members = project['members'] as List<dynamic>;

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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStackedAvatars(members),
                          const SizedBox(width: 8),
                          Text(
                            members.join(', '),
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _confirmDeleteProject(index),
                            tooltip: 'Delete Project',
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
            final members = project['members'] as List<dynamic>;

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
                  // Top Row: Project Index | Edit | Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROJECT #${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _startEditProject(index),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _confirmDeleteProject(index),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
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

                  // Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
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

                  const Divider(height: 12, color: Color(0xFFF1F5F9)),

                  // Team Members
                  Row(
                    children: [
                      _buildStackedAvatars(members),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          members.join(', '),
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildStackedAvatars(List<dynamic> members) {
    final display = members.take(3).toList();
    return SizedBox(
      height: 24,
      width: (display.length * 16.0) + 8,
      child: Stack(
        children: List.generate(display.length, (i) {
          final initial = display[i].toString().isNotEmpty ? display[i].toString()[0].toUpperCase() : 'M';
          return Positioned(
            left: i * 16.0,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: _getAvatarColor(display[i].toString()),
              child: Text(
                initial,
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
    ];
    return colors[name.hashCode.abs() % colors.length];
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
