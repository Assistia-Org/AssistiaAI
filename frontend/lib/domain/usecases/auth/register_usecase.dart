import '../../entities/user/user.dart';
import '../../repositories/auth/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> execute({required String name, required String email, required String password, required String verificationCode}) {
    return repository.register(name: name, email: email, password: password, verificationCode: verificationCode);
  }
}
