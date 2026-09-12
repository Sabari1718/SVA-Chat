class ApiConstants {
  static const String baseUrl = 'https://employee-management.srivagroups.in/api/v1';
  
  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static String qrStatus(String qrToken) => '$baseUrl/auth/qr/status/$qrToken';

  // Admin Dashboard & Management Endpoints
  static const String chatUnread = '$baseUrl/chat/unread';
  static const String heartbeat = '$baseUrl/employee/session/heartbeat';
  static const String employees = '$baseUrl/employees';
  static const String loginSessions = '$baseUrl/employee/login-sessions';
  static String employeeLoginSessions(String id) => '$baseUrl/employee/login-sessions/$id';
  static const String sessionCurrent = '$baseUrl/employee/session/current';
  static const String sessionLogin = '$baseUrl/employee/session/login';
  static String sessionDaily(String date) => '$baseUrl/employee/session/daily?date=$date';
  static const String tasks = '$baseUrl/tasks';
  static const String projects = '$baseUrl/projects';
  static const String adminPendingLeaves = '$baseUrl/leave-permission/admin?status=pending';

  // Chat Endpoints
  static const String chatMembers = '$baseUrl/chat/members';
  static String chatActivity(String id) => '$baseUrl/chat/activity/$id';
  static const String chatConversations = '$baseUrl/chat/conversations';
  static String chatMessages(String convId) => '$baseUrl/chat/messages/$convId';
  static const String chatSendMessage = '$baseUrl/chat/messages';
  static const String chatGroups = '$baseUrl/chat/groups';
  static const String chatUpload = '$baseUrl/chat/upload';
  
  // Leave & Permission Endpoints
  static const String leavePermissionAdmin = '$baseUrl/leave-permission/admin';
  static const String leavePermissionMy = '$baseUrl/leave-permission/my';
  static const String leavePermissionSubmit = '$baseUrl/leave-permission';
  static const String leavePermissionWfh = '$baseUrl/leave-permission/work-from-home';
  static String leavePermissionUpdate(String requestId) => '$baseUrl/leave-permission/$requestId';
  static String leavePermissionCancel(String requestId) => '$baseUrl/leave-permission/$requestId/cancel';
  
  // Employee Endpoint
  static String employeeUpdate(String id) => '$baseUrl/employees/$id';

  // Payslip Endpoint
  static const String payslips = '$baseUrl/payslips';

  // Attendance
  static String employeeAttendance(String month, {String? employeeId}) {
    final query = (employeeId != null && employeeId.isNotEmpty)
        ? '?month=$month&employeeId=$employeeId'
        : '?month=$month';
    return '$baseUrl/employee/attendance$query';
  }
}

