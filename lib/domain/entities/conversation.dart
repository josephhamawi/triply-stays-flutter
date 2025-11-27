import 'package:flutter/foundation.dart';

/// Participant info stored in conversations
@immutable
class ConversationParticipant {
  final String id;
  final String name;
  final String? photoUrl;

  const ConversationParticipant({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory ConversationParticipant.fromMap(Map<String, dynamic> map) {
    return ConversationParticipant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}

/// Conversation entity representing a chat thread between users
@immutable
class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, ConversationParticipant> participants;
  final String? listingId;
  final String? listingTitle;
  final String? listingImageUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the other participant for a 1-on-1 conversation
  ConversationParticipant? getOtherParticipant(String currentUserId) {
    for (final entry in participants.entries) {
      if (entry.key != currentUserId) {
        return entry.value;
      }
    }
    return null;
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, ConversationParticipant>? participants,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participants': participants.map((k, v) => MapEntry(k, v.toMap())),
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Firestore map
  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    final participantsMap = <String, ConversationParticipant>{};
    if (map['participants'] != null) {
      (map['participants'] as Map<String, dynamic>).forEach((key, value) {
        participantsMap[key] = ConversationParticipant.fromMap(value as Map<String, dynamic>);
      });
    }

    final unreadCountMap = <String, int>{};
    if (map['unreadCount'] != null) {
      (map['unreadCount'] as Map<String, dynamic>).forEach((key, value) {
        unreadCountMap[key] = (value as num).toInt();
      });
    }

    return Conversation(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participants: participantsMap,
      listingId: map['listingId'],
      listingTitle: map['listingTitle'],
      listingImageUrl: map['listingImageUrl'],
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.parse(map['lastMessageAt'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: unreadCountMap,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Conversation(id: $id, participants: ${participantIds.length}, lastMessage: $lastMessage)';
  }
}
