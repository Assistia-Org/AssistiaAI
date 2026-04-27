import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/main_screen.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/splash/login_success_splash.dart';
import 'presentation/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // initAuth + en az 3 saniye → ikisi de bitince startup splash kapanır
      await Future.wait([
        ref.read(authControllerProvider).initAuth(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      if (mounted) {
        setState(() => _isInitializing = false);
      }
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
