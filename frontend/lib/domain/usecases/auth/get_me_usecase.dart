import '../../entities/user/user.dart';
import '../../repositories/auth/auth_repository.dart';

class GetMeUseCase {
  final AuthRepository repository;

  GetMeUseCase(this.repository);

  Future<User> execute(String token) {
    return repository.getMe(token);
  }
}
