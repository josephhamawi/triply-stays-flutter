import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Repository for handling messaging functionality with Firestore
class MessagingRepository {
  final FirebaseFirestore _firestore;

  MessagingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(String conversationId) =>
      _conversationsRef.doc(conversationId).collection('messages');

  /// Get conversations stream for a user
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get a single conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _conversationsRef.doc(conversationId).get();
    if (doc.exists && doc.data() != null) {
      return Conversation.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Find or create a conversation between two users for a specific listing
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    String? currentUserPhotoUrl,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
  }) async {
    // First, try to find existing conversation
    final existingQuery = await _conversationsRef
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (final doc in existingQuery.docs) {
      final data = doc.data();
      final participantIds = List<String>.from(data['participantIds'] ?? []);

      if (participantIds.contains(otherUserId)) {
        // If we have a listingId, check if it matches
        if (listingId != null) {
          if (data['listingId'] == listingId) {
            return Conversation.fromMap(doc.id, data);
          }
        } else {
          // No listingId specified, return any conversation with this user
          return Conversation.fromMap(doc.id, data);
        }
      }
    }

    // Create new conversation
    final now = DateTime.now();
    final participants = {
      currentUserId: ConversationParticipant(
        id: currentUserId,
        name: currentUserName,
        photoUrl: currentUserPhotoUrl,
      ),
      otherUserId: ConversationParticipant(
        id: otherUserId,
        name: otherUserName,
        photoUrl: otherUserPhotoUrl,
      ),
    };

    final conversation = Conversation(
      id: '',
      participantIds: [currentUserId, otherUserId],
      participants: participants,
      listingId: listingId,
      listingTitle: listingTitle,
      listingImageUrl: listingImageUrl,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _conversationsRef.add(conversation.toMap());
    return conversation.copyWith(id: docRef.id);
  }

  /// Get messages stream for a conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _messagesRef(conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final now = DateTime.now();

    final message = Message(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: content,
      type: type,
      createdAt: now,
    );

    // Add message to subcollection
    final docRef = await _messagesRef(conversationId).add(message.toMap());

    // Update conversation with last message info
    final conversation = await getConversation(conversationId);
    if (conversation != null) {
      // Increment unread count for other participants
      final newUnreadCount = Map<String, int>.from(conversation.unreadCount);
      for (final participantId in conversation.participantIds) {
        if (participantId != senderId) {
          newUnreadCount[participantId] = (newUnreadCount[participantId] ?? 0) + 1;
        }
      }

      await _conversationsRef.doc(conversationId).update({
        'lastMessage': content,
        'lastMessageAt': now.toIso8601String(),
        'lastMessageSenderId': senderId,
        'unreadCount': newUnreadCount,
        'updatedAt': now.toIso8601String(),
      });
    }

    return message.copyWith(id: docRef.id);
  }

  /// Mark messages as read for a user in a conversation
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    // Reset unread count for this user
    await _conversationsRef.doc(conversationId).update({
      'unreadCount.$userId': 0,
    });

    // Mark individual messages as read
    final unreadMessages = await _messagesRef(conversationId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  /// Get total unread count for a user across all conversations
  Stream<int> getTotalUnreadCountStream(String userId) {
    return _conversationsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null && unreadCount[userId] != null) {
          total += (unreadCount[userId] as num).toInt();
        }
      }
      return total;
    });
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages first
    final messages = await _messagesRef(conversationId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete conversation
    await _conversationsRef.doc(conversationId).delete();
  }
}
