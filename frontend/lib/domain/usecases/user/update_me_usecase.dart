import '../../entities/user/user.dart';
import '../../repositories/user/user_repository.dart';

class UpdateMeUseCase {
  final UserRepository repository;

  UpdateMeUseCase(this.repository);

  Future<User> execute({String? name, String? username, String? email}) {
    return repository.updateMe(name: name, username: username, email: email);
  }
}
