import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../presentation/providers/messaging/messaging_provider.dart';

/// No-op messaging repository for when Firebase isn't available
class NoOpMessagingRepository implements MessagingRepositoryBase {
  @override
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return Stream.value([]);
  }

  @override
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return Stream.value([]);
  }

  @override
  Stream<int> getTotalUnreadCountStream(String userId) {
    return Stream.value(0);
  }

  @override
  Future<Conversation?> getConversation(String conversationId) async {
    return null;
  }

  @override
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
    throw Exception('Messaging is unavailable. Firebase is not initialized.');
  }

  @override
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    throw Exception('Messaging is unavailable. Firebase is not initialized.');
  }

  @override
  Future<void> markMessagesAsRead({required String chatId, required String userId}) async {}

  @override
  Future<void> deleteConversation(String chatId, String userId) async {}

  @override
  Future<void> archiveConversation({required String chatId, required String userId}) async {}

  @override
  Future<void> unarchiveConversation({required String chatId, required String userId}) async {}
}
