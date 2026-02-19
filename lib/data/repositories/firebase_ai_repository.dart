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
      // Fall back to local smart responses when AI service fails
      return _generateLocalResponse(message, listingContext);
    }
  }

  /// Generate a helpful response locally when AI service is unavailable
  String _generateLocalResponse(String message, String? listingContext) {
    final msg = message.toLowerCase();

    // Property-specific context
    if (listingContext != null) {
      if (msg.contains('price') || msg.contains('cost') || msg.contains('how much')) {
        return 'You can find the pricing details on the property listing page. Prices may vary between weekdays and weekends. Feel free to message the host directly for special rates or longer stay discounts!';
      }
      if (msg.contains('book') || msg.contains('reserve') || msg.contains('available')) {
        return 'To book this property, you can contact the host directly through the listing page using the Call, WhatsApp, or Message buttons. They\'ll confirm availability for your dates!';
      }
      if (msg.contains('amenit') || msg.contains('wifi') || msg.contains('pool') || msg.contains('parking')) {
        return 'You can find the full list of amenities on the property listing page. If you need specific details, I recommend messaging the host directly - they\'re usually very responsive!';
      }
    }

    // Best time to visit
    if (msg.contains('best time') || msg.contains('when to visit') || msg.contains('season')) {
      return 'Lebanon is beautiful year-round! **Summer (June-September)** is perfect for beach towns like Batroun, Byblos, and Tyre. **Winter (December-March)** is ideal for skiing in the Cedars and Faraya. **Spring and Fall** offer mild weather, great for exploring Beirut, the Chouf, and mountain villages. Each season has its own charm!';
    }

    // Family recommendations
    if (msg.contains('family') || msg.contains('kid') || msg.contains('children')) {
      return 'For family-friendly stays, I recommend:\n\n- **Byblos/Jbeil** - Beautiful beaches with calm waters, historical sites kids love\n- **Faraya/Faqra** - Mountain resorts with activities for all ages\n- **Batroun** - Charming coastal town with family-friendly restaurants\n- **Broummana** - Cool mountain air with parks and entertainment\n\nLook for properties with pools, gardens, and multiple bedrooms for the best family experience!';
    }

    // Budget tips
    if (msg.contains('budget') || msg.contains('cheap') || msg.contains('afford') || msg.contains('save')) {
      return 'Here are some budget tips for vacation rentals in Lebanon:\n\n- **Book weekdays** - many properties offer lower weekday rates\n- **Stay longer** - hosts often give discounts for weekly or monthly stays\n- **Try mountain towns** - often more affordable than popular beach areas\n- **Off-season deals** - visit beach towns in spring/fall for lower prices\n- **Message hosts directly** - you can often negotiate better rates\n\nUse the Search feature to filter by your budget!';
    }

    // Location questions
    if (msg.contains('where') || msg.contains('location') || msg.contains('area') || msg.contains('region')) {
      return 'Lebanon has amazing regions to explore:\n\n- **Beirut** - Vibrant nightlife, restaurants, and culture\n- **North** - Batroun, Byblos, Tripoli - coastal charm\n- **Mount Lebanon** - Broummana, Faraya, Bhamdoun - mountain retreats\n- **South** - Tyre, Sidon - historic cities and beaches\n- **Bekaa** - Baalbek, Zahle - wine country and ruins\n\nWhat kind of experience are you looking for?';
    }

    // Safety
    if (msg.contains('safe') || msg.contains('security') || msg.contains('danger')) {
      return 'Lebanon is generally welcoming to tourists. Here are some tips:\n\n- Most tourist areas are very safe\n- People are incredibly hospitable and helpful\n- Always verify property details with the host before booking\n- Use the in-app messaging to communicate with hosts\n- Keep emergency contacts handy\n\nFeel free to ask about specific areas you\'re interested in!';
    }

    // Greetings
    if (msg.contains('hello') || msg.contains('hi') || msg.contains('hey') || msg.contains('help')) {
      return 'Hi there! I\'m Triply, your travel assistant for Lebanon. I can help you with:\n\n- **Finding properties** - Use the Search tab to describe what you\'re looking for\n- **Travel tips** - Ask me about the best times to visit, regions, and budget advice\n- **Property questions** - I can guide you on how to book and contact hosts\n\nWhat would you like to know?';
    }

    // Food / restaurants
    if (msg.contains('food') || msg.contains('restaurant') || msg.contains('eat') || msg.contains('cuisine')) {
      return 'Lebanese cuisine is world-renowned! Each region has specialties:\n\n- **Beirut** - Fine dining, street food, international cuisine\n- **Batroun** - Fresh seafood by the sea\n- **Zahle** - Famous for its riverside restaurants and arak\n- **Mountain villages** - Traditional Lebanese mezze\n\nMany of our listed properties have full kitchens too, perfect for cooking with fresh local ingredients from nearby markets!';
    }

    // Default helpful response
    return 'Thanks for your question! While I work best with specific topics like:\n\n- **Travel timing** - "Best time to visit Lebanon?"\n- **Destinations** - "Where should I stay for beaches?"\n- **Budget help** - "Tips for affordable stays"\n- **Family travel** - "Family-friendly recommendations"\n\nYou can also use the **Search** tab to find properties by describing what you want, like "Beach villa with pool" or "Mountain cabin for family".\n\nHow can I help you today?';
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
