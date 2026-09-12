import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  /// POST /api/v1/auth/login
  Future<UserModel> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.login);
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final loginAt = data['loginAt'] as String?;
        final userData = data['user'] as Map<String, dynamic>;

        return UserModel.fromJson(
          userData,
          token: token,
          loginAt: loginAt,
        );
      } else {
        final errorMsg = responseData['message'] as String? ?? 'Login failed. Please check credentials.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  /// GET /api/v1/auth/qr/status/{qrToken}
  Future<Map<String, dynamic>> checkQrStatus(String qrToken) async {
    try {
      final url = Uri.parse(ApiConstants.qrStatus(qrToken.trim()));
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return responseData['data'] as Map<String, dynamic>? ?? {};
      } else {
        final errorMsg = responseData['message'] as String? ?? 'Failed to retrieve QR status.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: Unable to verify QR ($e)');
    }
  }

  /// POST /api/v1/auth/logout
  Future<void> logout(String token) async {
    try {
      final url = Uri.parse(ApiConstants.logout);
      await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignore errors on logout as we will clear local state anyway
    }
  }

  /// POST /api/v1/employee/session/login
  Future<void> triggerSessionLogin(String token) async {
    try {
      final url = Uri.parse(ApiConstants.sessionLogin);
      await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Non-blocking, ignore errors if it fails or if already active
    }
  }
}
