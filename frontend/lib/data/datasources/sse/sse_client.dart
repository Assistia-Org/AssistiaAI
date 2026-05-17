import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class SSEClient {
  final SharedPreferences? _prefs;
  http.Client? _streamClient;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  SSEClient(this._prefs);

  Stream<Map<String, dynamic>> get stream => _eventController.stream;

  void connect() {
    if (_isConnected) return;
    _isConnected = true;
    _reconnect();
  }

  void _reconnect() async {
    if (!_isConnected || _prefs == null) return;
    
    // Always get the latest token from prefs
    String? token = _prefs!.getString(AppConstants.accessTokenKey);
    if (token == null) {
      _scheduleReconnect();
      return;
    }

    _streamClient = http.Client();
    
    try {
      final request = http.Request('GET', Uri.parse('${ApiConstants.baseUrl}/sse/stream'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';

      final response = await _streamClient!.send(request);

      if (response.statusCode == 200) {
        response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
          (String line) {
            if (line.startsWith('data: ')) {
              final dataStr = line.substring(6).trim();
              if (dataStr.isNotEmpty) {
                try {
                  final data = jsonDecode(dataStr);
                  _eventController.add(data);
                } catch (e) {
                  debugPrint('SSE JSON Decode error: $e');
                }
              }
            }
          },
          onError: (error) {
            debugPrint('SSE Stream Error: $error');
            _scheduleReconnect();
          },
          onDone: () {
            debugPrint('SSE Stream closed by server');
            _scheduleReconnect();
          },
          cancelOnError: true,
        );
      } else if (response.statusCode == 401) {
        debugPrint('SSE 401 Unauthorized - attempting token refresh');
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          _reconnect(); // Retry immediately with new token
        } else {
          _scheduleReconnect();
        }
      } else {
        debugPrint('SSE Connection failed with status: ${response.statusCode}');
        _scheduleReconnect();
      }
    } catch (e) {
      debugPrint('SSE Connection Exception: $e');
      _scheduleReconnect();
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    if (_prefs == null) return false;
    final refreshToken = _prefs!.getString(AppConstants.refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRefresh}'),
        headers: AppConstants.baseHeaders,
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await _prefs!.setString(AppConstants.accessTokenKey, newAccessToken);
        if (newRefreshToken != null) {
          await _prefs!.setString(AppConstants.refreshTokenKey, newRefreshToken);
        }
        return true;
      }
    } catch (e) {
      debugPrint('SSE Token Refresh Error: $e');
    }
    return false;
  }

  void _scheduleReconnect() {
    if (!_isConnected) return;
    _streamClient?.close();
    Future.delayed(const Duration(seconds: 5), () {
      if (_isConnected) {
        _reconnect();
      }
    });
  }

  void disconnect() {
    _isConnected = false;
    _streamClient?.close();
    _streamClient = null;
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}
