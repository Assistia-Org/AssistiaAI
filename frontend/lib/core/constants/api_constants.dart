class ApiConstants {

  
  static const String baseUrl = 'https://assistiaai.onrender.com/api/v1';
  

  // Auth endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authChangePassword = '/auth/change-password';

  // Verification endpoints
  static const String verificationRequest = '/verification/request';
  static const String verificationVerify = '/verification/verify';

  // User endpoints
  static const String userMe = '/users/me';
  static String userById(String id) => '/users/$id';
  static String userByEmail(String email) => '/users/by-email?email=${Uri.encodeComponent(email)}';

  // Reservation endpoints
  static const String reservations = '/reservations/';
  static String reservationById(String id) => '/reservations/$id';
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

  // Notification endpoints
  static const String notifications = '/notifications/';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationDelete(String id) => '/notifications/$id';

  // FCM token endpoint
  static const String fcmToken = '/users/me/fcm-token';

  // Assistant endpoints
  static const String assistantChat = '/assistant/chat';
}
