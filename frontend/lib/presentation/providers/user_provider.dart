import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/user/get_me_usecase.dart';
import '../../domain/usecases/user/update_me_usecase.dart';
import '../../data/datasources/user/user_remote_data_source.dart';
import '../../data/repositories/user/user_repository_impl.dart';
import 'auth_provider.dart';

final userRemoteDataSourceProvider = FutureProvider<UserRemoteDataSource>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final client = ref.watch(httpClientProvider);
  return UserRemoteDataSource(client: client, sharedPreferences: prefs);
});

final userRepositoryProvider = FutureProvider<UserRepositoryImpl>((ref) async {
  final remoteDataSource = await ref.watch(userRemoteDataSourceProvider.future);
  return UserRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getMeUseCaseProvider = FutureProvider<GetMeUseCase>((ref) async {
  final repository = await ref.watch(userRepositoryProvider.future);
  return GetMeUseCase(repository);
});

final updateMeUseCaseProvider = FutureProvider<UpdateMeUseCase>((ref) async {
  final repository = await ref.watch(userRepositoryProvider.future);
  return UpdateMeUseCase(repository);
});

class UserController {
  final Ref ref;

  UserController(this.ref);

  Future<void> updateProfile({String? name, String? username, String? email}) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final updateMeUseCase = await ref.read(updateMeUseCaseProvider.future);
      final user = await updateMeUseCase.execute(name: name, username: username, email: email);
      ref.read(currentUserProvider.notifier).setUser(user);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }
}

final userControllerProvider = Provider<UserController>((ref) {
  return UserController(ref);
});
