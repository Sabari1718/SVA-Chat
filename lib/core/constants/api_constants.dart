class ApiConstants {
  static const String baseUrl = 'https://employee-management.srivagroups.in/api/v1';
  
  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static String qrStatus(String qrToken) => '$baseUrl/auth/qr/status/$qrToken';
}
