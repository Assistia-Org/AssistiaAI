import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/reservation/reservation_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';

class ReservationRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  ReservationRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
  });

  Future<ReservationModel> createReservation(
    ReservationModel reservation,
  ) async {
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reservations}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
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
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    // We don't need user_id in URL as backend gets it from token
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reservations}'),
      headers: {
        ...AppConstants.baseHeaders,
        if (token != null) ...AppConstants.authHeader(token),
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
    final token = sharedPreferences.getString(AppConstants.accessTokenKey);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reservationsAnalyze}'),
    );

    if (token != null) {
      request.headers.addAll(AppConstants.authHeader(token));
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
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reservationsAnalyzeBus}'),
    );

    if (token != null) {
      request.headers.addAll(AppConstants.authHeader(token));
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
