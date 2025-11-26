import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing user sessions
class SessionService {
  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _lastLoginKey = 'last_login_timestamp';
  static const String _sessionTokenKey = 'session_token';

  SessionService({
    FirebaseAuth? firebaseAuth,
    FlutterSecureStorage? secureStorage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Check if user has a valid session
  bool get hasValidSession => _firebaseAuth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Listen to ID token changes (for token refresh)
  Stream<User?> get idTokenChanges => _firebaseAuth.idTokenChanges();

  /// Persist session data
  Future<void> persistSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      await _secureStorage.write(
        key: _lastLoginKey,
        value: DateTime.now().toIso8601String(),
      );

      // Get and store the ID token
      final token = await user.getIdToken();
      if (token != null) {
        await _secureStorage.write(
          key: _sessionTokenKey,
          value: token,
        );
      }
    } catch (e) {
      debugPrint('Error persisting session: $e');
    }
  }

  /// Clear session data on logout
  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _lastLoginKey);
      await _secureStorage.delete(key: _sessionTokenKey);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLoginTimestamp() async {
    try {
      final timestamp = await _secureStorage.read(key: _lastLoginKey);
      if (timestamp != null) {
        return DateTime.tryParse(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting last login: $e');
    }
    return null;
  }

  /// Force refresh the user's ID token
  Future<String?> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken(true);
      if (token != null) {
        await _secureStorage.write(
          key: _sessionTokenKey,
          value: token,
        );
      }
      return token;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  /// Check if session is expired (optional custom logic)
  Future<bool> isSessionExpired({Duration maxAge = const Duration(days: 30)}) async {
    final lastLogin = await getLastLoginTimestamp();
    if (lastLogin == null) return true;

    return DateTime.now().difference(lastLogin) > maxAge;
  }

  /// Re-authenticate user (for sensitive operations)
  Future<bool> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Reauthentication failed: $e');
      return false;
    }
  }

  /// Sign out and clear all session data
  Future<void> signOut() async {
    await clearSession();
    await _firebaseAuth.signOut();
  }
}
