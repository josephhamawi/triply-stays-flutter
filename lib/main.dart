import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with timeout - don't block app startup
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Firebase initialization timed out');
        throw Exception('Firebase timeout');
      },
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase - app will handle this gracefully
  }

  runApp(
    const ProviderScope(
      child: TriplyStaysApp(),
    ),
  );
}

class TriplyStaysApp extends ConsumerWidget {
  const TriplyStaysApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Triply Stays',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
