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
/// Compatible with web app's 'chats' collection structure
@immutable
class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, ConversationParticipant> participants;
  final String? hostId;
  final String? guestId;
  final String? listingId;
  final String? listingTitle;
  final String? listingImageUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final Map<String, bool> archivedBy;
  final bool readByHost;
  final bool readByGuest;
  final List<String> deletedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.hostId,
    this.guestId,
    this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    this.archivedBy = const {},
    this.readByHost = true,
    this.readByGuest = true,
    this.deletedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if conversation is archived for a specific user
  bool isArchivedFor(String userId) {
    return archivedBy[userId] == true;
  }

  /// Check if conversation is deleted for a specific user
  bool isDeletedFor(String userId) {
    return deletedBy.contains(userId);
  }

  /// Check if there are unread messages for this user
  bool hasUnreadFor(String userId) {
    if (hostId == userId) {
      return !readByHost;
    } else if (guestId == userId) {
      return !readByGuest;
    }
    return false;
  }

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
    String? hostId,
    String? guestId,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? archivedBy,
    bool? readByHost,
    bool? readByGuest,
    List<String>? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      archivedBy: archivedBy ?? this.archivedBy,
      readByHost: readByHost ?? this.readByHost,
      readByGuest: readByGuest ?? this.readByGuest,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore map (compatible with web app)
  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'guestId': guestId,
      'hostName': participants[hostId]?.name,
      'guestName': participants[guestId]?.name,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSenderId,
      'readByHost': readByHost,
      'readByGuest': readByGuest,
      'deletedBy': deletedBy,
    };
  }

  /// Create from Firestore map (compatible with web app's 'chats' collection)
  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    // Extract hostId and guestId from web app structure
    final hostId = map['hostId'] as String?;
    final guestId = map['guestId'] as String?;
    final hostName = map['hostName'] as String? ?? 'Host';
    final guestName = map['guestName'] as String? ?? 'Guest';

    // Build participantIds from hostId/guestId
    final participantIds = <String>[];
    if (hostId != null) participantIds.add(hostId);
    if (guestId != null) participantIds.add(guestId);

    // Build participants map
    final participantsMap = <String, ConversationParticipant>{};
    if (hostId != null) {
      participantsMap[hostId] = ConversationParticipant(
        id: hostId,
        name: hostName,
      );
    }
    if (guestId != null) {
      participantsMap[guestId] = ConversationParticipant(
        id: guestId,
        name: guestName,
      );
    }

    // Parse lastMessageTime from Firestore Timestamp
    DateTime? lastMessageAt;
    final lastMessageTime = map['lastMessageTime'];
    if (lastMessageTime != null) {
      try {
        lastMessageAt = (lastMessageTime as dynamic).toDate();
      } catch (_) {
        // Fallback if it's already a DateTime or other format
      }
    }

    // Parse deletedBy array
    final deletedBy = List<String>.from(map['deletedBy'] ?? []);

    // Parse archivedBy (custom field for Flutter)
    final archivedByMap = <String, bool>{};
    if (map['archivedBy'] != null) {
      (map['archivedBy'] as Map<String, dynamic>).forEach((key, value) {
        archivedByMap[key] = value as bool;
      });
    }

    return Conversation(
      id: id,
      participantIds: participantIds,
      participants: participantsMap,
      hostId: hostId,
      guestId: guestId,
      listingId: map['listingId'],
      listingTitle: map['listingTitle'],
      listingImageUrl: null,
      lastMessage: map['lastMessage'],
      lastMessageAt: lastMessageAt,
      lastMessageSenderId: map['lastMessageSender'],
      unreadCount: const {},
      archivedBy: archivedByMap,
      readByHost: map['readByHost'] ?? true,
      readByGuest: map['readByGuest'] ?? true,
      deletedBy: deletedBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
