import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';

class SSEClient {
  http.Client? _streamClient;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _eventController.stream;

  void connect(String token) {
    if (_isConnected) return;
    _isConnected = true;
    _reconnect(token);
  }

  void _reconnect(String token) async {
    if (!_isConnected) return;
    
    // Create a dedicated client for this long-running request
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
            _scheduleReconnect(token);
          },
          onDone: () {
            debugPrint('SSE Stream closed by server');
            _scheduleReconnect(token);
          },
          cancelOnError: true,
        );
      } else {
        debugPrint('SSE Connection failed with status: ${response.statusCode}');
        _scheduleReconnect(token);
      }
    } catch (e) {
      debugPrint('SSE Connection Exception: $e');
      _scheduleReconnect(token);
    }
  }

  void _scheduleReconnect(String token) {
    if (!_isConnected) return;
    _streamClient?.close();
    Future.delayed(const Duration(seconds: 5), () {
      if (_isConnected) {
        _reconnect(token);
      }
    });
  }

  void disconnect() {
    _isConnected = false;
    _streamClient?.close();
    _streamClient = null;
  }
}
