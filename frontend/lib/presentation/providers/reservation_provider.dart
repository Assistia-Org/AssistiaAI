import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../data/datasources/reservation_remote_data_source.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/usecases/add_reservation_usecase.dart';
import '../../domain/usecases/analyze_ticket_usecase.dart';
import '../../domain/entities/reservation.dart';
import 'dart:io';

// --- Dependency Injection ---

final reservationRemoteDataSourceProvider = FutureProvider<ReservationRemoteDataSource>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final client = ref.watch(httpClientProvider);
  return ReservationRemoteDataSource(client: client, sharedPreferences: prefs);
});

final reservationRepositoryProvider = FutureProvider<ReservationRepositoryImpl>((ref) async {
  final remoteDataSource = await ref.watch(reservationRemoteDataSourceProvider.future);
  return ReservationRepositoryImpl(remoteDataSource: remoteDataSource);
});

final addReservationUseCaseProvider = FutureProvider<AddReservationUseCase>((ref) async {
  final repository = await ref.watch(reservationRepositoryProvider.future);
  return AddReservationUseCase(repository);
});

final analyzeTicketUseCaseProvider = FutureProvider<AnalyzeTicketUseCase>((ref) async {
  final repository = await ref.watch(reservationRepositoryProvider.future);
  return AnalyzeTicketUseCase(repository);
});

// --- State Management ---

class ReservationLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) {
    state = val;
  }
}

final reservationLoadingProvider = NotifierProvider<ReservationLoadingNotifier, bool>(() {
  return ReservationLoadingNotifier();
});

class ReservationController {
  final Ref ref;

  ReservationController(this.ref);

  Future<Reservation> addReservation(Reservation reservation) async {
    ref.read(reservationLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(addReservationUseCaseProvider.future);
      return await useCase.execute(reservation);
    } finally {
      ref.read(reservationLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<Map<String, dynamic>> analyzeTicket(File file, String mimeType) async {
    // We reuse the same loading state for analysis
    ref.read(reservationLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(analyzeTicketUseCaseProvider.future);
      return await useCase.execute(file, mimeType);
    } finally {
      ref.read(reservationLoadingProvider.notifier).setLoading(false);
    }
  }
}

final reservationControllerProvider = Provider<ReservationController>((ref) {
  return ReservationController(ref);
});
