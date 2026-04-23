import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task/task_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';

class TaskRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  TaskRemoteDataSource({required this.client, required this.sharedPreferences});

  Future<TaskModel> createTask(TaskModel task) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasks}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode == 201) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Görev oluşturulamadı: ${response.statusCode}');
    }
  }

  Future<List<TaskModel>> getTasksByUserId(String userId) async {
    final token = sharedPreferences.getString('access_token');

    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasksByUserId(userId)}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } else {
      throw Exception('Görevler yüklenemedi: ${response.statusCode}');
    }
  }
}
