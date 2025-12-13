import 'package:flutter/foundation.dart';
import 'user_verifications.dart';

/// User entity representing an authenticated user in the domain layer
@immutable
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final bool emailVerified;
  final String? phoneNumber;
  final bool hasWhatsApp;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final UserRole role;
  final bool isHost;
  final bool isHostProElite;
  final bool onboardingCompleted;
  final UserVerifications verifications;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneNumber,
    this.hasWhatsApp = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.role = UserRole.guest,
    this.isHost = false,
    this.isHostProElite = false,
    this.onboardingCompleted = false,
    this.verifications = const UserVerifications(),
  });

  /// Get full name from firstName and lastName, or fall back to displayName
  String? get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    if (firstName != null) return firstName;
    if (lastName != null) return lastName;
    return displayName;
  }

  /// Creates an empty user (for initial/loading states)
  const User.empty()
      : id = '',
        email = '',
        displayName = null,
        firstName = null,
        lastName = null,
        photoUrl = null,
        emailVerified = false,
        phoneNumber = null,
        hasWhatsApp = false,
        createdAt = null,
        updatedAt = null,
        lastLoginAt = null,
        role = UserRole.guest,
        isHost = false,
        isHostProElite = false,
        onboardingCompleted = false,
        verifications = const UserVerifications();

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? photoUrl,
    bool? emailVerified,
    String? phoneNumber,
    bool? hasWhatsApp,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserRole? role,
    bool? isHost,
    bool? isHostProElite,
    bool? onboardingCompleted,
    UserVerifications? verifications,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hasWhatsApp: hasWhatsApp ?? this.hasWhatsApp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      isHost: isHost ?? this.isHost,
      isHostProElite: isHostProElite ?? this.isHostProElite,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      verifications: verifications ?? this.verifications,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, emailVerified: $emailVerified)';
  }
}

/// User roles in the application
enum UserRole {
  guest,
  host,
  admin,
}
