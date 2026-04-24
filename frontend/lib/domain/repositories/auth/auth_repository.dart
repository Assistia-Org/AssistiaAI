import '../../entities/user/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({required String name, required String email, required String password, required String verificationCode});
  Future<void> sendVerificationCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> logout();
  Future<User> getMe(String token);
  Future<void> forgotPassword(String email);
}
