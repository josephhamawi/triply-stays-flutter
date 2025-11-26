import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Provider for auth state changes stream
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull;
});

/// Auth notifier for managing authentication state and actions
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthNotifier(this._authRepository) : super(const AuthState.initial()) {
    _init();
  }

  void _init() {
    state = const AuthState.loading();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error) {
        state = AuthState.error(error.toString());
      },
    );
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      state = const AuthState.unauthenticated();
    } else if (!user.emailVerified) {
      state = AuthState.emailUnverified(user);
    } else {
      state = AuthState.authenticated(user);
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    result.fold(
      onSuccess: (user) {
        if (!user.emailVerified) {
          state = AuthState.emailUnverified(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
      onFailure: (failure) {
        state = AuthState.error(failure.message, user: state.user);
      },
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );

    result.fold(
      onSuccess: (user) {
        state = AuthState.emailUnverified(user);
      },
      onFailure: (failure) {
        state = AuthState.error(failure.message);
      },
    );
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.signInWithGoogle();

    result.fold(
      onSuccess: (user) {
        if (!user.emailVerified) {
          state = AuthState.emailUnverified(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
      onFailure: (failure) {
        state = AuthState.error(failure.message);
      },
    );
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.signInWithApple();

    result.fold(
      onSuccess: (user) {
        if (!user.emailVerified) {
          state = AuthState.emailUnverified(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
      onFailure: (failure) {
        state = AuthState.error(failure.message);
      },
    );
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.signOut();

    result.fold(
      onSuccess: (_) {
        state = const AuthState.unauthenticated();
      },
      onFailure: (failure) {
        state = AuthState.error(failure.message, user: state.user);
      },
    );
  }

  /// Send email verification code
  Future<bool> sendEmailVerificationCode() async {
    final email = state.user?.email;
    if (email == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.sendEmailVerificationCode(email);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  /// Verify email code
  Future<bool> verifyEmailCode(String code) async {
    final email = state.user?.email;
    if (email == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.verifyEmailCode(
      email: email,
      code: code,
    );

    return result.fold(
      onSuccess: (_) async {
        // Reload user to get updated verification status
        final reloadResult = await _authRepository.reloadUser();
        reloadResult.fold(
          onSuccess: (user) {
            state = AuthState.authenticated(user);
          },
          onFailure: (failure) {
            // Even if reload fails, verification succeeded
            if (state.user != null) {
              state = AuthState.authenticated(
                state.user!.copyWith(emailVerified: true),
              );
            }
          },
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.sendPasswordResetEmail(email);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reload user data
  Future<void> reloadUser() async {
    final result = await _authRepository.reloadUser();
    result.fold(
      onSuccess: (user) {
        if (!user.emailVerified) {
          state = AuthState.emailUnverified(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
      onFailure: (failure) {
        // Keep current state on reload failure
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

/// Helper providers for common auth state checks
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final needsEmailVerificationProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).needsEmailVerification;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).errorMessage;
});
