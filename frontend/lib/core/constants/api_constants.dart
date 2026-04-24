class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Auth endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authChangePassword = '/auth/change-password';

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
