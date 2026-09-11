import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isCreateView = false; // Default to List view as in screenshot
  int _viewMode = 1; // Default to Card Grid view for mobile-first experience

  int? _editingIndex;
  final _taskNameController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _completionController = TextEditingController(text: '0');

  String _selectedProject = 'Business setup';
  final List<String> _projectList = [
    'Business setup',
    'OX',
    'Billing',
    'validation Form',
    'Chat',
    'Manage',
    'User',
    'Website Development',
  ];

  // Tasks dataset matching screenshot exactly
  final List<Map<String, dynamic>> _tasks = [
    {
      'name': 'Supplier create',
      'project': 'Business setup',
      'duration': '3h',
      'hours': 3,
      'minutes': 0,
      'progress': 0,
      'status': 'not started',
      'createdBy': 'Krishna',
    },
    {
      'name': 'OX Class',
      'project': 'OX',
      'duration': '22h',
      'hours': 22,
      'minutes': 0,
      'progress': 80,
      'status': 'in progress',
      'createdBy': 'Lohit',
    },
    {
      'name': 'Business setup application create',
      'project': 'Business setup',
      'duration': '0h 0m',
      'hours': 0,
      'minutes': 0,
      'progress': 100,
      'status': 'completed',
      'createdBy': 'Krishna',
    },
    {
      'name': 'Design',
      'project': 'Billing',
      'duration': '0h 0m',
      'hours': 0,
      'minutes': 0,
      'progress': 55,
      'status': 'in progress',
      'createdBy': 'Krishna',
    },
    {
      'name': 'All Validation',
      'project': 'validation Form',
      'duration': '5h',
      'hours': 5,
      'minutes': 0,
      'progress': 0,
      'status': 'not started',
      'createdBy': 'Kavin Kumar',
    },
    {
      'name': 'Conversations',
      'project': 'Chat',
      'duration': '12h',
      'hours': 12,
      'minutes': 0,
      'progress': 100,
      'status': 'completed',
      'createdBy': 'Lohit',
    },
    {
      'name': 'Manage Login',
      'project': 'Manage',
      'duration': '24h',
      'hours': 24,
      'minutes': 0,
      'progress': 68,
      'status': 'in progress',
      'createdBy': 'Lohit',
    },
    {
      'name': 'User Login',
      'project': 'User',
      'duration': '12h',
      'hours': 12,
      'minutes': 0,
      'progress': 50,
      'status': 'in progress',
      'createdBy': 'Lohit',
    },
  ];

  @override
  void dispose() {
    _taskNameController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _startCreateTask() {
    setState(() {
      _editingIndex = null;
      _taskNameController.clear();
      _hoursController.text = '0';
      _minutesController.text = '0';
      _completionController.text = '0';
      _selectedProject = _projectList.first;
      _isCreateView = true;
    });
  }

  void _startEditTask(int index) {
    final task = _tasks[index];
    setState(() {
      _editingIndex = index;
      _taskNameController.text = task['name'] as String;
      _hoursController.text = '${task['hours'] ?? 0}';
      _minutesController.text = '${task['minutes'] ?? 0}';
      _completionController.text = '${task['progress'] ?? 0}';
      final project = task['project'] as String;
      _selectedProject = _projectList.contains(project) ? project : _projectList.first;
      _isCreateView = true;
    });
  }

  void _deleteTask(int index) {
    final name = _tasks[index]['name'];
    setState(() {
      _tasks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "$name" deleted'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  String _calculateStatus(int completion) {
    if (completion <= 0) return 'not started';
    if (completion >= 100) return 'completed';
    return 'in progress';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF2563EB);
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
      case 'not started':
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  void _saveTask() {
    final name = _taskNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Task Name')),
      );
      return;
    }

    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final completion = int.tryParse(_completionController.text) ?? 0;
    final durationText = hours > 0 ? '${hours}h' : '${minutes}m';

    setState(() {
      if (_editingIndex != null && _editingIndex! < _tasks.length) {
        // Update existing task
        _tasks[_editingIndex!] = {
          'name': name,
          'project': _selectedProject,
          'duration': durationText,
          'hours': hours,
          'minutes': minutes,
          'progress': completion,
          'status': _calculateStatus(completion),
          'createdBy': _tasks[_editingIndex!]['createdBy'] ?? 'Sabarishwaran',
        };
      } else {
        // Insert new task at beginning
        _tasks.insert(0, {
          'name': name,
          'project': _selectedProject,
          'duration': durationText,
          'hours': hours,
          'minutes': minutes,
          'progress': completion,
          'status': _calculateStatus(completion),
          'createdBy': 'Sabarishwaran',
        });
      }
      _isCreateView = false;
      _editingIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task saved successfully!'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completionVal = int.tryParse(_completionController.text) ?? 0;
    final calculatedStatus = _calculateStatus(completionVal);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header matching Screenshot 1
                  Text(
                    'Task Management',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and manage organization tasks shared across all users.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Top Action Bar: [List] vs [+ Create Task] on LEFT, and [Table] vs [Grid] on RIGHT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: List vs Create Task toggle
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
                              label: 'Create Task',
                              icon: Icons.add_circle_outline_rounded,
                              isSelected: _isCreateView,
                              onTap: _startCreateTask,
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
                            _editingIndex != null ? 'Edit Task' : 'Create New Task',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the form below to log a new task item.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel('Task Name *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _taskNameController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Website Redesign Frontend',
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildFieldLabel('Project Name *'),
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
                                value: _selectedProject,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                items: _projectList.map((project) {
                                  return DropdownMenuItem<String>(
                                    value: project,
                                    child: Text(
                                      project,
                                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedProject = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildFieldLabel('Duration *'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hours', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _hoursController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: '0'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Minutes', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _minutesController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: '0'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          _buildFieldLabel('Task Completion (%) *'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _completionController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: '0',
                              suffixText: '%',
                            ),
                          ),
                          const SizedBox(height: 18),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Calculated Task Status:',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusBg(calculatedStatus),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(calculatedStatus).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    calculatedStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(calculatedStatus),
                                    ),
                                  ),
                                ),
                              ],
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
                                onPressed: _saveTask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  _editingIndex != null ? 'Update Task' : 'Save Task',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // View Mode 2: Table / Row List View (Screenshot 1)
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

  // Table View matching Screenshot 1
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
            constraints: const BoxConstraints(minWidth: 850),
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
                DataColumn(label: Text('TASK NAME')),
                DataColumn(label: Text('PROJECT NAME')),
                DataColumn(label: Text('DURATION')),
                DataColumn(label: Text('PROGRESS')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('CREATED BY')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: List.generate(_tasks.length, (index) {
                final task = _tasks[index];
                final status = task['status'] as String;
                final color = _getStatusColor(status);
                final bg = _getStatusBg(status);
                final progress = (task['progress'] as int);

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)))),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          task['name'] as String,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task['project'] as String,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                        ),
                      ),
                    ),
                    DataCell(Text(task['duration'] as String, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$progress%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    DataCell(Text(task['createdBy'] as String, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => _startEditTask(index),
                            tooltip: 'Edit Task',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _deleteTask(index),
                            tooltip: 'Delete Task',
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

  // Grid / Card View matching Screenshot 2
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 520 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tasks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final task = _tasks[index];
            final status = task['status'] as String;
            final color = _getStatusColor(status);
            final bg = _getStatusBg(status);
            final progress = (task['progress'] as int);

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
                  // Top Row: TASK #ID | Edit | Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TASK #${index + 1}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _startEditTask(index),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _deleteTask(index),
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

                  // Task Name
                  Text(
                    task['name'] as String,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Project Name pill & Created By
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Project:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          task['project'] as String,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),

                  // Created By
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Created By:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        task['createdBy'] as String,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),

                  // Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        task['duration'] as String,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),

                  // Progress Bar & Percentage
                  Row(
                    children: [
                      Text('Progress:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$progress%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
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
