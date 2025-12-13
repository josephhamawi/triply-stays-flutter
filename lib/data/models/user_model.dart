import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/user.dart';
import '../../domain/entities/user_verifications.dart';

/// User model for data layer operations
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.firstName,
    super.lastName,
    super.photoUrl,
    super.emailVerified,
    super.phoneNumber,
    super.hasWhatsApp,
    super.createdAt,
    super.updatedAt,
    super.lastLoginAt,
    super.role,
    super.isHost,
    super.isHostProElite,
    super.onboardingCompleted,
    super.verifications,
  });

  /// Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: firebaseUser.metadata.creationTime,
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return UserModel(id: doc.id, email: '');
    }

    // Build displayName from firstName + lastName if not directly available
    String? displayName = data['displayName'] as String? ?? data['name'] as String?;
    final firstName = data['firstName'] as String?;
    final lastName = data['lastName'] as String?;
    if (displayName == null && (firstName != null || lastName != null)) {
      displayName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }

    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      photoUrl: data['photoUrl'] as String? ?? data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      phoneNumber: data['phoneNumber'] as String? ?? data['phone'] as String?,
      hasWhatsApp: data['hasWhatsApp'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      role: _parseRole(data['role'] as String?),
      isHost: data['isHost'] as bool? ?? false,
      isHostProElite: data['isHostProElite'] as bool? ?? false,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      verifications: UserVerifications.fromMap(data['verifications'] as Map<String, dynamic>?),
    );
  }

  /// Create UserModel from map (for JSON)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Build displayName from firstName + lastName if not directly available
    String? displayName = map['displayName'] as String? ?? map['name'] as String?;
    final firstName = map['firstName'] as String?;
    final lastName = map['lastName'] as String?;
    if (displayName == null && (firstName != null || lastName != null)) {
      displayName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }

    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      photoUrl: map['photoUrl'] as String? ?? map['photoURL'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      phoneNumber: map['phoneNumber'] as String? ?? map['phone'] as String?,
      hasWhatsApp: map['hasWhatsApp'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
      role: _parseRole(map['role'] as String?),
      isHost: map['isHost'] as bool? ?? false,
      isHostProElite: map['isHostProElite'] as bool? ?? false,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      verifications: UserVerifications.fromMap(map['verifications'] as Map<String, dynamic>?),
    );
  }

  /// Convert to Firestore map
  /// Includes 'name' field for web app compatibility (web saves full name separately)
  Map<String, dynamic> toFirestore() {
    // Build full name for web app compatibility
    String? fullName;
    if (firstName != null || lastName != null) {
      fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    } else {
      fullName = displayName;
    }

    return {
      'email': email,
      'displayName': displayName,
      'name': fullName, // Web app compatibility - stores full name separately
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'photoURL': photoUrl, // Web app compatibility - uses photoURL
      'emailVerified': emailVerified,
      'phone': phoneNumber,
      'hasWhatsApp': hasWhatsApp,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'role': role.name,
      'isHost': isHost,
      'isHostProElite': isHostProElite,
      'onboardingCompleted': onboardingCompleted,
      'verifications': verifications.toMap(),
    };
  }

  /// Convert to map (for JSON)
  Map<String, dynamic> toMap() {
    // Build full name for consistency
    String? fullName;
    if (firstName != null || lastName != null) {
      fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    } else {
      fullName = displayName;
    }

    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'name': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'phone': phoneNumber,
      'hasWhatsApp': hasWhatsApp,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'role': role.name,
      'isHost': isHost,
      'isHostProElite': isHostProElite,
      'onboardingCompleted': onboardingCompleted,
      'verifications': verifications.toMap(),
    };
  }

  /// Merge Firebase Auth user with Firestore data
  UserModel mergeWithFirestore(Map<String, dynamic>? firestoreData) {
    if (firestoreData == null) return this;

    // Build displayName from firstName + lastName if not directly available
    String? mergedDisplayName = displayName ?? firestoreData['displayName'] as String? ?? firestoreData['name'] as String?;
    final fsFirstName = firestoreData['firstName'] as String?;
    final fsLastName = firestoreData['lastName'] as String?;
    if (mergedDisplayName == null && (fsFirstName != null || fsLastName != null)) {
      mergedDisplayName = '${fsFirstName ?? ''} ${fsLastName ?? ''}'.trim();
    }

    // Firestore phone field takes priority over Firebase Auth phoneNumber
    // because Firestore is where we store user-entered phone numbers
    final firestorePhone = firestoreData['phone'] as String? ?? firestoreData['phoneNumber'] as String?;

    return UserModel(
      id: id,
      email: email,
      displayName: mergedDisplayName,
      firstName: fsFirstName,
      lastName: fsLastName,
      photoUrl: photoUrl ?? firestoreData['photoUrl'] as String? ?? firestoreData['photoURL'] as String?,
      emailVerified: firestoreData['emailVerified'] as bool? ?? emailVerified,
      phoneNumber: firestorePhone ?? phoneNumber,
      hasWhatsApp: firestoreData['hasWhatsApp'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: _parseTimestamp(firestoreData['updatedAt']),
      lastLoginAt: lastLoginAt,
      role: _parseRole(firestoreData['role'] as String?),
      isHost: firestoreData['isHost'] as bool? ?? false,
      isHostProElite: firestoreData['isHostProElite'] as bool? ?? false,
      onboardingCompleted: firestoreData['onboardingCompleted'] as bool? ?? false,
      verifications: UserVerifications.fromMap(firestoreData['verifications'] as Map<String, dynamic>?),
    );
  }

  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      photoUrl: photoUrl,
      emailVerified: emailVerified,
      phoneNumber: phoneNumber,
      hasWhatsApp: hasWhatsApp,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      role: role,
      isHost: isHost,
      isHostProElite: isHostProElite,
      onboardingCompleted: onboardingCompleted,
      verifications: verifications,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static UserRole _parseRole(String? roleString) {
    if (roleString == null) return UserRole.guest;
    return UserRole.values.firstWhere(
      (role) => role.name == roleString,
      orElse: () => UserRole.guest,
    );
  }
}
