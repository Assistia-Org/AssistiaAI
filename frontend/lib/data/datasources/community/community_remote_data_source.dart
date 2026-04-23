import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/community/community_model.dart';

class CommunityRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  CommunityRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
  });

  Future<CommunityModel> createCommunity({
    required String name,
    required String type,
  }) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.communities}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
      body: jsonEncode({
        'name': name,
        'type': type,
      }),
    );

    if (response.statusCode == 201) {
      return CommunityModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Topluluk oluşturulamadı: ${response.body}');
    }
  }

  Future<List<CommunityModel>> getMyCommunities() async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myCommunities}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CommunityModel.fromJson(json)).toList();
    } else {
      throw Exception('Topluluklar yüklenemedi: ${response.body}');
    }
  }

  Future<CommunityModel> getCommunityById(String id) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.communityDetail(id)}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      return CommunityModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Topluluk detayı yüklenemedi: ${response.body}');
    }
  }

  Future<CommunityModel> updateCommunity({
    required String id,
    String? name,
    String? type,
    List<CommunityMemberModel>? members,
  }) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (members != null) {
      body['members'] = members.map((m) => m.toJson()).toList();
    }

    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.communityDetail(id)}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return CommunityModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Topluluk güncellenemedi: ${response.body}');
    }
  }

  Future<void> deleteCommunity(String id) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.communityDetail(id)}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Topluluk silinemedi: ${response.body}');
    }
  }

  Future<void> leaveCommunity(String id) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.communityLeave(id)}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Topluluktan ayrılma başarısız: ${response.body}');
    }
  }

  Future<void> removeCommunityMember(String communityId, String userId) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.communityRemoveMember(communityId, userId)}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Üye silinemedi: ${response.body}');
    }
  }
}
