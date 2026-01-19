import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ai_chat_message.dart';
import '../../../domain/entities/listing.dart';
import '../auth/auth_provider.dart';
import '../listings/listings_provider.dart';
import 'ai_providers.dart';

/// State for AI chat
class AIChatState {
  final String? conversationId;
  final List<AIChatMessage> messages;
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final Listing? listingContext;

  const AIChatState({
    this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
    this.listingContext,
  });

  AIChatState copyWith({
    String? conversationId,
    List<AIChatMessage>? messages,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    Listing? listingContext,
    bool clearError = false,
    bool clearListingContext = false,
  }) {
    return AIChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : (error ?? this.error),
      listingContext: clearListingContext ? null : (listingContext ?? this.listingContext),
    );
  }
}

/// Notifier for AI chat functionality
class AIChatNotifier extends StateNotifier<AIChatState> {
  final Ref _ref;

  AIChatNotifier(this._ref) : super(const AIChatState());

  /// Initialize or resume a chat conversation
  Future<void> initChat({String? listingId}) async {
    final authState = _ref.read(authNotifierProvider);
    if (authState.user == null) {
      state = state.copyWith(error: 'Please sign in to use the AI assistant');
      return;
    }

    state = state.copyWith(isInitializing: true, clearError: true);

    try {
      final aiRepository = _ref.read(aiRepositoryProvider);

      // Get or create conversation
      final conversationId = await aiRepository.getOrCreateConversation(
        userId: authState.user!.id,
        listingId: listingId,
      );

      state = state.copyWith(
        conversationId: conversationId,
        isInitializing: false,
      );

      // Load listing context if provided
      if (listingId != null) {
        final listing = await _ref.read(listingDetailProvider(listingId).future);
        if (listing != null) {
          state = state.copyWith(listingContext: listing);
        }
      }

      // Start watching chat history
      _watchChatHistory(conversationId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize chat: ${e.toString()}',
        isInitializing: false,
      );
    }
  }

  /// Watch chat history stream
  void _watchChatHistory(String conversationId) {
    final aiRepository = _ref.read(aiRepositoryProvider);

    aiRepository.watchChatHistory(conversationId).listen((messages) {
      if (mounted) {
        state = state.copyWith(messages: messages);
      }
    });
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    if (state.conversationId == null) {
      await initChat();
      if (state.conversationId == null) return;
    }

    final conversationId = state.conversationId!;

    // Create user message
    final userMessage = AIChatMessage.user(
      conversationId: conversationId,
      content: message.trim(),
      listingIds: state.listingContext != null ? [state.listingContext!.id] : [],
    );

    // Add to local state immediately for responsiveness
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final aiRepository = _ref.read(aiRepositoryProvider);

      // Save user message
      await aiRepository.saveChatMessage(userMessage);

      // Build listing context string if available
      String? listingContextStr;
      if (state.listingContext != null) {
        final listing = state.listingContext!;
        listingContextStr = '''
Property: ${listing.title}
Location: ${listing.city}, ${listing.country}
Price: \$${listing.price}/night
Bedrooms: ${listing.bedrooms}
Bathrooms: ${listing.bathrooms}
Max Guests: ${listing.maxGuests}
Amenities: ${listing.amenities.join(', ')}
Views: ${listing.listingViews.join(', ')}
Description: ${listing.description}
''';
      }

      // Get AI response
      final response = await aiRepository.sendChatMessage(
        conversationId: conversationId,
        message: message.trim(),
        history: state.messages.take(10).toList(), // Keep context manageable
        listingContext: listingContextStr,
      );

      // Create assistant message
      final assistantMessage = AIChatMessage.assistant(
        conversationId: conversationId,
        content: response,
        listingIds: state.listingContext != null ? [state.listingContext!.id] : [],
      );

      // Save assistant message
      await aiRepository.saveChatMessage(assistantMessage);

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send message: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Set listing context for the chat
  Future<void> setListingContext(String listingId) async {
    final listing = await _ref.read(listingDetailProvider(listingId).future);
    if (listing != null) {
      state = state.copyWith(listingContext: listing);
    }
  }

  /// Clear listing context
  void clearListingContext() {
    state = state.copyWith(clearListingContext: true);
  }

  /// Clear chat and start fresh
  Future<void> clearChat() async {
    state = const AIChatState();
  }
}

/// Provider for AI chat state and notifier
final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  return AIChatNotifier(ref);
});

/// Welcome message shown when chat is empty
final aiWelcomeMessageProvider = Provider<String>((ref) {
  return '''
Hi! I'm Triply, your AI travel assistant.

I can help you with:
- Finding the perfect vacation rental
- Answering questions about properties
- Travel tips and recommendations

How can I help you today?
''';
});
