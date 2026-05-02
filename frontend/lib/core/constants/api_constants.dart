import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.180:8000/api/v1';
      default:
        return 'http://localhost:8000/api/v1';
    }
  }

  // Auth endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';

  // User endpoints
  static const String userMe = '/users/me';
  static String userById(String id) => '/users/$id';
  static String userByEmail(String email) => '/users/by-email?email=${Uri.encodeComponent(email)}';

  // Reservation endpoints
  static const String reservations = '/reservations/';
  static const String reservationsAnalyze = '/reservations/analyze';
  static const String reservationsAnalyzeBus = '/reservations/analyze-bus';

  // Daily Program endpoints
  static String dailyProgramsByDate(String dateStr) => '/daily-programs/date/$dateStr';

  // Task endpoints
  static const String tasks = '/tasks/';
  static String tasksByUserId(String userId) => '/tasks/user/$userId';

  // Community endpoints
  static const String communities = '/communities/';
  static const String myCommunities = '/communities/me';
  static String communityDetail(String id) => '/communities/$id';
  static String communityLeave(String id) => '/communities/$id/leave';
  static String communityRemoveMember(String communityId, String userId) => '/communities/$communityId/members/$userId';
}
