import 'package:flutter/foundation.dart';

/// User entity representing an authenticated user in the domain layer
@immutable
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final UserRole role;
  final bool isHost;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneNumber,
    this.createdAt,
    this.lastLoginAt,
    this.role = UserRole.guest,
    this.isHost = false,
  });

  /// Creates an empty user (for initial/loading states)
  const User.empty()
      : id = '',
        email = '',
        displayName = null,
        photoUrl = null,
        emailVerified = false,
        phoneNumber = null,
        createdAt = null,
        lastLoginAt = null,
        role = UserRole.guest,
        isHost = false;

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserRole? role,
    bool? isHost,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      isHost: isHost ?? this.isHost,
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
