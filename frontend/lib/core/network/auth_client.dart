import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class AuthClient extends http.BaseClient {
  final http.Client _inner;
  final SharedPreferences _prefs;
  final Function()? onLogout;

  AuthClient(this._inner, this._prefs, {this.onLogout});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add access token if available
    final token = _prefs.getString(AppConstants.accessTokenKey);
    if (token != null && !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add base headers if not present
    AppConstants.baseHeaders.forEach((key, value) {
      if (!request.headers.containsKey(key)) {
        request.headers[key] = value;
      }
    });

    final response = await _inner.send(request);

    // If 401 Unauthorized, try to refresh token
    if (response.statusCode == 401) {
      final refreshToken = _prefs.getString(AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        final refreshSuccess = await _attemptTokenRefresh(refreshToken);
        if (refreshSuccess) {
          // Retry the original request with new token
          final newToken = _prefs.getString(AppConstants.accessTokenKey);
          
          // Re-create the request because it might have been consumed
          final newRequest = _copyRequest(request);
          if (newToken != null) {
            newRequest.headers['Authorization'] = 'Bearer $newToken';
          }
          return await _inner.send(newRequest);
        } else {
          // Refresh failed, logout
          await _handleLogout();
        }
      } else {
        // No refresh token, logout
        await _handleLogout();
      }
    }

    return response;
  }

  Future<bool> _attemptTokenRefresh(String refreshToken) async {
    try {
      final response = await _inner.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRefresh}'),
        headers: AppConstants.baseHeaders,
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await _prefs.setString(AppConstants.accessTokenKey, newAccessToken);
        if (newRefreshToken != null) {
          await _prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
        }
        return true;
      }
    } catch (e) {
      // Log error if needed
    }
    return false;
  }

  Future<void> _handleLogout() async {
    await _prefs.remove(AppConstants.accessTokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
    if (onLogout != null) {
      onLogout!();
    }
  }

  // Helper to copy request for retry
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest newRequest;
    if (request is http.Request) {
      newRequest = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    } else if (request is http.MultipartRequest) {
      newRequest = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    } else {
      // Cannot copy StreamedRequest or other unknown request types
      throw StateError('Cannot retry request of type ${request.runtimeType}');
    }
    return newRequest;
  }
}
