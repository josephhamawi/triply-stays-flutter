import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserWithFirestoreData(firebaseUser);
    });
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return UserModel.fromFirebaseUser(firebaseUser);
  }

  @override
  Future<AuthResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      final user = await _getUserWithFirestoreData(credential.user!);
      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      // Update display name
      await credential.user!.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(credential.user!, displayName);

      // Reload user to get updated data
      await credential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser == null) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      final user = await _getUserWithFirestoreData(updatedUser);
      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<User>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure(const AuthFailure(
          message: 'Google sign in was cancelled.',
          code: 'google-sign-in-cancelled',
        ));
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(
          userCredential.user!,
          googleUser.displayName ?? '',
          emailVerified: true, // Google accounts are pre-verified
        );
      }

      final user = await _getUserWithFirestoreData(userCredential.user!);
      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<User>> signInWithApple() async {
    try {
      // Check if running on iOS
      if (!Platform.isIOS) {
        return AuthResult.failure(const AuthFailure(
          message: 'Apple Sign In is only available on iOS.',
          code: 'apple-sign-in-unavailable',
        ));
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        return AuthResult.failure(AuthFailure.unknown);
      }

      // Apple only provides name on first sign in
      String? displayName;
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(displayName);
        }
      }

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(
          userCredential.user!,
          displayName ?? userCredential.user!.displayName ?? '',
          emailVerified: true, // Apple accounts are pre-verified
        );
      }

      final user = await _getUserWithFirestoreData(userCredential.user!);
      return AuthResult.success(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure(const AuthFailure(
          message: 'Apple sign in was cancelled.',
          code: 'apple-sign-in-cancelled',
        ));
      }
      return AuthResult.failure(AuthFailure(
        message: e.message,
        code: e.code.toString(),
        originalError: e,
      ));
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<void>> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _firebaseAuth.signOut();
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<void>> sendEmailVerificationCode(String email) async {
    try {
      final callable = _functions.httpsCallable('sendEmailVerification');
      await callable.call({'email': email.trim()});
      return AuthResult.success(null);
    } on FirebaseFunctionsException catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.message ?? 'Failed to send verification code.',
        code: e.code,
        originalError: e,
      ));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<void>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyEmailCode');
      final result = await callable.call({
        'email': email.trim(),
        'code': code.trim(),
      });

      final success = result.data['success'] as bool? ?? false;
      if (!success) {
        final message = result.data['message'] as String? ?? 'Verification failed.';
        if (message.toLowerCase().contains('expired')) {
          return AuthResult.failure(AuthFailure.verificationCodeExpired);
        }
        return AuthResult.failure(AuthFailure.invalidVerificationCode);
      }

      // Reload user to get updated verification status
      await _firebaseAuth.currentUser?.reload();

      return AuthResult.success(null);
    } on FirebaseFunctionsException catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.message ?? 'Verification failed.',
        code: e.code,
        originalError: e,
      ));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<User>> updateProfile({
    String? displayName,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
    bool? hasWhatsApp,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure(const AuthFailure(
          message: 'No user is signed in.',
          code: 'no-user',
        ));
      }

      // Build displayName from first/last name if not provided
      String? finalDisplayName = displayName;
      if (finalDisplayName == null && (firstName != null || lastName != null)) {
        finalDisplayName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      }

      if (finalDisplayName != null) {
        await user.updateDisplayName(finalDisplayName);
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore with all fields
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (finalDisplayName != null) updateData['displayName'] = finalDisplayName;
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (phoneNumber != null) updateData['phone'] = phoneNumber;
      if (hasWhatsApp != null) updateData['hasWhatsApp'] = hasWhatsApp;

      await _firestore.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      await user.reload();
      final updatedUser = await _getUserWithFirestoreData(_firebaseAuth.currentUser!);
      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<AuthResult<User>> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure(const AuthFailure(
          message: 'No user is signed in.',
          code: 'no-user',
        ));
      }

      await user.reload();
      final updatedUser = await _getUserWithFirestoreData(_firebaseAuth.currentUser!);
      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  Future<bool> isEmailVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['emailVerified'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthResult<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure(const AuthFailure(
          message: 'No user is signed in.',
          code: 'no-user',
        ));
      }

      if (user.email == null) {
        return AuthResult.failure(const AuthFailure(
          message: 'No email associated with this account.',
          code: 'no-email',
        ));
      }

      // Reauthenticate the user first
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Now update the password
      await user.updatePassword(newPassword);

      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return AuthResult.failure(AuthFailure(
        message: e.toString(),
        originalError: e,
      ));
    }
  }

  @override
  String? get signInProvider {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') return 'google';
      if (provider.providerId == 'apple.com') return 'apple';
      if (provider.providerId == 'password') return 'password';
    }
    return null;
  }

  // Private helper methods

  Future<User> _getUserWithFirestoreData(firebase_auth.User firebaseUser) async {
    final userModel = UserModel.fromFirebaseUser(firebaseUser);

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return userModel.mergeWithFirestore(doc.data());
      }
    } catch (e) {
      // If Firestore fetch fails, return basic user data
    }

    return userModel;
  }

  Future<void> _createUserDocument(
    firebase_auth.User user,
    String displayName, {
    bool emailVerified = false,
  }) async {
    // Parse displayName into firstName and lastName
    String? firstName;
    String? lastName;
    if (displayName.isNotEmpty) {
      final nameParts = displayName.trim().split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }
    }

    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      photoUrl: user.photoURL,
      emailVerified: emailVerified,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(
          userModel.toFirestore(),
          SetOptions(merge: true),
        );
  }

  AuthFailure _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthFailure.invalidEmail;
      case 'user-disabled':
        return AuthFailure.userDisabled;
      case 'user-not-found':
        return AuthFailure.userNotFound;
      case 'wrong-password':
        return AuthFailure.wrongPassword;
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse;
      case 'weak-password':
        return AuthFailure.weakPassword;
      case 'operation-not-allowed':
        return AuthFailure.operationNotAllowed;
      case 'too-many-requests':
        return AuthFailure.tooManyRequests;
      case 'network-request-failed':
        return AuthFailure.networkError;
      default:
        return AuthFailure(
          message: e.message ?? 'An error occurred.',
          code: e.code,
          originalError: e,
        );
    }
  }
}
