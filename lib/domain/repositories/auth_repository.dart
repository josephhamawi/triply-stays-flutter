import '../entities/user.dart';

/// Result type for authentication operations
class AuthResult<T> {
  final T? data;
  final AuthFailure? failure;

  const AuthResult._({this.data, this.failure});

  factory AuthResult.success(T data) => AuthResult._(data: data);
  factory AuthResult.failure(AuthFailure failure) =>
      AuthResult._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AuthFailure failure) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(data as T);
    }
    return onFailure(failure!);
  }
}

/// Authentication failure types
class AuthFailure {
  final String message;
  final String? code;
  final dynamic originalError;

  const AuthFailure({
    required this.message,
    this.code,
    this.originalError,
  });

  // Common auth failures
  static const AuthFailure invalidEmail = AuthFailure(
    message: 'The email address is invalid.',
    code: 'invalid-email',
  );

  static const AuthFailure userDisabled = AuthFailure(
    message: 'This account has been disabled.',
    code: 'user-disabled',
  );

  static const AuthFailure userNotFound = AuthFailure(
    message: 'No account found with this email.',
    code: 'user-not-found',
  );

  static const AuthFailure wrongPassword = AuthFailure(
    message: 'Incorrect password. Please try again.',
    code: 'wrong-password',
  );

  static const AuthFailure emailAlreadyInUse = AuthFailure(
    message: 'An account already exists with this email.',
    code: 'email-already-in-use',
  );

  static const AuthFailure weakPassword = AuthFailure(
    message: 'Password is too weak. Use at least 8 characters.',
    code: 'weak-password',
  );

  static const AuthFailure operationNotAllowed = AuthFailure(
    message: 'This operation is not allowed.',
    code: 'operation-not-allowed',
  );

  static const AuthFailure tooManyRequests = AuthFailure(
    message: 'Too many attempts. Please try again later.',
    code: 'too-many-requests',
  );

  static const AuthFailure networkError = AuthFailure(
    message: 'Network error. Please check your connection.',
    code: 'network-error',
  );

  static const AuthFailure unknown = AuthFailure(
    message: 'An unexpected error occurred.',
    code: 'unknown',
  );

  static const AuthFailure invalidVerificationCode = AuthFailure(
    message: 'Invalid verification code. Please try again.',
    code: 'invalid-verification-code',
  );

  static const AuthFailure verificationCodeExpired = AuthFailure(
    message: 'Verification code has expired. Please request a new one.',
    code: 'verification-code-expired',
  );

  @override
  String toString() => 'AuthFailure(code: $code, message: $message)';
}

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Get the current authenticated user
  User? get currentUser;

  /// Sign in with email and password
  Future<AuthResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create a new account with email and password
  Future<AuthResult<User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google
  Future<AuthResult<User>> signInWithGoogle();

  /// Sign in with Apple
  Future<AuthResult<User>> signInWithApple();

  /// Sign out the current user
  Future<AuthResult<void>> signOut();

  /// Send email verification code
  Future<AuthResult<void>> sendEmailVerificationCode(String email);

  /// Verify email with code
  Future<AuthResult<void>> verifyEmailCode({
    required String email,
    required String code,
  });

  /// Send password reset email
  Future<AuthResult<void>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<AuthResult<User>> updateProfile({
    String? displayName,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
    bool? hasWhatsApp,
  });

  /// Reload the current user data
  Future<AuthResult<User>> reloadUser();

  /// Check if email is verified in Firestore
  Future<bool> isEmailVerified(String userId);

  /// Update user password (requires reauthentication)
  Future<AuthResult<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Get the sign-in provider for the current user
  String? get signInProvider;
}
