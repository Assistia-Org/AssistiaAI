import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/assistant/assistant_message_model.dart';

class AssistantRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  AssistantRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
  });

  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required List<AssistantMessageModel> history,
    required String timezoneOffset,
  }) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final requestBody = {
      'message': message,
      'conversation_history': history.map((msg) => msg.toJson()).toList(),
      'timezone_offset': timezoneOffset,
    };

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.assistantChat}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Asistana ulaşılamadı: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> getDailyGreeting({String? targetDate}) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    
    var url = '${ApiConstants.baseUrl}/assistant/daily-greeting';
    if (targetDate != null) {
      url += '?target_date=$targetDate';
    }

    final response = await client.get(
      Uri.parse(url),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['greeting'] as String;
    } else {
      throw Exception('Günlük söz alınamadı: ${response.statusCode}');
    }
  }
}
