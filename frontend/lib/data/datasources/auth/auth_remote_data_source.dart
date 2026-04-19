import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/user/user_model.dart';
import '../../../domain/entities/user/user.dart';

class AuthRemoteDataSource {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  // The plan requested to be tested on Chrome, so we use localhost
  final String baseUrl = 'http://localhost:8000/api/v1';
  final http.Client client;
  final SharedPreferences sharedPreferences;

  AuthRemoteDataSource({required this.client, required this.sharedPreferences});

  Future<User> register({required String name, required String email, required String password}) async {
    const uuid = Uuid();
    final uniqueId = uuid.v4();

    // The backend uses 'display_name' and 'username', we map 'name' to both for simplicity.
    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': uniqueId,
        'username': name.replaceAll(' ', '').toLowerCase(),
        'display_name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<User> login({required String email, required String password}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      
      // Save tokens
      await sharedPreferences.setString('access_token', accessToken);
      if (refreshToken != null) {
        await sharedPreferences.setString('refresh_token', refreshToken);
      }

      // Now fetch user details
      return await getMe(accessToken);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

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

  Future<void> logout() async {
    await sharedPreferences.remove('access_token');
    await sharedPreferences.remove('refresh_token');
  }
}
