import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/user/user_model.dart';
import '../../../domain/entities/user/user.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';

class AuthRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  AuthRemoteDataSource({required this.client, required this.sharedPreferences});

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String verificationCode,
  }) async {
    const uuid = Uuid();
    final uniqueId = uuid.v4();

    // The backend uses 'display_name' and 'username', we map 'name' to both for simplicity.
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRegister}'),
      headers: AppConstants.baseHeaders,
      body: jsonEncode({
        'id': uniqueId,
        'username': name.replaceAll(' ', '').toLowerCase(),
        'display_name': name,
        'email': email,
        'password': password,
        'verification_code': verificationCode,
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
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authLogin}'),
      headers: AppConstants.baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];

      // Save tokens
      await sharedPreferences.setString(AppConstants.accessTokenKey, accessToken);
      if (refreshToken != null) {
        await sharedPreferences.setString(AppConstants.refreshTokenKey, refreshToken);
      }

      // Now fetch user details
      return await getMe(accessToken);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> getMe(String token) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userMe}'),
      headers: {
        ...AppConstants.baseHeaders,
        ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user details: ${response.body}');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send password reset email: ${response.body}');
    }
  }

  Future<void> sendVerificationCode(String email) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verificationRequest}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send verification code: ${response.body}');
    }
  }

  Future<void> verifyCode(String email, String code) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verificationVerify}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid verification code');
    }
  }

  Future<void> logout() async {
    await sharedPreferences.remove(AppConstants.accessTokenKey);
    await sharedPreferences.remove(AppConstants.refreshTokenKey);
  }
}
