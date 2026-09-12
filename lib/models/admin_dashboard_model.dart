import 'package:equatable/equatable.dart';

class AdminDashboardModel extends Equatable {
  final int totalEmployees;
  final int totalManagers;
  final int onlineStaff;
  final int pendingLeaves;
  final int pendingTasks;
  final int activeProjects;
  final int totalUnreadChats;

  final List<Map<String, dynamic>> rawEmployees;
  final List<Map<String, dynamic>> rawSessions;
  final List<Map<String, dynamic>> rawTasks;
  final List<Map<String, dynamic>> rawProjects;
  final List<Map<String, dynamic>> rawPendingLeaves;

  const AdminDashboardModel({
    required this.totalEmployees,
    required this.totalManagers,
    required this.onlineStaff,
    required this.pendingLeaves,
    required this.pendingTasks,
    required this.activeProjects,
    required this.totalUnreadChats,
    this.rawEmployees = const [],
    this.rawSessions = const [],
    this.rawTasks = const [],
    this.rawProjects = const [],
    this.rawPendingLeaves = const [],
  });

  factory AdminDashboardModel.fromApiData({
    required List<dynamic> employeesJson,
    required List<dynamic> sessionsJson,
    required List<dynamic> tasksJson,
    required List<dynamic> projectsJson,
    required List<dynamic> pendingLeavesJson,
    required Map<String, dynamic> unreadChatJson,
  }) {
    // 1. Employees & Managers
    int staffCount = 0;
    int managerCount = 0;
    final parsedEmployees = <Map<String, dynamic>>[];

    for (final item in employeesJson) {
      if (item is Map<String, dynamic>) {
        parsedEmployees.add(item);
        final role = (item['role'] as String? ?? '').toLowerCase();
        final department = (item['department'] as String? ?? '').toLowerCase();

        if (role != 'admin') {
          staffCount++;
        }
        if (role == 'manager' || department.contains('manager')) {
          managerCount++;
        }
      }
    }

    // 2. Online Staff (Unique employees currently WORKING or active)
    final onlineUserIds = <String>{};
    final parsedSessions = <Map<String, dynamic>>[];

    for (final item in sessionsJson) {
      if (item is Map<String, dynamic>) {
        parsedSessions.add(item);
        final status = (item['status'] as String? ?? '').toUpperCase();
        final sessionStatus = (item['sessionStatus'] as String? ?? '').toLowerCase();
        final logoutAt = item['logoutAt'];

        final isWorking = status == 'WORKING' || sessionStatus == 'active' || (logoutAt == null && status != 'LOGGED_OUT');
        if (isWorking) {
          final empId = item['employeeId'] as String? ?? item['userId'] as String? ?? item['userName'] as String? ?? '';
          if (empId.isNotEmpty) {
            onlineUserIds.add(empId);
          }
        }
      }
    }

    // 3. Tasks (Pending = not completed)
    int pendingTasksCount = 0;
    final parsedTasks = <Map<String, dynamic>>[];
    for (final item in tasksJson) {
      if (item is Map<String, dynamic>) {
        parsedTasks.add(item);
        final status = (item['status'] as String? ?? '').toLowerCase();
        if (status != 'completed') {
          pendingTasksCount++;
        }
      }
    }

    // 4. Projects (Active = not completed)
    int activeProjectsCount = 0;
    final parsedProjects = <Map<String, dynamic>>[];
    for (final item in projectsJson) {
      if (item is Map<String, dynamic>) {
        parsedProjects.add(item);
        final status = (item['status'] as String? ?? '').toLowerCase();
        if (status != 'completed') {
          activeProjectsCount++;
        }
      }
    }

    // 5. Pending Leaves
    final parsedLeaves = <Map<String, dynamic>>[];
    for (final item in pendingLeavesJson) {
      if (item is Map<String, dynamic>) {
        parsedLeaves.add(item);
      }
    }

    // 6. Unread Chats
    final totalUnread = unreadChatJson['totalUnread'] as int? ?? 0;

    return AdminDashboardModel(
      totalEmployees: staffCount > 0 ? staffCount : parsedEmployees.length,
      totalManagers: managerCount,
      onlineStaff: onlineUserIds.length,
      pendingLeaves: parsedLeaves.length,
      pendingTasks: pendingTasksCount,
      activeProjects: activeProjectsCount,
      totalUnreadChats: totalUnread,
      rawEmployees: parsedEmployees,
      rawSessions: parsedSessions,
      rawTasks: parsedTasks,
      rawProjects: parsedProjects,
      rawPendingLeaves: parsedLeaves,
    );
  }

  static const defaultFallback = AdminDashboardModel(
    totalEmployees: 11,
    totalManagers: 0,
    onlineStaff: 6,
    pendingLeaves: 0,
    pendingTasks: 8,
    activeProjects: 9,
    totalUnreadChats: 0,
  );

  @override
  List<Object?> get props => [
        totalEmployees,
        totalManagers,
        onlineStaff,
        pendingLeaves,
        pendingTasks,
        activeProjects,
        totalUnreadChats,
        rawEmployees,
        rawSessions,
        rawTasks,
        rawProjects,
        rawPendingLeaves,
      ];
}
