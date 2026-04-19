import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskRemoteDataSource {
  final String baseUrl = "http://10.0.2.2:8000/api/v1"; // Android Emulator
  final String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzY2MTE3OTMsInN1YiI6InN0cmluZyIsInR5cGUiOiJhY2Nlc3MifQ.Cygz5M4O4BJb_a9iZ4STncKqo780rEa_a3mpZi08L5A";

  TaskRemoteDataSource();

  Future<TaskModel> createTask(TaskModel task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/user/$userId'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
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
