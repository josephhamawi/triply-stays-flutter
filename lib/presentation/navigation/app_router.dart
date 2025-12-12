import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/biometric_service.dart';
import '../providers/auth/auth_provider.dart';
import '../providers/auth/auth_state.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/listing/listing_detail_screen.dart';
import '../screens/listing/add_listing_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/ai/ai_assistant_screen.dart';

/// App route paths
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String listing = '/listing/:id';
  static const String addListing = '/add-listing';
  static const String booking = '/booking/:id';
  static const String chat = '/chat/:conversationId';
  static const String notifications = '/notifications';
  static const String ai = '/ai';

  // Nested routes
  static const String settings = '/settings';
}

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  // Use read instead of watch to prevent router recreation on every state change
  // RouterRefreshStream handles refreshing when auth STATUS changes
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: RouterRefreshStream(ref),
    redirect: (context, state) {
      // Read current auth state inside redirect (called when RouterRefreshStream notifies)
      final authState = ref.read(authNotifierProvider);
      // Treat both authenticated and emailUnverified as "logged in"
      // Email verification is optional and only done via settings
      final isLoggedIn = authState.status == AuthStatus.authenticated ||
                         authState.status == AuthStatus.emailUnverified;
      final isGuest = authState.status == AuthStatus.guest;
      final isLoading = authState.status == AuthStatus.initial ||
                        authState.status == AuthStatus.loading;

      final currentPath = state.matchedLocation;

      // Auth routes that don't require authentication
      final authRoutes = [
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
      ];

      final isAuthRoute = authRoutes.contains(currentPath);
      final isSplashRoute = currentPath == AppRoutes.splash;

      // If still loading, stay on splash
      if (isLoading && !isSplashRoute) {
        return AppRoutes.splash;
      }

      // If not logged in and not guest, and trying to access protected route
      if (!isLoading && !isLoggedIn && !isGuest && !isAuthRoute) {
        return AppRoutes.signIn;
      }

      // If logged in or guest, redirect away from auth routes to home
      if ((isLoggedIn || isGuest) && (isAuthRoute || isSplashRoute)) {
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

      // Onboarding (shown to first-time users)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingScreen(
          onComplete: () => context.go(AppRoutes.signIn),
        ),
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
          onSuccess: () => context.go(AppRoutes.home),
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
          onBack: () async {
            // Set flag to prevent auto-biometric trigger on sign-in screen
            await BiometricService().setJustSignedOut(true);
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
            path: AppRoutes.ai,
            builder: (context, state) => const AIAssistantScreen(),
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

      // Edit profile screen
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Chat screen
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),

      // Notifications screen
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
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
