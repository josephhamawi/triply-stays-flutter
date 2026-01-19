import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/auth_state.dart';
import '../onboarding/onboarding_screen.dart';

/// Splash screen shown on app launch
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigationHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Check onboarding and auth after animation
    Future.delayed(const Duration(milliseconds: 1500), _checkNavigationTarget);

    // Absolute safety timeout - force navigation after 5 seconds no matter what
    Future.delayed(const Duration(seconds: 5), _forceNavigate);
  }

  void _forceNavigate() {
    if (!mounted || _navigationHandled) return;
    debugPrint('Force navigating due to timeout');
    _navigationHandled = true;
    context.go(AppRoutes.onboarding);
  }

  Future<void> _checkNavigationTarget() async {
    if (!mounted || _navigationHandled) return;

    try {
      // Try to get auth state with timeout
      bool isLoggedIn = false;

      try {
        var authState = ref.read(authNotifierProvider);

        // If still loading, wait up to 2 seconds for auth to resolve
        if (authState.status == AuthStatus.initial || authState.isLoading) {
          for (int i = 0; i < 4; i++) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (!mounted) return;
            authState = ref.read(authNotifierProvider);
            if (authState.status != AuthStatus.initial && !authState.isLoading) {
              break;
            }
          }
        }

        // Treat both authenticated and emailUnverified as logged in
        isLoggedIn = authState.status == AuthStatus.authenticated ||
                     authState.status == AuthStatus.emailUnverified;
      } catch (e) {
        // Firebase/auth failed - treat as not logged in
        debugPrint('Auth check failed: $e');
        isLoggedIn = false;
      }

      if (!mounted || _navigationHandled) return;

      // If user is logged in, go to home
      if (isLoggedIn) {
        _navigationHandled = true;
        context.go(AppRoutes.home);
        return;
      }

      // Check if onboarding is complete
      bool hasCompletedOnboarding = false;
      try {
        hasCompletedOnboarding = await OnboardingScreen.hasCompletedOnboarding();
      } catch (e) {
        debugPrint('Onboarding check failed: $e');
        hasCompletedOnboarding = false;
      }

      if (!mounted || _navigationHandled) return;

      _navigationHandled = true;

      if (!hasCompletedOnboarding) {
        // First time user - show onboarding
        context.go(AppRoutes.onboarding);
      } else {
        // Returning user - go to sign in
        context.go(AppRoutes.signIn);
      }
    } catch (e) {
      // Safety fallback - go to onboarding if everything fails
      debugPrint('Navigation check failed completely: $e');
      if (!mounted || _navigationHandled) return;
      _navigationHandled = true;
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryOrange,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Fox Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/logo/fox-icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Triply Stays',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your perfect stay',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
