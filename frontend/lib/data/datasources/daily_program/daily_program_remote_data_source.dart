import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/daily_program/daily_program_model.dart';

class DailyProgramRemoteDataSource {
  final String baseUrl = 'http://10.0.2.2:8000/api/v1';
  final http.Client client;
  final SharedPreferences sharedPreferences;

  DailyProgramRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
  });

  Future<DailyProgramModel> getProgramByDate(String dateStr) async {
    final token = sharedPreferences.getString('access_token');

    final response = await client.get(
      Uri.parse('$baseUrl/daily-programs/date/$dateStr'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return DailyProgramModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      // Return a structured "empty" program if not found to handle gracefully in UI
      return DailyProgramModel(
        id: '',
        tarih: DateTime.parse(dateStr),
        kullaniciId: '',
        ozet: DailyProgramSummary(),
        items: DailyProgramItems(tasks: [], etkinlikler: []),
      );
    } else {
      throw Exception('Sistem hatası: ${response.statusCode}');
    }
  }
}
