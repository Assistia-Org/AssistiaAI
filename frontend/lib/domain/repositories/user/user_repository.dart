import '../../entities/user/user.dart';

abstract class UserRepository {
  Future<User> getMe(String token);
  Future<User> updateMe({String? name, String? username, String? email});
}
