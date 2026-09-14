import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/admin_dashboard_model.dart';

class AdminRepository {
  final http.Client _client;

  AdminRepository({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      };

  /// Sends background heartbeat to keep active session status updated
  Future<int> sendHeartbeat(String token) async {
    try {
      final url = Uri.parse(ApiConstants.heartbeat);
      final response = await _client.post(
        url,
        headers: _headers(token),
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode;
    } catch (e) {
      debugPrint('[AdminRepository] Heartbeat failed: $e');
      return 500;
    }
  }

  Future<Map<String, dynamic>?> fetchEmployeeSessionCurrent(String token) async {
    try {
      final url = Uri.parse(ApiConstants.sessionCurrent);
      final response = await _client.get(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint('[AdminRepository] fetchEmployeeSessionCurrent error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchEmployeeSessionDaily(String token, String date) async {
    try {
      final url = Uri.parse(ApiConstants.sessionDaily(date));
      final response = await _client.get(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint('[AdminRepository] fetchEmployeeSessionDaily error: $e');
    }
    return null;
  }

  /// Employee Session Initialization
  Future<void> initEmployeeSession(String token) async {
    try {
      await Future.wait([
        sendHeartbeat(token),
        _safeGet(ApiConstants.chatUnread, token),
      ]);
    } catch (e) {
      debugPrint('[AdminRepository] Error init employee session: $e');
    }
  }

  /// Fetches all 7 Admin APIs in parallel using Future.wait
  Future<AdminDashboardModel> fetchAdminDashboardData(String token) async {
    try {
      final results = await Future.wait([
        _safeGet(ApiConstants.employees, token),
        _safeGet(ApiConstants.loginSessions, token),
        _safeGet(ApiConstants.tasks, token),
        _safeGet(ApiConstants.projects, token),
        _safeGet(ApiConstants.adminPendingLeaves, token),
        _safeGet(ApiConstants.chatUnread, token),
        sendHeartbeat(token),
      ]);

      final employeesData = _extractList(results[0]);
      final sessionsData = _extractList(results[1]);
      final tasksData = _extractList(results[2]);
      final projectsData = _extractList(results[3]);
      final leavesData = _extractList(results[4]);
      final unreadData = _extractMap(results[5]);

      return AdminDashboardModel.fromApiData(
        employeesJson: employeesData,
        sessionsJson: sessionsData,
        tasksJson: tasksData,
        projectsJson: projectsData,
        pendingLeavesJson: leavesData,
        unreadChatJson: unreadData,
      );
    } catch (e) {
      debugPrint('[AdminRepository] Error fetching dashboard data: $e');
      throw Exception('Failed to load admin dashboard: $e');
    }
  }

  // ==========================================
  // TASKS CRUD
  // ==========================================

  Future<List<Map<String, dynamic>>> getTasks(String token) async {
    final res = await _safeGet(ApiConstants.tasks, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTask({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.tasks);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to create task' : 'Failed to create task';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] createTask error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTask({
    required String token,
    required String taskId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.tasks}/$taskId');
      final response = await _client
          .put(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to update task' : 'Failed to update task';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] updateTask error: $e');
      rethrow;
    }
  }

  Future<bool> deleteTask({
    required String token,
    required String taskId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.tasks}/$taskId');
      final response = await _client
          .delete(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to delete task' : 'Failed to delete task';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] deleteTask error: $e');
      rethrow;
    }
  }

  // ==========================================
  // PROJECTS CRUD
  // ==========================================

  Future<List<Map<String, dynamic>>> getProjects(String token) async {
    final res = await _safeGet(ApiConstants.projects, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProject({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.projects);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to create project' : 'Failed to create project';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] createProject error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProject({
    required String token,
    required String projectId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.projects}/$projectId');
      final response = await _client
          .put(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to update project' : 'Failed to update project';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] updateProject error: $e');
      rethrow;
    }
  }

  Future<bool> deleteProject({
    required String token,
    required String projectId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.projects}/$projectId');
      final response = await _client
          .delete(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to delete project' : 'Failed to delete project';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] deleteProject error: $e');
      rethrow;
    }
  }

  // ==========================================
  // LEAVE & PERMISSION
  // ==========================================

  Future<List<Map<String, dynamic>>> getAdminLeaveRequests({
    required String token,
    String requestType = 'all',
    String status = 'all',
  }) async {
    try {
      final queryParams = <String, String>{};
      if (requestType.isNotEmpty) queryParams['requestType'] = requestType;
      if (status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse(ApiConstants.leavePermissionAdmin).replace(
        queryParameters: queryParams,
      );

      final response = await _client
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return (decoded['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      return const [];
    } catch (e) {
      debugPrint('[AdminRepository] getAdminLeaveRequests error: $e');
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyLeaveRequests(String token) async {
    try {
      final uri = Uri.parse(ApiConstants.leavePermissionMy);
      final response = await _client
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return (decoded['data'] as List).cast<Map<String, dynamic>>();
        }
      }
      return const [];
    } catch (e) {
      debugPrint('[AdminRepository] getMyLeaveRequests error: $e');
      return const [];
    }
  }

  Future<Map<String, dynamic>> submitLeaveRequest({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.leavePermissionSubmit);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to submit request' : 'Failed to submit request';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] submitLeaveRequest error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitWfhRequest({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.leavePermissionWfh);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to submit WFH request' : 'Failed to submit WFH request';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] submitWfhRequest error: $e');
      rethrow;
    }
  }

  Future<bool> cancelLeaveRequest({
    required String token,
    required String requestId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.leavePermissionCancel(requestId));
      final response = await _client
          .put(
            url,
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to cancel request' : 'Failed to cancel request';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] cancelLeaveRequest error: $e');
      rethrow;
    }
  }


  Future<Map<String, dynamic>> updateLeaveRequest({
    required String token,
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.leavePermissionUpdate(requestId));
      final response = await _client
          .put(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to update request' : 'Failed to update request';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] updateLeaveRequest error: $e');
      rethrow;
    }
  }

  // ==========================================
  // EMPLOYEES
  // ==========================================

  Future<List<Map<String, dynamic>>> getEmployees(String token) async {
    final res = await _safeGet(ApiConstants.employees, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createEmployee({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.employees);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to create employee' : 'Failed to create employee';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] createEmployee error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEmployee({
    required String token,
    required String employeeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.employeeUpdate(employeeId));
      final response = await _client
          .put(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to update employee' : 'Failed to update employee';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] updateEmployee error: $e');
      rethrow;
    }
  }

  Future<bool> deleteEmployee({
    required String token,
    required String employeeId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.employeeUpdate(employeeId));
      final response = await _client
          .delete(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to delete employee' : 'Failed to delete employee';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] deleteEmployee error: $e');
      rethrow;
    }
  }

  // ==========================================
  // LOGIN SESSIONS (ATTENDANCE & CALENDAR)
  // ==========================================

  Future<List<Map<String, dynamic>>> getLoginSessions(String token) async {
    final res = await _safeGet(ApiConstants.loginSessions, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getEmployeeLoginSessions(
    String token,
    String employeeId, {
    String? employeeName,
    String? employeeEmail,
  }) async {
    // 1. Try specific employee endpoint
    final res = await _safeGet(ApiConstants.employeeLoginSessions(employeeId), token);
    final list = _extractList(res).cast<Map<String, dynamic>>();
    if (list.isNotEmpty) return list;

    // 2. Fallback: query all sessions and filter by ID, Name, or Email
    final allSessions = await getLoginSessions(token);
    final idLower = employeeId.toLowerCase().trim();
    final nameLower = (employeeName ?? '').toLowerCase().trim();
    final emailLower = (employeeEmail ?? '').toLowerCase().trim();

    final filtered = allSessions.where((s) {
      final sEmpId = (s['employeeId'] ?? s['userId'] ?? '').toString().toLowerCase().trim();
      final sName = (s['employeeName'] ?? s['userName'] ?? s['name'] ?? '').toString().toLowerCase().trim();
      final sEmail = (s['employeeEmail'] ?? s['email'] ?? '').toString().toLowerCase().trim();

      if (idLower.isNotEmpty && (sEmpId == idLower || sEmpId.contains(idLower))) return true;
      if (nameLower.isNotEmpty && (sName == nameLower || sName.contains(nameLower))) return true;
      if (emailLower.isNotEmpty && sEmail == emailLower) return true;
      return false;
    }).toList();

    return filtered;
  }

  // ==========================================
  // CHAT (MEMBERS, CONVERSATIONS, MESSAGES)
  // ==========================================

  Future<List<Map<String, dynamic>>> getChatMembers(String token) async {
    final res = await _safeGet(ApiConstants.chatMembers, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getEmployeeChatActivity(String token, String employeeId) async {
    final res = await _safeGet(ApiConstants.chatActivity(employeeId), token);
    return _extractMap(res);
  }

  Future<List<Map<String, dynamic>>> getChatConversations(String token) async {
    final res = await _safeGet(ApiConstants.chatConversations, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getChatMessages({
    required String token,
    required String conversationId,
  }) async {
    final res = await _safeGet(ApiConstants.chatMessages(conversationId), token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String token,
    required String conversationId,
    required String messageText,
    String type = 'text',
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatSendMessage);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode({
              'conversationId': conversationId,
              'messageText': messageText,
              'type': type,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to send message' : 'Failed to send message';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] sendChatMessage error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createChatGroup({
    required String token,
    required String name,
    String? description,
    String? avatar,
    required List<String> memberIds,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroups);
      final body = {
        'name': name.trim(),
        'description': description?.trim() ?? '',
        'memberIds': memberIds,
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      };

      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to create group' : 'Failed to create group';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] createChatGroup error: $e');
      rethrow;
    }
  }

  Future<String?> uploadChatFile({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.chatUpload);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data']['fileUrl'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AdminRepository] uploadChatFile error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGroupDetails({
    required String token,
    required String groupId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroupDetails(groupId));
      final response = await _client
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : null;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to get group details' : 'Failed to get group details';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] getGroupDetails error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChatGroup({
    required String token,
    required String groupId,
    required String name,
    String? description,
    String? avatar,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroup(groupId));
      final body = <String, dynamic>{
        'name': name.trim(),
        'description': description?.trim() ?? '',
        'avatar': avatar,
      };

      final response = await _client
          .put(
            url,
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to update group' : 'Failed to update group';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] updateChatGroup error: $e');
      rethrow;
    }
  }

  Future<bool> addGroupMembers({
    required String token,
    required String groupId,
    required List<String> memberIds,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroupMembers(groupId));
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode({'memberIds': memberIds}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to add members' : 'Failed to add members';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] addGroupMembers error: $e');
      rethrow;
    }
  }

  Future<bool> removeGroupMember({
    required String token,
    required String groupId,
    required String memberId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroupMember(groupId, memberId));
      final response = await _client
          .delete(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to remove member' : 'Failed to remove member';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] removeGroupMember error: $e');
      rethrow;
    }
  }

  Future<bool> deleteChatGroup({
    required String token,
    required String groupId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroup(groupId));
      final response = await _client
          .delete(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to delete group' : 'Failed to delete group';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] deleteChatGroup error: $e');
      rethrow;
    }
  }

  Future<bool> leaveChatGroup({
    required String token,
    required String groupId,
    String? newAdminId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.chatGroupLeave(groupId));
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode({'newAdminId': newAdminId}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to leave group' : 'Failed to leave group';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] leaveChatGroup error: $e');
      rethrow;
    }
  }

  // ==========================================
  // PAYSLIPS
  // ==========================================

  Future<List<Map<String, dynamic>>> getPayslips(String token) async {
    final res = await _safeGet(ApiConstants.payslips, token);
    return _extractList(res).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createPayslip({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.payslips);
      final response = await _client
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded is Map<String, dynamic> ? decoded : {};
      } else {
        final errorMsg = decoded is Map ? decoded['message'] ?? 'Failed to generate payslip' : 'Failed to generate payslip';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AdminRepository] createPayslip error: $e');
      rethrow;
    }
  }

  // ==========================================
  // ATTENDANCE
  // ==========================================

  Future<Map<String, dynamic>?> getEmployeeAttendance(String token, String month, {String? employeeId}) async {
    try {
      final res = await _safeGet(ApiConstants.employeeAttendance(month, employeeId: employeeId), token);
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[AdminRepository] getEmployeeAttendance error: $e');
      return null;
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Future<dynamic> _safeGet(String urlString, String token) async {
    try {
      final url = Uri.parse(urlString);
      final response = await _client
          .get(url, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] != null) {
          return decoded['data'];
        }
        return decoded;
      } else {
        debugPrint('[AdminRepository] Request to $urlString returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[AdminRepository] Exception requesting $urlString: $e');
      return null;
    }
  }

  List<dynamic> _extractList(dynamic input) {
    if (input is List) return input;
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic input) {
    if (input is Map<String, dynamic>) return input;
    return const {};
  }
}
