import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user/user.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/get_me_usecase.dart';
import '../../data/datasources/auth/auth_remote_data_source.dart';
import '../../data/repositories/auth/auth_repository_impl.dart';

// --- Dependecy Injection via Riverpod ---

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final authRemoteDataSourceProvider = FutureProvider<AuthRemoteDataSource>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final client = ref.watch(httpClientProvider);
  return AuthRemoteDataSource(client: client, sharedPreferences: prefs);
});

final authRepositoryProvider = FutureProvider<AuthRepositoryImpl>((ref) async {
  final remoteDataSource = await ref.watch(authRemoteDataSourceProvider.future);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

final loginUseCaseProvider = FutureProvider<LoginUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return LoginUseCase(repository);
});

final registerUseCaseProvider = FutureProvider<RegisterUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return RegisterUseCase(repository);
});

final logoutUseCaseProvider = FutureProvider<LogoutUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return LogoutUseCase(repository);
});

final getMeUseCaseProvider = FutureProvider<GetMeUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return GetMeUseCase(repository);
});


// --- State Management ---

class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) {
    state = val;
  }
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(() {
  return AuthLoadingNotifier();
});

class CurrentUserNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User user) {
    state = user;
  }

  void _clearState() {
    state = null;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, User?>(() {
  return CurrentUserNotifier();
});

class AuthController {
  final Ref ref;

  AuthController(this.ref);

  Future<void> login(String email, String password) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final loginUseCase = await ref.read(loginUseCaseProvider.future);
      final user = await loginUseCase.execute(email: email, password: password);
      ref.read(currentUserProvider.notifier).setUser(user);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final registerUseCase = await ref.read(registerUseCaseProvider.future);
      final user = await registerUseCase.execute(name: name, email: email, password: password);
      ref.read(currentUserProvider.notifier).setUser(user);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> logout() async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final logoutUseCase = await ref.read(logoutUseCaseProvider.future);
      await logoutUseCase.execute();
      ref.read(currentUserProvider.notifier)._clearState();
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> initAuth() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    final token = prefs.getString('access_token');
    
    if (token != null) {
      try {
        final getMeUseCase = await ref.read(getMeUseCaseProvider.future);
        final user = await getMeUseCase.execute(token);
        ref.read(currentUserProvider.notifier).setUser(user);
      } catch (e) {
        // If token is invalid or expired, logout
        await logout();
      }
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
