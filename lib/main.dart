import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/navigation/app_router.dart';

/// Global flag to track if Firebase initialized successfully
bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with timeout to prevent hanging on iOS betas
  firebaseInitialized = await _initializeFirebase();

  runApp(
    const ProviderScope(
      child: TriplyStaysApp(),
    ),
  );
}

Future<bool> _initializeFirebase() async {
  try {
    // Race Firebase init against a timeout
    final result = await Future.any([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .then((_) => true),
      Future.delayed(const Duration(seconds: 10), () => false),
    ]);

    if (result == true) {
      debugPrint('Firebase initialized successfully');
      return true;
    } else {
      debugPrint('Firebase initialization timed out');
      return false;
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    return false;
  }
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
