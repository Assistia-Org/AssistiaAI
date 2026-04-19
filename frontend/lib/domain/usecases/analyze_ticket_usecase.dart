import 'dart:io';
import '../repositories/reservation_repository.dart';

class AnalyzeTicketUseCase {
  final ReservationRepository repository;

  AnalyzeTicketUseCase(this.repository);

  Future<Map<String, dynamic>> execute(File file, String mimeType) async {
    return await repository.analyzeTicket(file, mimeType);
  }
}
