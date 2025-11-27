import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/messaging_repository.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../auth/auth_provider.dart';

/// Provider for MessagingRepository
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
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
  final MessagingRepository _repository;
  final Ref _ref;

  MessagingNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Get or create a conversation for a listing inquiry
  Future<Conversation?> startConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhotoUrl,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
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
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final authState = _ref.read(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) return null;

    try {
      final message = await _repository.sendMessage(
        conversationId: conversationId,
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
  Future<void> markAsRead(String conversationId) async {
    final authState = _ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    try {
      await _repository.markMessagesAsRead(
        conversationId: conversationId,
        userId: userId,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    state = const AsyncValue.loading();

    try {
      await _repository.deleteConversation(conversationId);
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
