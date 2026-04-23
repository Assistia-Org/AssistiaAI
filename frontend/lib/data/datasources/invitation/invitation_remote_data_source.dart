import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/invitation/invitation_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';

class InvitationRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  InvitationRemoteDataSource({required this.client, required this.sharedPreferences});

  /// Parses the backend error `detail` field and returns a user-friendly message.
  String _parseErrorDetail(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        // 422 Pydantic validation errors come as a list
        final firstError = detail.first;
        if (firstError is Map && firstError.containsKey('msg')) {
          return firstError['msg'].toString();
        }
      }
    } catch (_) {}
    return response.body;
  }

  Future<InvitationModel> sendInvitation({
    required String communityId,
    required String inviteeEmail,
    String role = 'member',
  }) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/invitations/'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
      body: jsonEncode({
        'community_id': communityId,
        'invitee_email': inviteeEmail,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return InvitationModel.fromJson(jsonDecode(response.body));
    } else {
      final msg = _parseErrorDetail(response);
      throw Exception(_mapErrorMessage(msg, response.statusCode));
    }
  }

  Future<List<InvitationModel>> getMyInvitations() async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/invitations/me'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InvitationModel.fromJson(json)).toList();
    } else {
      throw Exception('Davetler alınamadı: ${_parseErrorDetail(response)}');
    }
  }

  Future<InvitationModel> acceptInvitation(String invitationId) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/invitations/$invitationId/accept'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      return InvitationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Davet kabul edilemedi: ${_parseErrorDetail(response)}');
    }
  }

  Future<InvitationModel> rejectInvitation(String invitationId) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/invitations/$invitationId/reject'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
      },
    );

    if (response.statusCode == 200) {
      return InvitationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Davet reddedilemedi: ${_parseErrorDetail(response)}');
    }
  }

  String _mapErrorMessage(String backendMsg, int statusCode) {
    final lowerMsg = backendMsg.toLowerCase();
    if (lowerMsg.contains('already a member')) {
      return 'Bu kullanıcı zaten topluluğun bir üyesi.';
    }
    if (lowerMsg.contains('already exists')) {
      return 'Bu kullanıcıya zaten bekleyen bir davet gönderildi.';
    }
    if (lowerMsg.contains('not authorized')) {
      return 'Bu topluluğa davet göndermek için yetkiniz yok.';
    }
    if (lowerMsg.contains('user not found')) {
      return 'Geçersiz e-posta formatı veya kullanıcı bulunamadı.';
    }
    if (lowerMsg.contains('community not found')) {
      return 'Topluluk bulunamadı.';
    }
    if (statusCode == 404) {
      return 'Kayıt bulunamadı.';
    }
    if (statusCode == 422) {
      return 'Geçersiz e-posta adresi. Lütfen tekrar kontrol edin.';
    }
    return 'Davet gönderilemedi: $backendMsg';
  }
}
