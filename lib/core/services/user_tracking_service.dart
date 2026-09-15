import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class UserTrackingService {
  static final http.Client _client = http.Client();

  /// Automatically tracks user login and increments login count on Mobile Admin
  static Future<void> trackUserLogin({
    required String userId,
    required String email,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.userLoginTracking);
      final cleanUserId = userId.trim().isNotEmpty ? userId.trim() : email.trim();
      final body = {
        'userid': cleanUserId,
        'username_or_email': email.trim(),
        'ime_number': 'device_${cleanUserId.hashCode.abs()}',
        'latitude': '11.0168',
        'longitude': '76.9558',
        'app_id': 'VACHAT-43253',
        'app_name': 'VA Chat',
      };

      debugPrint('[UserTrackingService] Sending login tracking for $cleanUserId...');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint('[UserTrackingService] Response (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('[UserTrackingService] Tracking error: $e');
      // Non-blocking: App login continues even if tracking network blips
    }
  }
}
