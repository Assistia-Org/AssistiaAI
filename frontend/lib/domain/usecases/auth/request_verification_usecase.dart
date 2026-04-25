import '../../repositories/auth/auth_repository.dart';

class RequestVerificationUseCase {
  final AuthRepository repository;

  RequestVerificationUseCase(this.repository);

  Future<void> execute(String email) {
    return repository.requestVerification(email);
  }
}
