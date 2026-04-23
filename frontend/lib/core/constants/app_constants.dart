class AppConstants {
  // SharedPreferences Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // Network Headers
  static const Map<String, String> baseHeaders = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeader(String token) => {
    'Authorization': 'Bearer $token',
  };
}
