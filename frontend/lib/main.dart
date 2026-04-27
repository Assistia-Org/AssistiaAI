import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/main_screen.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/splash/login_success_splash.dart';
import 'presentation/providers/auth_provider.dart';

/// Background FCM handler — must be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Android 8+ için notification channel oluştur
  await _setupNotificationChannel();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _setupNotificationChannel() async {
  final messaging = FirebaseMessaging.instance;

  // Bildirim izni iste (iOS + Android 13+)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Android: arka plan bildirimlerin gösterileceği kanalı oluştur
  if (defaultTargetPlatform == TargetPlatform.android) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitializing = true;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Startup splash + auth init (minimum 3 saniye göster)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        ref.read(authControllerProvider).initAuth(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    });

    // 🔔 Uygulama AÇIKKEN gelen FCM push → SnackBar göster
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Bildirim';
      final body = message.notification?.body ?? '';
      debugPrint('✅ FCM foreground mesaj geldi: $title — $body');

      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final authPage = ref.watch(authPageProvider);
    final showLoginSplash = ref.watch(showLoginSplashProvider);

    final child = _buildChild(
      isInitializing: _isInitializing,
      showLoginSplash: showLoginSplash,
      currentUser: currentUser,
      authPage: authPage,
    );

    return MaterialApp(
      title: 'Assistia AI',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: child,
    );
  }

  Widget _buildChild({
    required bool isInitializing,
    required bool showLoginSplash,
    required dynamic currentUser,
    required AuthPageType authPage,
  }) {
    // 1. Startup splash (en az 3 saniye)
    if (isInitializing) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    // 2. Login başarı splash — kendi animasyonu bitince onDismiss çağrılır
    if (showLoginSplash && currentUser != null) {
      return _LoginSplashBridge(
        key: const ValueKey('login_splash'),
        userName: currentUser.displayName,
      );
    }

    // 3. Normal routing
    if (currentUser != null) {
      return const MainScreen(key: ValueKey('main'));
    }
    return authPage == AuthPageType.login
        ? const LoginPage(key: ValueKey('login'))
        : const RegisterPage(key: ValueKey('register'));
  }
}

/// Login splash'ın onDismiss callback'ini Riverpod ile bağlayan köprü.
class _LoginSplashBridge extends ConsumerWidget {
  final String? userName;
  const _LoginSplashBridge({super.key, this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LoginSuccessSplash(
      userName: userName,
      onDismiss: () {
        ref.read(showLoginSplashProvider.notifier).hide();
      },
    );
  }
}
