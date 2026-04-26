import '../../entities/user/user.dart';
import '../../repositories/user/user_repository.dart';

class GetMeUseCase {
  final UserRepository repository;

  GetMeUseCase(this.repository);

  Future<User> execute(String token) {
    return repository.getMe(token);
  }
}
