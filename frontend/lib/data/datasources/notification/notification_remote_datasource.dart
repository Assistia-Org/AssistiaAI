import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/notification/notification_model.dart';

class NotificationRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  NotificationRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
  });

  String? get _token => sharedPreferences.getString('access_token');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<NotificationListModel> getNotifications() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}');
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return NotificationListModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load notifications: ${response.statusCode}');
  }

  Future<void> markAsRead(String notificationId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.notificationMarkRead(notificationId)}',
    );
    final response = await client.patch(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.notificationsReadAll}',
    );
    final response = await client.patch(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.notificationDelete(notificationId)}',
    );
    final response = await client.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }

  Future<void> registerFcmToken(String fcmToken) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.fcmToken}');
    final response = await client.patch(
      uri,
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    if (response.statusCode != 200) {
      debugPrint('Failed to register FCM token: ${response.statusCode}');
    }
  }
}
