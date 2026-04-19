import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/reservation/reservation_model.dart';

class ReservationRemoteDataSource {
  final String baseUrl = 'http://10.0.2.2:8000/api/v1';
  final http.Client client;
  final SharedPreferences sharedPreferences;

  ReservationRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
  });

  Future<ReservationModel> createReservation(
    ReservationModel reservation,
  ) async {
    final token = sharedPreferences.getString('access_token');

    final response = await client.post(
      Uri.parse('$baseUrl/reservations/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(reservation.toJson()),
    );

    if (response.statusCode == 201) {
      return ReservationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Rezervasyon oluşturulamadı: ${response.body}');
    }
  }

  Future<List<ReservationModel>> getMyReservations() async {
    final token = sharedPreferences.getString('access_token');

    // We don't need user_id in URL as backend gets it from token
    final response = await client.get(
      Uri.parse('$baseUrl/reservations/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ReservationModel.fromJson(json)).toList();
    } else {
      throw Exception('Rezervasyonlar yüklenemedi: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> analyzeTicket(File file, String mimeType) async {
    final token = sharedPreferences.getString('access_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/reservations/analyze'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Analiz hatası: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> analyzeBusTicket(
    File file,
    String mimeType,
  ) async {
    final token = sharedPreferences.getString('access_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/reservations/analyze-bus'),
    );

    if (token != null) {
      request.headers['Authorization'] =
          'Bearer $token'; // ignore: unnecessary_null_comparison
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Analiz hatası (Otobüs): ${response.statusCode}');
    }
  }
}
