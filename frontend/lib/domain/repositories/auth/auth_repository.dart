import '../../entities/user/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({required String name, required String email, required String password, required String verificationCode});
  Future<void> logout();
  Future<User> getMe(String token);
  Future<void> forgotPassword(String email);
  Future<void> changePassword({required String oldPassword, required String newPassword});
  Future<void> requestVerification(String email);
  Future<void> verifyCode({required String email, required String code});
}
