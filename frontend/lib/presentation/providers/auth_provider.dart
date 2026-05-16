import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user/user.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/get_me_usecase.dart';
import '../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../domain/usecases/auth/change_password_usecase.dart';
import '../../domain/usecases/auth/request_verification_usecase.dart';
import '../../domain/usecases/auth/verify_code_usecase.dart';
import '../../domain/usecases/auth/google_auth_usecase.dart';
import '../../data/datasources/auth/auth_remote_data_source.dart';
import '../../data/repositories/auth/auth_repository_impl.dart';
import '../../data/datasources/notification/notification_remote_datasource.dart';
import 'community_provider.dart';
import 'invitation_provider.dart';
import 'daily_program_provider.dart';
import 'notification_provider.dart';
import 'sse_provider.dart';

import '../../core/network/auth_client.dart';

// --- Dependecy Injection via Riverpod ---

enum AuthPageType { login, register }

class AuthPageNotifier extends Notifier<AuthPageType> {
  @override
  AuthPageType build() => AuthPageType.login;

  void setPage(AuthPageType type) {
    state = type;
  }
}

final authPageProvider = NotifierProvider<AuthPageNotifier, AuthPageType>(() {
  return AuthPageNotifier();
});

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final httpClientProvider = Provider<http.Client>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  
  // Return a dummy client if prefs aren't ready yet, 
  // but it will be updated once they are.
  return prefsAsync.when(
    data: (prefs) => AuthClient(
      http.Client(), 
      prefs,
      onLogout: () => ref.read(authControllerProvider).logout(),
    ),
    loading: () => http.Client(),
    error: (_, __) => http.Client(),
  );
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

final forgotPasswordUseCaseProvider = FutureProvider<ForgotPasswordUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return ForgotPasswordUseCase(repository);
});

final changePasswordUseCaseProvider = FutureProvider<ChangePasswordUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return ChangePasswordUseCase(repository);
});

final requestVerificationUseCaseProvider = FutureProvider<RequestVerificationUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return RequestVerificationUseCase(repository);
});

final verifyCodeUseCaseProvider = FutureProvider<VerifyCodeUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return VerifyCodeUseCase(repository);
});

final googleAuthUseCaseProvider = FutureProvider<GoogleAuthUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return GoogleAuthUseCase(repository);
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

// Login başarı splash ekranı için state
class ShowLoginSplashNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;
  void hide() => state = false;
}

final showLoginSplashProvider =
    NotifierProvider<ShowLoginSplashNotifier, bool>(() {
  return ShowLoginSplashNotifier();
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

      // Login başarı splash ekranını göster (3 saniye)
      ref.read(showLoginSplashProvider.notifier).show();

      // Connect SSE
      final prefs = await ref.read(sharedPrefsProvider.future);
      final token = prefs.getString('access_token');
      if (token != null) {
        ref.read(sseServiceProvider).connect(null);
        _registerFcmToken(prefs, ref.read(httpClientProvider));
      }
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password, String verificationCode) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final registerUseCase = await ref.read(registerUseCaseProvider.future);
      // Sadece kayıt yap, oturum açma — kullanıcı login sayfasından giriş yapacak
      await registerUseCase.execute(name: name, email: email, password: password, verificationCode: verificationCode);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> logout() async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final logoutUseCase = await ref.read(logoutUseCaseProvider.future);
      await logoutUseCase.execute();
      // Clear all cached user data
      ref.invalidate(myCommunitiesProvider);
      ref.invalidate(myInvitationsProvider);
      ref.invalidate(dailyProgramByDateProvider);
      ref.invalidate(notificationProvider);
      ref.read(currentUserProvider.notifier)._clearState();
      ref.read(authPageProvider.notifier).setPage(AuthPageType.login);
      ref.read(sseServiceProvider).disconnect();
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
        
        // Connect SSE on app launch
        ref.read(sseServiceProvider).connect(null);
        // Register FCM token with backend
        _registerFcmToken(prefs, ref.read(httpClientProvider));
      } catch (e) {
        // If token is invalid or expired, logout
        await logout();
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final forgotPasswordUseCase = await ref.read(forgotPasswordUseCaseProvider.future);
      await forgotPasswordUseCase.execute(email);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final changePasswordUseCase = await ref.read(changePasswordUseCaseProvider.future);
      await changePasswordUseCase.execute(oldPassword: oldPassword, newPassword: newPassword);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> requestVerification(String email) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(requestVerificationUseCaseProvider.future);
      await useCase.execute(email);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> verifyCode(String email, String code) async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      final useCase = await ref.read(verifyCodeUseCaseProvider.future);
      await useCase.execute(email: email, code: code);
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    ref.read(authLoadingProvider.notifier).setLoading(true);
    try {
      // 1. Google hesabı seç
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Kullanıcı iptal etti

      // 2. Firebase credential oluştur ve Firebase'e sign-in yap
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      // 3. Firebase ID Token al (kendi backend'imiz için)
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('Firebase ID token alınamadı.');

      // 4. FCM token al (opsiyonel)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessagingInstance._instance.getToken();
      } catch (_) {}

      // 5. Backend datasource üzerinden doğrudan googleAuth çağır (fcmToken ile)
      final prefs = await ref.read(sharedPrefsProvider.future);
      final client = ref.read(httpClientProvider);
      final ds = AuthRemoteDataSource(client: client, sharedPreferences: prefs);
      final user = await ds.googleAuth(idToken: idToken, fcmToken: fcmToken);

      ref.read(currentUserProvider.notifier).setUser(user);
      ref.read(showLoginSplashProvider.notifier).show();

      // SSE bağla
      final token = prefs.getString('access_token');
      if (token != null) {
        ref.read(sseServiceProvider).connect(null);
      }
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

/// Registers the FCM device token with the backend. Fire-and-forget.
void _registerFcmToken(SharedPreferences prefs, http.Client client) async {
  try {
    final accessToken = prefs.getString('access_token');
    if (accessToken == null) return;

    final messaging = FirebaseMessagingInstance._instance;
    final fcmToken = await messaging.getToken();

    // 🔍 Bu log'u Flutter konsolunda gör — token alındıysa FCM çalışıyor
    if (fcmToken == null) {
      debugPrint('❌ FCM: Token alınamadı (Google Play Services gerekli)');
      return;
    }
    debugPrint('✅ FCM Token alındı: $fcmToken');

    final ds = NotificationRemoteDataSource(
      client: client,
      sharedPreferences: prefs,
    );
    await ds.registerFcmToken(fcmToken);
    debugPrint('✅ FCM Token backend\'e kaydedildi');
  } catch (e) {
    debugPrint('❌ FCM Token hatası: $e');
  }
}

// Thin wrapper so we can import firebase_messaging only in one place
class FirebaseMessagingInstance {
  static final _instance = FirebaseMessaging.instance;
}

