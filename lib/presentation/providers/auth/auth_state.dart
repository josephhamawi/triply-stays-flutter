import 'package:flutter/foundation.dart';

import '../../../domain/entities/user.dart';

/// Authentication status enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailUnverified,
  error,
}

/// Authentication state model
@immutable
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  /// Initial state
  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null,
        isLoading = false;

  /// Loading state
  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null,
        isLoading = true;

  /// Authenticated state
  AuthState.authenticated(User this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null,
        isLoading = false;

  /// Unauthenticated state
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null,
        isLoading = false;

  /// Email unverified state
  AuthState.emailUnverified(User this.user)
      : status = AuthStatus.emailUnverified,
        errorMessage = null,
        isLoading = false;

  /// Error state
  AuthState.error(String this.errorMessage, {this.user})
      : status = AuthStatus.error,
        isLoading = false;

  /// Check if user is authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Check if user needs email verification
  bool get needsEmailVerification => status == AuthStatus.emailUnverified;

  /// Copy with
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.errorMessage == errorMessage &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(status, user, errorMessage, isLoading);
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.email}, error: $errorMessage, isLoading: $isLoading)';
  }
}
