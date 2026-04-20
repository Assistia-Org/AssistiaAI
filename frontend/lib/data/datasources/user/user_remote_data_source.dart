import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user/user_model.dart';
import '../../../domain/entities/user/user.dart';

class UserRemoteDataSource {
  final String baseUrl = 'http://10.0.2.2:8000/api/v1';
  final http.Client client;
  final SharedPreferences sharedPreferences;

  UserRemoteDataSource({required this.client, required this.sharedPreferences});

  Future<User> getMe(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user details: ${response.body}');
    }
  }

  Future<User> updateMe({String? name, String? username, String? email}) async {
    final token = sharedPreferences.getString('access_token');
    if (token == null) throw Exception('No access token found');

    // Fetch current user to get the ID
    final currentUser = await getMe(token);

    final Map<String, dynamic> body = {};
    if (name != null) body['display_name'] = name;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;

    final response = await client.patch(
      Uri.parse('$baseUrl/users/${currentUser.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }
}
