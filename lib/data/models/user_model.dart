import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/user.dart';

/// User model for data layer operations
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.emailVerified,
    super.phoneNumber,
    super.createdAt,
    super.lastLoginAt,
    super.role,
    super.isHost,
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

    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? data['name'] as String?,
      photoUrl: data['photoUrl'] as String? ?? data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      role: _parseRole(data['role'] as String?),
      isHost: data['isHost'] as bool? ?? false,
    );
  }

  /// Create UserModel from map (for JSON)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? map['name'] as String?,
      photoUrl: map['photoUrl'] as String? ?? map['photoURL'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
      role: _parseRole(map['role'] as String?),
      isHost: map['isHost'] as bool? ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'role': role.name,
      'isHost': isHost,
    };
  }

  /// Convert to map (for JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'role': role.name,
      'isHost': isHost,
    };
  }

  /// Merge Firebase Auth user with Firestore data
  UserModel mergeWithFirestore(Map<String, dynamic>? firestoreData) {
    if (firestoreData == null) return this;

    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? firestoreData['displayName'] as String? ?? firestoreData['name'] as String?,
      photoUrl: photoUrl ?? firestoreData['photoUrl'] as String? ?? firestoreData['photoURL'] as String?,
      emailVerified: firestoreData['emailVerified'] as bool? ?? emailVerified,
      phoneNumber: phoneNumber ?? firestoreData['phoneNumber'] as String?,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      role: _parseRole(firestoreData['role'] as String?),
      isHost: firestoreData['isHost'] as bool? ?? false,
    );
  }

  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      emailVerified: emailVerified,
      phoneNumber: phoneNumber,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      role: role,
      isHost: isHost,
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
