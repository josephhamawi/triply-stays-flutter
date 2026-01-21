import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/search_intent.dart';
import '../../domain/repositories/ai_repository.dart';

/// No-op AI repository for when Firebase isn't available
class NoOpAIRepository implements AIRepository {
  @override
  Future<SearchIntent> parseSearchQuery(String query) async {
    return SearchIntent(
      originalQuery: query,
      confidence: 0.0,
    );
  }

  @override
  Future<String> sendChatMessage({
    required String conversationId,
    required String message,
    List<AIChatMessage>? history,
    String? listingContext,
  }) async {
    return 'AI service is currently unavailable. Please try again later.';
  }

  @override
  Future<List<String>> getRecommendedListingIds({
    required String userId,
    List<String>? likedListingIds,
    List<String>? viewedListingIds,
  }) async {
    return [];
  }

  @override
  Stream<List<AIChatMessage>> watchChatHistory(String conversationId) {
    return Stream.value([]);
  }

  @override
  Future<void> saveChatMessage(AIChatMessage message) async {}

  @override
  Future<String> createConversation({
    required String userId,
    String? listingId,
  }) async {
    return 'offline_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> getOrCreateConversation({
    required String userId,
    String? listingId,
  }) async {
    return 'offline_${DateTime.now().millisecondsSinceEpoch}';
  }
}
