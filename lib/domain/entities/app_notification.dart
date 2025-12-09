import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types matching web app
enum NotificationType {
  message,
  listing,
  like,
  booking,
  review,
  user,
  admin,
  unknown,
}

/// App notification entity matching web app Firestore structure
class AppNotification {
  final String id;
  final String userId;
  final String message;
  final NotificationType type;
  final String? listingId;
  final DateTime timestamp;
  final bool read;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    this.listingId,
    required this.timestamp,
    required this.read,
  });

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      type: _parseType(data['type']),
      listingId: data['listingId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'message': message,
      'type': type.name,
      'listingId': listingId,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  /// Parse notification type from string
  static NotificationType _parseType(String? type) {
    if (type == null) return NotificationType.unknown;
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.unknown,
    );
  }

  /// Copy with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    String? message,
    NotificationType? type,
    String? listingId,
    DateTime? timestamp,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      listingId: listingId ?? this.listingId,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}
