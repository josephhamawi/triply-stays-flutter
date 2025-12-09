import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Repository for handling messaging functionality with Firestore
/// Uses 'chats' collection for compatibility with web app
class MessagingRepository {
  final FirebaseFirestore _firestore;

  MessagingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Uses 'chats' collection to match web app structure
  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection('messages');

  /// Get conversations stream for a user
  /// Queries both hostId and guestId fields for web app compatibility
  Stream<List<Conversation>> getConversationsStream(String userId) {
    // Query for chats where user is host
    final hostChatsStream = _chatsRef
        .where('hostId', isEqualTo: userId)
        .snapshots();

    // Query for chats where user is guest
    final guestChatsStream = _chatsRef
        .where('guestId', isEqualTo: userId)
        .snapshots();

    // Combine both streams
    return hostChatsStream.asyncExpand((hostSnapshot) {
      return guestChatsStream.map((guestSnapshot) {
        // Combine documents from both queries
        final allDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

        for (final doc in hostSnapshot.docs) {
          allDocs[doc.id] = doc;
        }
        for (final doc in guestSnapshot.docs) {
          allDocs[doc.id] = doc;
        }

        // Convert to Conversation objects
        final conversations = allDocs.values
            .map((doc) => Conversation.fromMap(doc.id, doc.data()))
            // Filter out deleted conversations
            .where((conv) => !conv.isDeletedFor(userId))
            .toList();

        // Sort by lastMessageAt descending (most recent first)
        conversations.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.updatedAt;
          final bTime = b.lastMessageAt ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });

        return conversations;
      });
    });
  }

  /// Get a single conversation by ID
  Future<Conversation?> getConversation(String chatId) async {
    final doc = await _chatsRef.doc(chatId).get();
    if (doc.exists && doc.data() != null) {
      return Conversation.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Find or create a conversation between two users for a specific listing
  /// Uses web app's chat ID format: ${listingId}_${guestId}_${hostId}
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
    required bool isCurrentUserHost,
  }) async {
    // Determine host and guest IDs based on role
    final hostId = isCurrentUserHost ? currentUserId : otherUserId;
    final guestId = isCurrentUserHost ? otherUserId : currentUserId;
    final hostName = isCurrentUserHost ? currentUserName : otherUserName;
    final guestName = isCurrentUserHost ? otherUserName : currentUserName;

    // Generate chat ID in web app format
    final chatId = '${listingId ?? 'general'}_${guestId}_$hostId';

    // Check if chat already exists
    final existingDoc = await _chatsRef.doc(chatId).get();

    if (existingDoc.exists && existingDoc.data() != null) {
      return Conversation.fromMap(existingDoc.id, existingDoc.data()!);
    }

    // Create new chat with web app compatible structure
    final chatData = {
      'hostId': hostId,
      'guestId': guestId,
      'hostName': hostName,
      'guestName': guestName,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'readByHost': true,
      'readByGuest': true,
      'deletedBy': <String>[],
    };

    await _chatsRef.doc(chatId).set(chatData);

    final now = DateTime.now();
    final participants = {
      hostId: ConversationParticipant(id: hostId, name: hostName),
      guestId: ConversationParticipant(id: guestId, name: guestName),
    };

    return Conversation(
      id: chatId,
      participantIds: [hostId, guestId],
      participants: participants,
      hostId: hostId,
      guestId: guestId,
      listingId: listingId,
      listingTitle: listingTitle,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get messages stream for a conversation
  /// Orders by 'timestamp' for web app compatibility
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _messagesRef(chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Send a message (compatible with web app)
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final now = DateTime.now();

    // Create message data compatible with web app
    final messageData = {
      'text': content,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'read': false,
      'messageType': type.name,
      if (type == MessageType.image && senderPhotoUrl != null)
        'imageUrl': senderPhotoUrl,
    };

    // Add message to subcollection
    final docRef = await _messagesRef(chatId).add(messageData);

    // Update chat with last message info (web app compatible)
    final conversation = await getConversation(chatId);
    if (conversation != null) {
      final isHost = senderId == conversation.hostId;

      await _chatsRef.doc(chatId).update({
        'lastMessage': type == MessageType.image ? 'Sent an image' : content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        // Mark as unread for the other party
        if (isHost) 'readByGuest': false else 'readByHost': false,
      });
    }

    final message = Message(
      id: docRef.id,
      conversationId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: content,
      type: type,
      createdAt: now,
    );

    return message;
  }

  /// Mark messages as read for a user in a chat (compatible with web app)
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    // Get conversation to determine if user is host or guest
    final conversation = await getConversation(chatId);
    if (conversation == null) return;

    final isHost = userId == conversation.hostId;

    // Update readByHost or readByGuest flag
    await _chatsRef.doc(chatId).update({
      if (isHost) 'readByHost': true else 'readByGuest': true,
    });

    // Mark individual messages as read
    final unreadMessages = await _messagesRef(chatId)
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Get total unread count for a user across all chats
  /// Uses web app's readByHost/readByGuest structure
  Stream<int> getTotalUnreadCountStream(String userId) {
    // We need to combine both host and guest queries
    final hostChatsStream = _chatsRef.where('hostId', isEqualTo: userId).snapshots();
    final guestChatsStream = _chatsRef.where('guestId', isEqualTo: userId).snapshots();

    return hostChatsStream.asyncExpand((hostSnapshot) {
      return guestChatsStream.map((guestSnapshot) {
        int total = 0;

        // Count unread for chats where user is host
        for (final doc in hostSnapshot.docs) {
          final data = doc.data();
          final deletedBy = List<String>.from(data['deletedBy'] ?? []);
          if (!deletedBy.contains(userId) && data['readByHost'] == false) {
            total += 1;
          }
        }

        // Count unread for chats where user is guest
        for (final doc in guestSnapshot.docs) {
          final data = doc.data();
          final deletedBy = List<String>.from(data['deletedBy'] ?? []);
          if (!deletedBy.contains(userId) && data['readByGuest'] == false) {
            total += 1;
          }
        }

        return total;
      });
    });
  }

  /// Hide a conversation for a user (soft delete using deletedBy array)
  /// Compatible with web app's delete behavior
  Future<void> deleteConversation(String chatId, String userId) async {
    await _chatsRef.doc(chatId).update({
      'deletedBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Archive a conversation for a specific user
  Future<void> archiveConversation({
    required String chatId,
    required String userId,
  }) async {
    await _chatsRef.doc(chatId).update({
      'archivedBy.$userId': true,
    });
  }

  /// Unarchive a conversation for a specific user
  Future<void> unarchiveConversation({
    required String chatId,
    required String userId,
  }) async {
    await _chatsRef.doc(chatId).update({
      'archivedBy.$userId': false,
    });
  }
}
