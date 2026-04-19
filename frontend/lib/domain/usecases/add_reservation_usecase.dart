import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class AddReservationUseCase {
  final ReservationRepository repository;

  AddReservationUseCase(this.repository);

  Future<Reservation> execute(Reservation reservation) async {
    return await repository.createReservation(reservation);
  }
}
