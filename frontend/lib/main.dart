import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main_screen.dart';
import 'presentation/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize auth state
    Future.microtask(() => ref.read(authControllerProvider).initAuth());

    final currentUser = ref.watch(currentUserProvider);

    return MaterialApp(
      title: 'Assistia AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: currentUser != null ? const MainScreen() : const LoginPage(),
    );
  }
}
