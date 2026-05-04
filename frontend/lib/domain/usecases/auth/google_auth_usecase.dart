import '../../entities/user/user.dart';
import '../../repositories/auth/auth_repository.dart';

class GoogleAuthUseCase {
  final AuthRepository repository;

  GoogleAuthUseCase(this.repository);

  Future<User> execute(String idToken) {
    return repository.googleAuth(idToken);
  }
}
