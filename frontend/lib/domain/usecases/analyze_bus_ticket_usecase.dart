import 'dart:io';
import '../repositories/reservation_repository.dart';

class AnalyzeBusTicketUseCase {
  final ReservationRepository repository;

  AnalyzeBusTicketUseCase(this.repository);

  Future<Map<String, dynamic>> execute(File file, String mimeType) async {
    return await repository.analyzeBusTicket(file, mimeType);
  }
}
