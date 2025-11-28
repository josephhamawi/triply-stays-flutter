import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth/auth_provider.dart';
import '../providers/auth/auth_state.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/listing/listing_detail_screen.dart';
import '../screens/listing/add_listing_screen.dart';
import '../screens/main/main_shell.dart';

/// App route paths
class AppRoutes {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String listing = '/listing/:id';
  static const String addListing = '/add-listing';
  static const String booking = '/booking/:id';
  static const String chat = '/chat/:conversationId';

  // Nested routes
  static const String settings = '/settings';
}

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final needsVerification = authState.status == AuthStatus.emailUnverified;
      final isLoading = authState.status == AuthStatus.initial ||
                        authState.status == AuthStatus.loading;

      final currentPath = state.matchedLocation;

      // Auth routes that don't require authentication
      final authRoutes = [
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
      ];

      final isAuthRoute = authRoutes.contains(currentPath);
      final isVerificationRoute = currentPath == AppRoutes.emailVerification;
      final isSplashRoute = currentPath == AppRoutes.splash;

      // If still loading, stay on splash
      if (isLoading && !isSplashRoute) {
        return AppRoutes.splash;
      }

      // If not logged in and trying to access protected route (including splash after loading)
      if (!isLoading && !isLoggedIn && !needsVerification && !isAuthRoute) {
        return AppRoutes.signIn;
      }

      // If logged in but needs verification
      if (needsVerification && !isVerificationRoute) {
        return AppRoutes.emailVerification;
      }

      // If logged in and verified, redirect away from auth routes
      if (isLoggedIn && (isAuthRoute || isVerificationRoute || isSplashRoute)) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => SignInScreen(
          onSignUpTap: () => context.go(AppRoutes.signUp),
          onForgotPasswordTap: () => context.go(AppRoutes.forgotPassword),
          onSuccess: () => context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => SignUpScreen(
          onSignInTap: () => context.go(AppRoutes.signIn),
          onSuccess: () => context.go(AppRoutes.emailVerification),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          onBackToSignIn: () => context.go(AppRoutes.signIn),
        ),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => EmailVerificationScreen(
          onVerified: () => context.go(AppRoutes.home),
          onBack: () {
            // Sign out and go back to sign in
            final container = ProviderScope.containerOf(context);
            container.read(authNotifierProvider.notifier).signOut();
            context.go(AppRoutes.signIn);
          },
        ),
      ),

      // Main app routes with shell (bottom navigation)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Listing detail (outside shell - no bottom nav)
      GoRoute(
        path: AppRoutes.listing,
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),

      // Add listing screen
      GoRoute(
        path: AppRoutes.addListing,
        builder: (context, state) => const AddListingScreen(),
      ),

      // Chat screen
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),

      // Booking screen (placeholder)
      GoRoute(
        path: AppRoutes.booking,
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Book Property'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Booking coming soon!',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

/// Listenable that notifies GoRouter when auth status changes
class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(this._ref) {
    _ref.listen(authNotifierProvider, (previous, next) {
      // Only notify when auth STATUS changes (login/logout/verification)
      // Don't notify when just user data changes (like profile update)
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}
