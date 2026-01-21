import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_verifications.dart';
import '../../../main.dart' show firebaseInitialized;

/// State for verification operations
class VerificationState {
  final bool isLoading;
  final String? errorMessage;
  final String? phoneVerificationId;
  final int? phoneResendToken;

  const VerificationState({
    this.isLoading = false,
    this.errorMessage,
    this.phoneVerificationId,
    this.phoneResendToken,
  });

  VerificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? phoneVerificationId,
    int? phoneResendToken,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      phoneVerificationId: phoneVerificationId ?? this.phoneVerificationId,
      phoneResendToken: phoneResendToken ?? this.phoneResendToken,
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

  /// Send phone verification code using Firebase Phone Auth
  Future<bool> sendPhoneVerificationCode(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'User not authenticated',
      );
      return false;
    }

    final completer = Completer<bool>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone.trim(),
        forceResendingToken: state.phoneResendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only) - automatically verify
          try {
            await _verifyWithCredential(credential, phone);
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              state = state.copyWith(
                isLoading: false,
                errorMessage: 'Auto-verification failed: ${e.toString()}',
              );
              completer.complete(false);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format. Please check and try again.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              errorMessage = e.message ?? 'Failed to send verification code';
          }
          state = state.copyWith(
            isLoading: false,
            errorMessage: errorMessage,
          );
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Code sent successfully - store verification ID for later use
          state = state.copyWith(
            isLoading: false,
            phoneVerificationId: verificationId,
            phoneResendToken: resendToken,
          );

          // Update user's phone number in Firestore
          try {
            await _firestore.collection('users').doc(user.uid).update({
              'phone': phone.trim(),
            });
          } catch (e) {
            // Don't fail if Firestore update fails
          }

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout - user must enter code manually
          state = state.copyWith(
            phoneVerificationId: verificationId,
          );
        },
      );

      return await completer.future;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Verify phone code using Firebase Phone Auth
  Future<bool> verifyPhoneCode(String phone, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final verificationId = state.phoneVerificationId;
    if (verificationId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please request a verification code first',
      );
      return false;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code.trim(),
      );

      return await _verifyWithCredential(credential, phone);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid code. Please check and try again.';
          break;
        case 'session-expired':
          errorMessage = 'Code expired. Please request a new code.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
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

  /// Helper to verify phone credential and update Firestore
  Future<bool> _verifyWithCredential(PhoneAuthCredential credential, String phone) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'User not authenticated',
      );
      return false;
    }

    try {
      // Link the phone credential to the current user
      // This verifies the phone number belongs to this user
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Phone already linked to another account - but we can still verify it
        // Just update Firestore without linking
      } else if (e.code == 'provider-already-linked') {
        // Phone already linked to this account - that's fine, just verify
      } else {
        // Handle other Firebase auth errors gracefully
        String errorMessage;
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Invalid code. Please check and try again.';
            break;
          case 'session-expired':
            errorMessage = 'Code expired. Please request a new code.';
            break;
          case 'invalid-verification-id':
            errorMessage = 'Verification session expired. Please request a new code.';
            break;
          default:
            errorMessage = e.message ?? 'Verification failed. Please try again.';
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
        );
        return false;
      }
    } catch (e) {
      // Handle any other unexpected errors
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed. Please try again.',
      );
      return false;
    }

    // Update user's verifications in Firestore
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'phone': phone.trim(),
        'verifications.phone': {
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save verification. Please try again.',
      );
      return false;
    }

    // Clear the verification state
    state = state.copyWith(
      isLoading: false,
      phoneVerificationId: null,
      phoneResendToken: null,
    );

    return true;
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
      // Path matches web app storage rules: identity-verifications/{userId}/{fileName}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = documentFile.path.split('.').last;
      final storagePath = 'identity-verifications/${user.uid}/$timestamp.$extension';

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
  if (!firebaseInitialized) {
    return _NoOpVerificationNotifier();
  }
  return VerificationNotifier();
});

/// No-op verification notifier for when Firebase isn't available
class _NoOpVerificationNotifier extends StateNotifier<VerificationState> implements VerificationNotifier {
  _NoOpVerificationNotifier() : super(const VerificationState());

  @override
  FirebaseAuth get _auth => throw UnimplementedError();
  @override
  FirebaseFirestore get _firestore => throw UnimplementedError();
  @override
  FirebaseFunctions get _functions => throw UnimplementedError();
  @override
  FirebaseStorage get _storage => throw UnimplementedError();

  @override
  Future<bool> sendEmailVerificationCode(String email) async {
    state = state.copyWith(errorMessage: 'Verification unavailable on iOS beta');
    return false;
  }

  @override
  Future<bool> verifyEmailCode(String email, String code) async {
    state = state.copyWith(errorMessage: 'Verification unavailable on iOS beta');
    return false;
  }

  @override
  Future<bool> sendPhoneVerificationCode(String phone) async {
    state = state.copyWith(errorMessage: 'Verification unavailable on iOS beta');
    return false;
  }

  @override
  Future<bool> verifyPhoneCode(String phone, String code) async {
    state = state.copyWith(errorMessage: 'Verification unavailable on iOS beta');
    return false;
  }

  @override
  Future<bool> _verifyWithCredential(PhoneAuthCredential credential, String phone) async => false;

  @override
  Future<bool> submitIdentityVerification(String documentType, File documentFile) async {
    state = state.copyWith(errorMessage: 'Verification unavailable on iOS beta');
    return false;
  }

  @override
  Future<UserVerifications?> getUserVerifications() async => null;

  @override
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for user verifications stream
final userVerificationsStreamProvider = StreamProvider<UserVerifications?>((ref) {
  // Check if Firebase is available
  if (!firebaseInitialized) {
    return Stream.value(null);
  }

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
