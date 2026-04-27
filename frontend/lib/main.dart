import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/main_screen.dart';
import 'presentation/providers/auth_provider.dart';

/// Background FCM handler — must be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized here too for background isolate
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
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Initialize auth state only once on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider).initAuth();
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
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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

    return MaterialApp(
      title: 'Assistia AI',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: currentUser != null
          ? const MainScreen()
          : (authPage == AuthPageType.login ? const LoginPage() : const RegisterPage()),
    );
  }
}
