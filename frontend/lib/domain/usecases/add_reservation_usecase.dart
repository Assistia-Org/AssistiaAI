import '../entities/reservation/reservation.dart';
import '../repositories/reservation/reservation_repository.dart';

class AddReservationUseCase {
  final ReservationRepository repository;

  AddReservationUseCase(this.repository);

  Future<Reservation> execute(Reservation reservation) async {
    return await repository.createReservation(reservation);
  }
}
