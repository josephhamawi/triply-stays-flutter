import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/ai_service.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/search_intent.dart';
import '../../domain/repositories/ai_repository.dart';

/// Firebase implementation of AIRepository
class FirebaseAIRepository implements AIRepository {
  final FirebaseFirestore _firestore;
  final AIService _aiService;

  FirebaseAIRepository({
    required AIService aiService,
    FirebaseFirestore? firestore,
  })  : _aiService = aiService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _aiChatsRef =>
      _firestore.collection('aiChats');

  CollectionReference<Map<String, dynamic>> _messagesRef(String conversationId) =>
      _aiChatsRef.doc(conversationId).collection('messages');

  /// Schema for search intent parsing
  static const String _searchIntentSchema = '''
{
  "location": "string or null - city or area mentioned",
  "propertyType": "string or null - type like cabin, villa, apartment, house, chalet",
  "amenities": ["array of strings - pool, wifi, parking, hot tub, kitchen, etc."],
  "minBedrooms": "integer or null - minimum bedrooms needed",
  "minBathrooms": "integer or null - minimum bathrooms needed",
  "minGuests": "integer or null - number of guests",
  "maxPrice": "number or null - maximum price per night in dollars",
  "views": ["array of strings - sea, mountain, city, garden, lake, etc."],
  "confidence": "number 0-1 - how confident you are in the parsing"
}
''';

  @override
  Future<SearchIntent> parseSearchQuery(String query) async {
    final prompt = '''
Parse this vacation rental search query into structured filters:
"$query"

Extract any mentioned:
- Location (city, area, beach, mountain, etc.)
- Property type (cabin, villa, apartment, house, chalet)
- Amenities (pool, wifi, parking, hot tub, kitchen, AC, etc.)
- Number of bedrooms
- Number of bathrooms
- Number of guests
- Price constraints
- Views (sea view, mountain view, city view, etc.)

If something isn't mentioned, use null for that field.
''';

    try {
      final response = await _aiService.parseStructuredResponse(
        prompt: prompt,
        schema: _searchIntentSchema,
      );

      return SearchIntent.fromJson(response, query);
    } catch (e) {
      // Return empty intent if parsing fails
      return SearchIntent(originalQuery: query, confidence: 0.0);
    }
  }

  @override
  Future<String> sendChatMessage({
    required String conversationId,
    required String message,
    List<AIChatMessage>? history,
    String? listingContext,
  }) async {
    // Build AI message history
    final aiHistory = history?.map((m) => AIMessage(
      content: m.content,
      role: m.role == AIChatRole.user ? 'user' : 'model',
    )).toList();

    // Build prompt with optional listing context
    String prompt = message;
    if (listingContext != null) {
      prompt = '''
The user is asking about this property:
$listingContext

User question: $message
''';
    }

    try {
      final response = await _aiService.generateResponse(
        prompt: prompt,
        history: aiHistory,
      );

      return response;
    } catch (e) {
      return 'I apologize, but I encountered an error. Please try again.';
    }
  }

  @override
  Future<List<String>> getRecommendedListingIds({
    required String userId,
    List<String>? likedListingIds,
    List<String>? viewedListingIds,
  }) async {
    if (likedListingIds == null || likedListingIds.isEmpty) {
      return [];
    }

    // Fetch sample liked listings to understand preferences
    final likedListingsData = await Future.wait(
      likedListingIds.take(5).map((id) =>
          _firestore.collection('listings').doc(id).get()),
    );

    final likedListings = likedListingsData
        .where((doc) => doc.exists)
        .map((doc) => doc.data()!)
        .toList();

    if (likedListings.isEmpty) {
      return [];
    }

    // Build preference summary from liked listings
    final categories = <String>[];

    for (final listing in likedListings) {
      if (listing['category'] != null) categories.add(listing['category']);
    }

    // Query for similar listings excluding already liked ones
    Query<Map<String, dynamic>> query = _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .limit(20);

    // Add category filter if consistent preference
    final categoryCount = <String, int>{};
    for (final cat in categories) {
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }
    final topCategory = categoryCount.entries.isEmpty
        ? null
        : categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    if (topCategory != null && categoryCount[topCategory]! >= 2) {
      query = query.where('category', isEqualTo: topCategory);
    }

    final results = await query.get();

    // Filter out already liked listings and return IDs
    return results.docs
        .map((doc) => doc.id)
        .where((id) => !likedListingIds.contains(id))
        .take(10)
        .toList();
  }

  @override
  Stream<List<AIChatMessage>> watchChatHistory(String conversationId) {
    return _messagesRef(conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> saveChatMessage(AIChatMessage message) async {
    await _messagesRef(message.conversationId).add(message.toMap());

    // Update conversation's lastMessageAt
    await _aiChatsRef.doc(message.conversationId).update({
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> createConversation({
    required String userId,
    String? listingId,
  }) async {
    final doc = await _aiChatsRef.add({
      'userId': userId,
      'listingId': listingId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  @override
  Future<String> getOrCreateConversation({
    required String userId,
    String? listingId,
  }) async {
    // Look for existing conversation
    Query<Map<String, dynamic>> query = _aiChatsRef
        .where('userId', isEqualTo: userId);

    if (listingId != null) {
      query = query.where('listingId', isEqualTo: listingId);
    } else {
      query = query.where('listingId', isEqualTo: null);
    }

    final existing = await query.limit(1).get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new conversation
    return createConversation(userId: userId, listingId: listingId);
  }
}
