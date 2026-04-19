import 'dart:io';
import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<Reservation> createReservation(Reservation reservation);
  Future<List<Reservation>> getMyReservations();
  Future<Map<String, dynamic>> analyzeTicket(File file, String mimeType);
  Future<Map<String, dynamic>> analyzeBusTicket(File file, String mimeType);
}
