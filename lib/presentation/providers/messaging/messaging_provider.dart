import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/messaging_repository.dart';
import '../../../data/repositories/noop_messaging_repository.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../../main.dart' show firebaseInitialized;
import '../auth/auth_provider.dart';

/// Abstract interface for messaging repository (for NoOp support)
abstract class MessagingRepositoryBase {
  Stream<List<Conversation>> getConversationsStream(String userId);
  Stream<List<Message>> getMessagesStream(String conversationId);
  Stream<int> getTotalUnreadCountStream(String userId);
  Future<Conversation?> getConversation(String conversationId);
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
  });
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    MessageType type,
  });
  Future<void> markMessagesAsRead({required String chatId, required String userId});
  Future<void> deleteConversation(String chatId, String userId);
  Future<void> archiveConversation({required String chatId, required String userId});
  Future<void> unarchiveConversation({required String chatId, required String userId});
}

/// Provider for MessagingRepository
final messagingRepositoryProvider = Provider<MessagingRepositoryBase>((ref) {
  if (!firebaseInitialized) {
    return NoOpMessagingRepository();
  }
  return MessagingRepository();
});

/// Provider for user's conversations stream
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getConversationsStream(userId);
});

/// Provider for messages in a specific conversation
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getMessagesStream(conversationId);
});

/// Provider for total unread message count
final totalUnreadCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value(0);
  }

  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getTotalUnreadCountStream(userId);
});

/// Provider for a single conversation
final conversationProvider = FutureProvider.family<Conversation?, String>((ref, conversationId) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getConversation(conversationId);
});

/// State notifier for messaging actions
class MessagingNotifier extends StateNotifier<AsyncValue<void>> {
  final MessagingRepositoryBase _repository;
  final Ref _ref;

  MessagingNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Get or create a conversation for a listing inquiry
  /// The isCurrentUserHost parameter determines the chat ID format
  Future<Conversation?> startConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    bool isCurrentUserHost = false,
  }) async {
    final authState = _ref.read(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) return null;

    state = const AsyncValue.loading();

    try {
      final conversation = await _repository.getOrCreateConversation(
        currentUserId: currentUser.id,
        currentUserName: currentUser.fullName ?? currentUser.email,
        currentUserPhotoUrl: currentUser.photoUrl,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhotoUrl: otherUserPhotoUrl,
        listingId: listingId,
        listingTitle: listingTitle,
        listingImageUrl: listingImageUrl,
        isCurrentUserHost: isCurrentUserHost,
      );

      state = const AsyncValue.data(null);
      return conversation;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Send a message
  Future<Message?> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final authState = _ref.read(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) return null;

    try {
      final message = await _repository.sendMessage(
        chatId: chatId,
        senderId: currentUser.id,
        senderName: currentUser.fullName ?? currentUser.email,
        senderPhotoUrl: currentUser.photoUrl,
        content: content,
        type: type,
      );

      return message;
    } catch (e) {
      return null;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId) async {
    final authState = _ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    try {
      await _repository.markMessagesAsRead(
        chatId: chatId,
        userId: userId,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Delete a conversation (soft delete - adds to deletedBy array)
  Future<bool> deleteConversation(String chatId) async {
    final authState = _ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return false;

    state = const AsyncValue.loading();

    try {
      await _repository.deleteConversation(chatId, userId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Archive a conversation
  Future<bool> archiveConversation(String chatId) async {
    final authState = _ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return false;

    state = const AsyncValue.loading();

    try {
      await _repository.archiveConversation(
        chatId: chatId,
        userId: userId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Unarchive a conversation
  Future<bool> unarchiveConversation(String chatId) async {
    final authState = _ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return false;

    state = const AsyncValue.loading();

    try {
      await _repository.unarchiveConversation(
        chatId: chatId,
        userId: userId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for MessagingNotifier
final messagingNotifierProvider = StateNotifierProvider<MessagingNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(messagingRepositoryProvider);
  return MessagingNotifier(repository, ref);
});
