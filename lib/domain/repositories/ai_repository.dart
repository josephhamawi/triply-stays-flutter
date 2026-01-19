import '../entities/ai_chat_message.dart';
import '../entities/search_intent.dart';

/// Abstract repository interface for AI features
abstract class AIRepository {
  /// Parse a natural language search query into structured intent
  Future<SearchIntent> parseSearchQuery(String query);

  /// Send a chat message and get AI response
  Future<String> sendChatMessage({
    required String conversationId,
    required String message,
    List<AIChatMessage>? history,
    String? listingContext,
  });

  /// Get recommended listing IDs based on user preferences
  Future<List<String>> getRecommendedListingIds({
    required String userId,
    List<String>? likedListingIds,
    List<String>? viewedListingIds,
  });

  /// Watch chat history for a conversation
  Stream<List<AIChatMessage>> watchChatHistory(String conversationId);

  /// Save a chat message to Firestore
  Future<void> saveChatMessage(AIChatMessage message);

  /// Create a new conversation and return its ID
  Future<String> createConversation({
    required String userId,
    String? listingId,
  });

  /// Get or create a conversation for AI chat
  Future<String> getOrCreateConversation({
    required String userId,
    String? listingId,
  });
}
