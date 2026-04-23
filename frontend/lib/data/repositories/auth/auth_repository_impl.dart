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
  Future<User> register({required String name, required String email, required String password}) {
    return remoteDataSource.register(name: name, email: email, password: password);
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
}
