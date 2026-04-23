import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user/user_model.dart';
import '../../../domain/entities/user/user.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';

class UserRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  UserRemoteDataSource({required this.client, required this.sharedPreferences});

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

  Future<User> updateMe({String? name, String? username, String? email}) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    if (token == null) throw Exception('No access token found');

    // Fetch current user to get the ID
    final currentUser = await getMe(token);

    final Map<String, dynamic> body = {};
    if (name != null) body['display_name'] = name;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;

    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userById(currentUser.id)}'),
      headers: {
        ...AppConstants.baseHeaders,
        ...AppConstants.authHeader(token),
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
