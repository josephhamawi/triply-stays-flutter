import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Message entity representing a single chat message
@immutable
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Convert to Firestore map (compatible with web app)
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': content,
      'messageType': type.name,
      'read': isRead,
      'status': 'sent',
      if (type == MessageType.image && senderPhotoUrl != null)
        'imageUrl': senderPhotoUrl,
    };
  }

  /// Helper function to parse timestamps from various formats
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    // Handle Firestore Timestamp object
    if (value is Timestamp) {
      return value.toDate();
    }

    // Handle Map with seconds (Firestore Timestamp as Map)
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as int) * 1000,
      );
    }

    // Handle ISO string
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    // Handle DateTime directly
    if (value is DateTime) {
      return value;
    }

    // Fallback: try dynamic toDate()
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }

  /// Create from Firestore map (compatible with web app)
  factory Message.fromMap(String id, Map<String, dynamic> map) {
    // Handle timestamp from Firestore (can be Timestamp or ISO string)
    DateTime createdAt = _parseTimestamp(map['timestamp']) ??
        _parseTimestamp(map['createdAt']) ??
        DateTime.now();

    // Parse readAt timestamp
    DateTime? readAt = _parseTimestamp(map['readAt']);

    // Parse message type from web's 'messageType' or Flutter's 'type'
    final typeStr = map['messageType'] ?? map['type'] ?? 'text';

    return Message(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['imageUrl'],
      content: map['text'] ?? map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MessageType.text,
      ),
      createdAt: createdAt,
      readAt: readAt,
      isRead: map['read'] ?? map['isRead'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, content: $content)';
  }
}

/// Message types
enum MessageType {
  text,
  image,
  system,
}
