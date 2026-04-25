import '../../../domain/entities/user/user.dart';
import '../../../domain/repositories/auth/auth_repository.dart';
import '../../datasources/auth/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> login({required String email, required String password}) {
    return remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<User> register({required String name, required String email, required String password, required String verificationCode}) {
    return remoteDataSource.register(name: name, email: email, password: password, verificationCode: verificationCode);
  }
  
  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }

  @override
  Future<User> getMe(String token) {
    return remoteDataSource.getMe(token);
  }

  @override
  Future<void> forgotPassword(String email) {
    return remoteDataSource.forgotPassword(email);
  }

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) {
    return remoteDataSource.changePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  @override
  Future<void> requestVerification(String email) {
    return remoteDataSource.requestVerification(email);
  }

  @override
  Future<void> verifyCode({required String email, required String code}) {
    return remoteDataSource.verifyCode(email, code);
  }
}
