import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_program_model.dart';

class DailyProgramRemoteDataSource {
  final String baseUrl = "http://10.0.2.2:8000/api/v1"; 
  final String? token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzcyMTcxNzMsInN1YiI6InN0cmluZyIsInR5cGUiOiJhY2Nlc3MifQ.Lhk0ipmndnER3r1WT73rhotRwV5XWgS0Ov8ViVVlZCY";

  DailyProgramRemoteDataSource();

  Future<DailyProgramModel> getProgramByDate(String dateStr) async {
    final response = await http.get(
      Uri.parse('$baseUrl/daily-programs/date/$dateStr'),
      headers: {
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
