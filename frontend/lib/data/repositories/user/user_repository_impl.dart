import '../../../domain/entities/user/user.dart';
import '../../../domain/repositories/user/user_repository.dart';
import '../../datasources/user/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> getMe(String token) {
    return remoteDataSource.getMe(token);
  }

  @override
  Future<User> updateMe({String? name, String? username, String? email}) {
    return remoteDataSource.updateMe(name: name, username: username, email: email);
  }
}
