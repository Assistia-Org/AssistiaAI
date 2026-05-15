import '../../repositories/auth/auth_repository.dart';

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<void> execute({required String email, required String code}) {
    return repository.verifyCode(email: email, code: code);
  }
}
