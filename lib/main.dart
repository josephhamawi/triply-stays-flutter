import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // TODO: Initialize Hive for local storage
  // await Hive.initFlutter();

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
    // TODO: Use GoRouter when navigation is set up
    // final router = ref.watch(routerProvider);

    return MaterialApp(
      title: 'Triply Stays',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      // TODO: Replace with GoRouter
      // routerConfig: router,
    );
  }
}
