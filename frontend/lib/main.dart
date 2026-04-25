import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/main_screen.dart';
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
  @override
  void initState() {
    super.initState();
    // Initialize auth state only once on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider).initAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final authPage = ref.watch(authPageProvider);

    return MaterialApp(
      key: ValueKey(currentUser?.id ?? 'logged_out'),
      title: 'Assistia AI',
      debugShowCheckedModeBanner: false,
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
