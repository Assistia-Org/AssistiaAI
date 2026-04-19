import 'dart:io';
import '../../../domain/entities/reservation/reservation.dart';
import '../../../domain/repositories/reservation/reservation_repository.dart';
import '../../datasources/reservation/reservation_remote_data_source.dart';
import '../../models/reservation/reservation_model.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource remoteDataSource;

  ReservationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Reservation> createReservation(Reservation reservation) async {
    final model = ReservationModel.fromEntity(reservation);
    return await remoteDataSource.createReservation(model);
  }

  @override
  Future<List<Reservation>> getMyReservations() async {
    return await remoteDataSource.getMyReservations();
  }

  @override
  Future<Map<String, dynamic>> analyzeTicket(File file, String mimeType) async {
    return await remoteDataSource.analyzeTicket(file, mimeType);
  }

  @override
  Future<Map<String, dynamic>> analyzeBusTicket(
    File file,
    String mimeType,
  ) async {
    return await remoteDataSource.analyzeBusTicket(file, mimeType);
  }
}
