import '../../repositories/auth/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<void> execute({required String oldPassword, required String newPassword}) {
    return repository.changePassword(oldPassword: oldPassword, newPassword: newPassword);
  }
}
