import '../../entities/user/user.dart';
import '../../entities/user/user_settings.dart';

abstract class UserRepository {
  Future<User> getMe(String token);
  Future<User> updateMe({String? name, String? username, String? email});
  Future<User> updateSettings(UserSettings settings);
}
