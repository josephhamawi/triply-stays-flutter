import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_verifications.dart';

/// State for verification operations
class VerificationState {
  final bool isLoading;
  final String? errorMessage;

  const VerificationState({
    this.isLoading = false,
    this.errorMessage,
  });

  VerificationState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for verification operations
class VerificationNotifier extends StateNotifier<VerificationState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  VerificationNotifier({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _storage = storage ?? FirebaseStorage.instance,
        super(const VerificationState());

  /// Send email verification code
  Future<bool> sendEmailVerificationCode(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final callable = _functions.httpsCallable('sendEmailVerification');
      await callable.call({'email': email.trim()});

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Failed to send verification code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Verify email code
  Future<bool> verifyEmailCode(String email, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final callable = _functions.httpsCallable('verifyEmailCode');
      final result = await callable.call({
        'email': email.trim(),
        'code': code.trim(),
      });

      final success = result.data['success'] as bool? ?? false;
      if (!success) {
        final message = result.data['message'] as String? ?? 'Verification failed';
        state = state.copyWith(isLoading: false, errorMessage: message);
        return false;
      }

      // Update user's verifications in Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'verifications.email': {
            'verified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          },
          'emailVerified': true,
        });
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Verification failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Send phone verification code
  Future<bool> sendPhoneVerificationCode(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return false;
      }

      final callable = _functions.httpsCallable('sendPhoneVerification');
      await callable.call({
        'phone': phone.trim(),
        'userId': user.uid,
      });

      // Also update the user's phone number in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'phone': phone.trim(),
      });

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Failed to send verification code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Verify phone code
  Future<bool> verifyPhoneCode(String phone, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return false;
      }

      final callable = _functions.httpsCallable('verifyPhoneCode');
      final result = await callable.call({
        'phone': phone.trim(),
        'code': code.trim(),
        'userId': user.uid,
      });

      final success = result.data['success'] as bool? ?? false;
      if (!success) {
        final message = result.data['message'] as String? ?? 'Verification failed';
        state = state.copyWith(isLoading: false, errorMessage: message);
        return false;
      }

      // Update user's verifications in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'verifications.phone': {
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        },
      });

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Verification failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Submit identity verification
  Future<bool> submitIdentityVerification(String documentType, File documentFile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return false;
      }

      // Upload document to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = documentFile.path.split('.').last;
      final storagePath = 'identity_documents/${user.uid}/$timestamp.$extension';

      final ref = _storage.ref().child(storagePath);
      await ref.putFile(documentFile);
      final downloadUrl = await ref.getDownloadURL();

      // Update user's verifications in Firestore with pending status
      await _firestore.collection('users').doc(user.uid).update({
        'verifications.identity': {
          'verified': false,
          'status': 'pending',
          'documentType': documentType,
          'documentUrl': downloadUrl,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });

      // Optionally notify admin about new verification request
      try {
        final callable = _functions.httpsCallable('notifyIdentityVerification');
        await callable.call({
          'userId': user.uid,
          'documentType': documentType,
          'documentUrl': downloadUrl,
        });
      } catch (e) {
        // Don't fail if notification fails
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Failed to upload document',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Get current user's verifications
  Future<UserVerifications?> getUserVerifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return UserVerifications.fromMap(
        data['verifications'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for verification notifier
final verificationNotifierProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});

/// Provider for user verifications stream
final userVerificationsStreamProvider = StreamProvider<UserVerifications?>((ref) {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final user = auth.currentUser;
  if (user == null) {
    return Stream.value(null);
  }

  return firestore.collection('users').doc(user.uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return UserVerifications.fromMap(
      data['verifications'] as Map<String, dynamic>?,
    );
  });
});
