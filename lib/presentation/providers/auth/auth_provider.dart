import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../main.dart' show firebaseInitialized;
import 'auth_state.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!firebaseInitialized) {
    return _NoOpAuthRepository();
  }
  return FirebaseAuthRepository();
});

/// No-op auth repository for when Firebase isn't available
/// This is used when Firebase fails to initialize (e.g., iOS beta compatibility issues)
class _NoOpAuthRepository implements AuthRepository {
  // Return a stream that emits null once - this signals unauthenticated state
  // The UI should handle this gracefully and show appropriate messaging
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  String? get signInProvider => null;

  @override
  Future<AuthResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta. Please update to stable iOS.'));

  @override
  Future<AuthResult<User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async => AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta. Please update to stable iOS.'));

  @override
  Future<AuthResult<User>> signInWithGoogle() async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta. Please update to stable iOS.'));

  @override
  Future<AuthResult<User>> signInWithApple() async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta. Please update to stable iOS.'));

  @override
  Future<AuthResult<void>> signOut() async => AuthResult.success(null);

  @override
  Future<AuthResult<void>> deleteAccount() async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<AuthResult<void>> sendPasswordResetEmail(String email) async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<AuthResult<void>> sendEmailVerificationCode(String email) async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<AuthResult<void>> verifyEmailCode({required String email, required String code}) async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<AuthResult<User>> reloadUser() async =>
      AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<AuthResult<User>> updateProfile({
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    bool? hasWhatsApp,
    String? photoUrl,
  }) async => AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<AuthResult<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async => AuthResult.failure(const AuthFailure(message: 'Firebase unavailable on iOS beta.'));

  @override
  Future<bool> isEmailVerified(String userId) async => false;
}

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

  /// Continue as guest (browse-only mode)
  void continueAsGuest() {
    state = const AuthState.guest();
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.deleteAccount();

    return result.fold(
      onSuccess: (_) {
        state = const AuthState.unauthenticated();
        return true;
      },
      onFailure: (failure) {
        state = AuthState.error(failure.message, user: state.user);
        return false;
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
    if (email == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to send verification code. Please sign in again.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.sendEmailVerificationCode(email);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (failure) {
        // Provide user-friendly error messages
        String errorMessage = failure.message;
        if (failure.message.contains('not configured')) {
          errorMessage = 'Email service is temporarily unavailable. Please try again later.';
        } else if (failure.message.contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }
        state = state.copyWith(isLoading: false, errorMessage: errorMessage);
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

  /// Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

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

  /// Get sign-in provider
  String? get signInProvider => _authRepository.signInProvider;

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

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    bool? hasWhatsApp,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      hasWhatsApp: hasWhatsApp,
      photoUrl: photoUrl,
    );

    return result.fold(
      onSuccess: (user) {
        state = AuthState.authenticated(user);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
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

final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isGuest;
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
