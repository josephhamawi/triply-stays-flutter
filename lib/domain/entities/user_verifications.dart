import 'package:flutter/foundation.dart';

/// Single verification status
@immutable
class VerificationStatus {
  final bool verified;
  final DateTime? verifiedAt;
  final String? code;
  final DateTime? expiresAt;
  final String? status; // 'pending', 'verified', 'rejected'
  final String? documentType;
  final String? documentUrl;
  final DateTime? submittedAt;

  const VerificationStatus({
    this.verified = false,
    this.verifiedAt,
    this.code,
    this.expiresAt,
    this.status,
    this.documentType,
    this.documentUrl,
    this.submittedAt,
  });

  factory VerificationStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const VerificationStatus();
    return VerificationStatus(
      verified: map['verified'] as bool? ?? false,
      verifiedAt: _parseDateTime(map['verifiedAt']),
      code: map['code'] as String?,
      expiresAt: _parseDateTime(map['expiresAt']),
      status: map['status'] as String?,
      documentType: map['documentType'] as String?,
      documentUrl: map['documentUrl'] as String?,
      submittedAt: _parseDateTime(map['submittedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verified': verified,
      if (verifiedAt != null) 'verifiedAt': verifiedAt,
      if (code != null) 'code': code,
      if (expiresAt != null) 'expiresAt': expiresAt,
      if (status != null) 'status': status,
      if (documentType != null) 'documentType': documentType,
      if (documentUrl != null) 'documentUrl': documentUrl,
      if (submittedAt != null) 'submittedAt': submittedAt,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate();
    }
    return null;
  }

  VerificationStatus copyWith({
    bool? verified,
    DateTime? verifiedAt,
    String? code,
    DateTime? expiresAt,
    String? status,
    String? documentType,
    String? documentUrl,
    DateTime? submittedAt,
  }) {
    return VerificationStatus(
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

/// User verifications container
@immutable
class UserVerifications {
  final VerificationStatus email;
  final VerificationStatus phone;
  final VerificationStatus identity;

  const UserVerifications({
    this.email = const VerificationStatus(),
    this.phone = const VerificationStatus(),
    this.identity = const VerificationStatus(),
  });

  factory UserVerifications.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserVerifications();
    return UserVerifications(
      email: VerificationStatus.fromMap(map['email'] as Map<String, dynamic>?),
      phone: VerificationStatus.fromMap(map['phone'] as Map<String, dynamic>?),
      identity: VerificationStatus.fromMap(map['identity'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email.toMap(),
      'phone': phone.toMap(),
      'identity': identity.toMap(),
    };
  }

  /// Calculate trust score based on verifications (same as web app)
  int get trustScore {
    int score = 0;
    if (email.verified) score += 20;
    if (phone.verified) score += 20;
    if (identity.verified) score += 30;
    return score;
  }

  /// Get verification count
  int get verifiedCount {
    int count = 0;
    if (email.verified) count++;
    if (phone.verified) count++;
    if (identity.verified) count++;
    return count;
  }

  /// Total possible verifications
  int get totalCount => 3;

  /// Get trust level based on score
  TrustLevel get trustLevel {
    final score = trustScore;
    if (score >= 60) {
      return TrustLevel.trusted;
    } else if (score >= 40) {
      return TrustLevel.verified;
    } else if (score >= 20) {
      return TrustLevel.basic;
    } else {
      return TrustLevel.newUser;
    }
  }

  UserVerifications copyWith({
    VerificationStatus? email,
    VerificationStatus? phone,
    VerificationStatus? identity,
  }) {
    return UserVerifications(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      identity: identity ?? this.identity,
    );
  }
}

/// Trust level enum
enum TrustLevel {
  newUser(name: 'New User', color: 0xFF6b7280, description: 'Limited verification'),
  basic(name: 'Basic Verification', color: 0xFFf59e0b, description: 'Some verification completed'),
  verified(name: 'Verified', color: 0xFF023047, description: 'Well verified'),
  trusted(name: 'Trusted', color: 0xFFFB8500, description: 'Highly verified and trusted');

  final String name;
  final int color;
  final String description;

  const TrustLevel({
    required this.name,
    required this.color,
    required this.description,
  });
}
