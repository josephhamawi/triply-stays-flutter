/// Conversation Analytics Utility
///
/// Tracks conversation patterns, booking intent, and generates AI insights
/// for GuestIntent AI (Phase 1)

import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// INTENT SIGNAL DETECTION (Keyword-Based MVP)
// ============================================

/// Keywords that indicate booking intent
class IntentKeywords {
  // High intent - strong booking signals
  static const List<String> booking = [
    'book', 'reserve', 'reservation', 'confirm', 'available', 'availability'
  ];

  static const List<String> dates = [
    'when', 'date', 'check-in', 'checkout', 'check in', 'check out',
    'arrive', 'arrival', 'departure', 'stay', 'night', 'nights'
  ];

  static const List<String> pricing = [
    'price', 'cost', 'rate', 'fee', 'charge', 'payment', 'pay',
    'total', 'how much', 'expensive', 'cheap', 'discount', 'deal'
  ];

  static const List<String> guests = [
    'guest', 'people', 'person', 'adults', 'children', 'kids',
    'family', 'group', 'we are'
  ];

  static const List<String> amenities = [
    'wifi', 'parking', 'pool', 'kitchen', 'bathroom', 'bedroom',
    'bed', 'air conditioning', 'heating', 'tv', 'washer', 'dryer'
  ];

  static const List<String> location = [
    'address', 'location', 'directions', 'nearby', 'close to',
    'distance', 'how far', 'walk', 'drive'
  ];

  // Urgency indicators
  static const List<String> urgency = [
    'urgent', 'asap', 'immediately', 'tonight', 'today',
    'tomorrow', 'this weekend', 'need now'
  ];

  // Commitment language
  static const List<String> commitment = [
    'definitely', 'sure', 'yes', 'okay', 'great', 'perfect',
    'sounds good', "let's do it", "i'll take it"
  ];
}

/// Question indicators
const List<String> questionIndicators = [
  '?', 'how', 'what', 'when', 'where', 'which', 'who', 'why',
  'can', 'could', 'would', 'is', 'are', 'do', 'does'
];

/// Positive sentiment keywords
const List<String> positiveKeywords = [
  'great', 'perfect', 'excellent', 'wonderful', 'amazing',
  'beautiful', 'love', 'fantastic', 'awesome', 'nice', 'good'
];

/// Negative sentiment keywords
const List<String> negativeKeywords = [
  'bad', 'terrible', 'horrible', 'disappointing', 'poor',
  'worst', 'awful', 'unfortunately', 'problem', 'issue', 'complaint'
];

/// Intent signals with scores
class IntentSignals {
  final double priceInquiry;
  final double datesMentioned;
  final double guestCountMentioned;
  final double specificQuestions;
  final double bookingLanguage;
  final double urgencyIndicators;
  final double commitmentLanguage;
  final double overallIntent;

  IntentSignals({
    required this.priceInquiry,
    required this.datesMentioned,
    required this.guestCountMentioned,
    required this.specificQuestions,
    required this.bookingLanguage,
    required this.urgencyIndicators,
    required this.commitmentLanguage,
    required this.overallIntent,
  });

  Map<String, dynamic> toMap() => {
    'priceInquiry': priceInquiry,
    'datesMentioned': datesMentioned,
    'guestCountMentioned': guestCountMentioned,
    'specificQuestions': specificQuestions,
    'bookingLanguage': bookingLanguage,
    'urgencyIndicators': urgencyIndicators,
    'commitmentLanguage': commitmentLanguage,
    'overallIntent': overallIntent,
  };

  factory IntentSignals.fromMap(Map<String, dynamic> map) => IntentSignals(
    priceInquiry: (map['priceInquiry'] ?? 0).toDouble(),
    datesMentioned: (map['datesMentioned'] ?? 0).toDouble(),
    guestCountMentioned: (map['guestCountMentioned'] ?? 0).toDouble(),
    specificQuestions: (map['specificQuestions'] ?? 0).toDouble(),
    bookingLanguage: (map['bookingLanguage'] ?? 0).toDouble(),
    urgencyIndicators: (map['urgencyIndicators'] ?? 0).toDouble(),
    commitmentLanguage: (map['commitmentLanguage'] ?? 0).toDouble(),
    overallIntent: (map['overallIntent'] ?? 0).toDouble(),
  );
}

/// Message content analysis result
class MessageContent {
  final String text;
  final int wordCount;
  final bool hasQuestions;
  final List<String> questionTypes;
  final bool hasExclamation;
  final String tone;

  MessageContent({
    required this.text,
    required this.wordCount,
    required this.hasQuestions,
    required this.questionTypes,
    required this.hasExclamation,
    required this.tone,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'wordCount': wordCount,
    'hasQuestions': hasQuestions,
    'questionTypes': questionTypes,
    'hasExclamation': hasExclamation,
    'tone': tone,
  };

  factory MessageContent.fromMap(Map<String, dynamic> map) => MessageContent(
    text: map['text'] ?? '',
    wordCount: map['wordCount'] ?? 0,
    hasQuestions: map['hasQuestions'] ?? false,
    questionTypes: List<String>.from(map['questionTypes'] ?? []),
    hasExclamation: map['hasExclamation'] ?? false,
    tone: map['tone'] ?? 'neutral',
  );
}

/// Conversation metrics
class ConversationMetrics {
  final int totalMessages;
  final int guestMessages;
  final int hostMessages;
  final Map<String, double> avgResponseTime;
  final double conversationDuration;
  final double engagementScore;
  final List<double> intentProgression;
  final List<String> topicsDiscussed;
  final String sentimentTrend;
  final double highestIntentScore;

  ConversationMetrics({
    required this.totalMessages,
    required this.guestMessages,
    required this.hostMessages,
    required this.avgResponseTime,
    required this.conversationDuration,
    required this.engagementScore,
    required this.intentProgression,
    required this.topicsDiscussed,
    required this.sentimentTrend,
    required this.highestIntentScore,
  });

  Map<String, dynamic> toMap() => {
    'totalMessages': totalMessages,
    'guestMessages': guestMessages,
    'hostMessages': hostMessages,
    'avgResponseTime': avgResponseTime,
    'conversationDuration': conversationDuration,
    'engagementScore': engagementScore,
    'intentProgression': intentProgression,
    'topicsDiscussed': topicsDiscussed,
    'sentimentTrend': sentimentTrend,
    'highestIntentScore': highestIntentScore,
  };

  factory ConversationMetrics.fromMap(Map<String, dynamic> map) {
    final avgResponseTimeData = map['avgResponseTime'];
    Map<String, double> avgResponseTime = {'host': 0, 'guest': 0};

    if (avgResponseTimeData is Map) {
      avgResponseTime = {
        'host': (avgResponseTimeData['host'] ?? 0).toDouble(),
        'guest': (avgResponseTimeData['guest'] ?? 0).toDouble(),
      };
    }

    return ConversationMetrics(
      totalMessages: map['totalMessages'] ?? 0,
      guestMessages: map['guestMessages'] ?? 0,
      hostMessages: map['hostMessages'] ?? 0,
      avgResponseTime: avgResponseTime,
      conversationDuration: (map['conversationDuration'] ?? 0).toDouble(),
      engagementScore: (map['engagementScore'] ?? 0).toDouble(),
      intentProgression: List<double>.from(
        (map['intentProgression'] ?? []).map((e) => (e as num).toDouble())
      ),
      topicsDiscussed: List<String>.from(map['topicsDiscussed'] ?? []),
      sentimentTrend: map['sentimentTrend'] ?? 'neutral',
      highestIntentScore: (map['highestIntentScore'] ?? 0).toDouble(),
    );
  }
}

/// Conversation analytics data
class ConversationAnalytics {
  final String chatId;
  final Map<String, String> participants;
  final List<Map<String, dynamic>> messages;
  final ConversationMetrics conversationMetrics;
  final Map<String, dynamic> outcome;
  final Map<String, dynamic> metadata;

  ConversationAnalytics({
    required this.chatId,
    required this.participants,
    required this.messages,
    required this.conversationMetrics,
    required this.outcome,
    required this.metadata,
  });

  factory ConversationAnalytics.fromMap(Map<String, dynamic> map) {
    return ConversationAnalytics(
      chatId: map['chatId'] ?? '',
      participants: Map<String, String>.from(map['participants'] ?? {}),
      messages: List<Map<String, dynamic>>.from(map['messages'] ?? []),
      conversationMetrics: ConversationMetrics.fromMap(
        map['conversationMetrics'] ?? {}
      ),
      outcome: Map<String, dynamic>.from(map['outcome'] ?? {}),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Conversation Analytics Service
class ConversationAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate keyword match score
  double _calculateKeywordScore(String text, List<String> keywords) {
    int matches = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        matches++;
      }
    }
    // Normalize score (more matches = higher score, but cap at 1.0)
    final maxScore = (keywords.length * 0.3).clamp(1.0, double.infinity);
    return (matches / maxScore).clamp(0.0, 1.0);
  }

  /// Analyze message content for booking intent signals
  IntentSignals detectIntentSignals(String text) {
    final lowerText = text.toLowerCase();

    // Calculate intent scores based on keyword presence
    final priceInquiry = _calculateKeywordScore(lowerText, IntentKeywords.pricing);
    final datesMentioned = _calculateKeywordScore(lowerText, IntentKeywords.dates);
    final guestCountMentioned = _calculateKeywordScore(lowerText, IntentKeywords.guests);
    final specificQuestions = _calculateKeywordScore(
      lowerText,
      [...IntentKeywords.amenities, ...IntentKeywords.location]
    );
    final bookingLanguage = _calculateKeywordScore(lowerText, IntentKeywords.booking);
    final urgencyIndicators = _calculateKeywordScore(lowerText, IntentKeywords.urgency);
    final commitmentLanguage = _calculateKeywordScore(lowerText, IntentKeywords.commitment);

    // Overall intent score (weighted average)
    final overallIntent = (
      bookingLanguage * 0.3 +
      datesMentioned * 0.25 +
      priceInquiry * 0.15 +
      guestCountMentioned * 0.1 +
      specificQuestions * 0.1 +
      urgencyIndicators * 0.05 +
      commitmentLanguage * 0.05
    ).clamp(0.0, 1.0);

    return IntentSignals(
      priceInquiry: priceInquiry,
      datesMentioned: datesMentioned,
      guestCountMentioned: guestCountMentioned,
      specificQuestions: specificQuestions,
      bookingLanguage: bookingLanguage,
      urgencyIndicators: urgencyIndicators,
      commitmentLanguage: commitmentLanguage,
      overallIntent: overallIntent,
    );
  }

  /// Analyze message content
  MessageContent analyzeMessageContent(String text) {
    final lowerText = text.toLowerCase();
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // Detect questions
    final hasQuestions = text.contains('?') ||
        questionIndicators.any((indicator) => lowerText.contains(indicator));

    // Categorize question types
    final questionTypes = <String>[];
    if (hasQuestions) {
      if (IntentKeywords.pricing.any((kw) => lowerText.contains(kw))) {
        questionTypes.add('price');
      }
      if (IntentKeywords.dates.any((kw) => lowerText.contains(kw))) {
        questionTypes.add('availability');
      }
      if (IntentKeywords.amenities.any((kw) => lowerText.contains(kw))) {
        questionTypes.add('amenities');
      }
      if (IntentKeywords.location.any((kw) => lowerText.contains(kw))) {
        questionTypes.add('location');
      }
      if (IntentKeywords.guests.any((kw) => lowerText.contains(kw))) {
        questionTypes.add('capacity');
      }
    }

    // Detect exclamations
    final hasExclamation = text.contains('!');

    // Determine tone
    String tone = 'neutral';
    if (positiveKeywords.any((kw) => lowerText.contains(kw))) {
      tone = hasExclamation ? 'excited' : 'positive';
    } else if (negativeKeywords.any((kw) => lowerText.contains(kw))) {
      tone = 'negative';
    } else if (hasExclamation) {
      tone = 'enthusiastic';
    } else if (lowerText.contains('please') || lowerText.contains('thank')) {
      tone = 'polite';
    }

    return MessageContent(
      text: text,
      wordCount: words.length,
      hasQuestions: hasQuestions,
      questionTypes: questionTypes,
      hasExclamation: hasExclamation,
      tone: tone,
    );
  }

  /// Calculate sentiment score for a message
  double calculateSentiment(String text) {
    final lowerText = text.toLowerCase();

    int positiveCount = 0;
    int negativeCount = 0;

    for (final keyword in positiveKeywords) {
      if (lowerText.contains(keyword)) positiveCount++;
    }

    for (final keyword in negativeKeywords) {
      if (lowerText.contains(keyword)) negativeCount++;
    }

    final totalSentimentWords = positiveCount + negativeCount;
    if (totalSentimentWords == 0) return 0;

    return (positiveCount - negativeCount) / totalSentimentWords;
  }

  /// Track a new message in conversation analytics
  Future<Map<String, dynamic>?> trackMessage({
    required String chatId,
    required String messageId,
    required String text,
    required String sender,
    required String guestId,
    required String hostId,
    required String listingId,
    required DateTime timestamp,
    bool isFirstMessage = false,
    double responseTime = 0,
  }) async {
    try {
      // Analyze message content
      final content = analyzeMessageContent(text);
      final intentSignals = detectIntentSignals(text);
      final sentiment = calculateSentiment(text);

      // Create message analytics object
      final messageAnalytics = {
        'messageId': messageId,
        'timestamp': Timestamp.fromDate(timestamp),
        'sender': sender,
        'content': content.toMap(),
        'intentSignals': intentSignals.toMap(),
        'sentiment': sentiment,
        'responseTime': responseTime,
        'isFirstMessage': isFirstMessage,
      };

      // Get or create conversation analytics document
      final analyticsRef = _firestore.collection('conversationAnalytics').doc(chatId);
      final analyticsDoc = await analyticsRef.get();

      if (!analyticsDoc.exists) {
        // Create new analytics document
        await analyticsRef.set({
          'chatId': chatId,
          'participants': {
            'guestId': guestId,
            'hostId': hostId,
            'listingId': listingId,
          },
          'messages': [messageAnalytics],
          'conversationMetrics': {
            'totalMessages': 1,
            'guestMessages': sender == 'guest' ? 1 : 0,
            'hostMessages': sender == 'host' ? 1 : 0,
            'avgResponseTime': {
              'host': sender == 'host' && responseTime > 0 ? responseTime : 0,
              'guest': sender == 'guest' && responseTime > 0 ? responseTime : 0,
            },
            'conversationDuration': 0,
            'engagementScore': intentSignals.overallIntent,
            'intentProgression': [intentSignals.overallIntent],
            'topicsDiscussed': content.questionTypes,
            'sentimentTrend': sentiment > 0.3 ? 'positive' :
                             sentiment < -0.3 ? 'negative' : 'neutral',
            'highestIntentScore': intentSignals.overallIntent,
          },
          'outcome': {
            'resultedInBooking': false,
            'bookingId': null,
            'timeToBooking': null,
            'reasonForNoBooking': null,
            'ghostedByGuest': false,
            'ghostedByHost': false,
          },
          'metadata': {
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageAt': FieldValue.serverTimestamp(),
            'conversationStatus': 'active',
            'isTrainingData': true,
            'labeledBy': 'system',
            'confidenceScore': 0.0,
          },
        });
      } else {
        // Update existing analytics document
        final existingData = analyticsDoc.data() ?? {};
        final messages = List<Map<String, dynamic>>.from(existingData['messages'] ?? []);

        // Add new message
        messages.add(messageAnalytics);

        // Calculate updated metrics
        final guestMessages = messages.where((m) => m['sender'] == 'guest').length;
        final hostMessages = messages.where((m) => m['sender'] == 'host').length;

        // Calculate average response times
        final hostResponseTimes = messages
            .where((m) => m['sender'] == 'host' && (m['responseTime'] ?? 0) > 0)
            .map((m) => (m['responseTime'] as num).toDouble())
            .toList();
        final guestResponseTimes = messages
            .where((m) => m['sender'] == 'guest' && (m['responseTime'] ?? 0) > 0)
            .map((m) => (m['responseTime'] as num).toDouble())
            .toList();

        final avgHostResponseTime = hostResponseTimes.isNotEmpty
            ? hostResponseTimes.reduce((a, b) => a + b) / hostResponseTimes.length
            : 0.0;

        final avgGuestResponseTime = guestResponseTimes.isNotEmpty
            ? guestResponseTimes.reduce((a, b) => a + b) / guestResponseTimes.length
            : 0.0;

        // Calculate conversation duration
        final firstMessage = messages.first;
        final lastMessage = messages.last;

        DateTime firstTimestamp;
        DateTime lastTimestamp;

        if (firstMessage['timestamp'] is Timestamp) {
          firstTimestamp = (firstMessage['timestamp'] as Timestamp).toDate();
        } else {
          firstTimestamp = DateTime.now();
        }

        if (lastMessage['timestamp'] is Timestamp) {
          lastTimestamp = (lastMessage['timestamp'] as Timestamp).toDate();
        } else {
          lastTimestamp = DateTime.now();
        }

        final conversationDuration =
            (lastTimestamp.millisecondsSinceEpoch - firstTimestamp.millisecondsSinceEpoch) / 1000;

        // Calculate engagement score (average of all intent scores)
        final allIntentScores = messages
            .map((m) => ((m['intentSignals'] as Map?)?['overallIntent'] ?? 0).toDouble())
            .toList();
        final avgIntentScore = allIntentScores.isNotEmpty
            ? allIntentScores.reduce((a, b) => a + b) / allIntentScores.length
            : 0.0;

        // Track intent progression
        final bucketSize = (messages.length / 5).floor().clamp(1, messages.length);
        final intentProgression = <double>[];
        for (int i = 0; i < messages.length; i += bucketSize) {
          final bucket = messages.sublist(i, (i + bucketSize).clamp(0, messages.length));
          final bucketAvg = bucket
              .map((m) => ((m['intentSignals'] as Map?)?['overallIntent'] ?? 0).toDouble())
              .reduce((a, b) => a + b) / bucket.length;
          intentProgression.add(bucketAvg);
        }

        // Collect all topics discussed
        final allTopics = messages
            .expand((m) => List<String>.from((m['content'] as Map?)?['questionTypes'] ?? []))
            .toSet()
            .toList();

        // Calculate overall sentiment trend
        final avgSentiment = messages
            .map((m) => (m['sentiment'] ?? 0).toDouble())
            .reduce((a, b) => a + b) / messages.length;
        final sentimentTrend = avgSentiment > 0.3 ? 'positive' :
                              avgSentiment < -0.3 ? 'negative' : 'neutral';

        // Find highest intent score
        final highestIntentScore = allIntentScores.reduce((a, b) => a > b ? a : b);

        // Update document
        await analyticsRef.update({
          'messages': messages,
          'conversationMetrics': {
            'totalMessages': messages.length,
            'guestMessages': guestMessages,
            'hostMessages': hostMessages,
            'avgResponseTime': {
              'host': avgHostResponseTime,
              'guest': avgGuestResponseTime,
            },
            'conversationDuration': conversationDuration,
            'engagementScore': avgIntentScore,
            'intentProgression': intentProgression,
            'topicsDiscussed': allTopics,
            'sentimentTrend': sentimentTrend,
            'highestIntentScore': highestIntentScore,
          },
          'metadata.lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      return messageAnalytics;
    } catch (error) {
      print('Error tracking message analytics: $error');
      // Don't throw - analytics should never break the app
      return null;
    }
  }

  /// Mark a conversation as resulting in a booking
  Future<void> markConversationAsBooked(
    String chatId,
    String bookingId, {
    Map<String, dynamic>? pricingData,
  }) async {
    try {
      final analyticsRef = _firestore.collection('conversationAnalytics').doc(chatId);
      final analyticsDoc = await analyticsRef.get();

      if (!analyticsDoc.exists) {
        print('No analytics found for chat: $chatId');
        return;
      }

      final data = analyticsDoc.data() ?? {};
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

      if (messages.isEmpty) return;

      final firstMessage = messages.first;

      // Calculate time to booking
      DateTime firstTimestamp;
      if (firstMessage['timestamp'] is Timestamp) {
        firstTimestamp = (firstMessage['timestamp'] as Timestamp).toDate();
      } else {
        firstTimestamp = DateTime.now();
      }

      final timeToBooking =
          (DateTime.now().millisecondsSinceEpoch - firstTimestamp.millisecondsSinceEpoch) / 1000;

      // Prepare pricing analytics
      final pricing = pricingData ?? {};
      final listingPrice = (pricing['listingPrice'] ?? 0).toDouble();
      final totalPrice = (pricing['totalPrice'] ?? 0).toDouble();
      final nights = (pricing['nights'] ?? 1).toInt();

      final pricingAnalytics = {
        'listingPrice': listingPrice,
        'finalPrice': totalPrice,
        'priceVariance': listingPrice > 0 && nights > 0
            ? ((totalPrice - (listingPrice * nights)) / (listingPrice * nights) * 100)
            : 0,
        'dailyRate': pricing['dailyRate'] ?? listingPrice,
        'discountApplied': pricing['discountType'] != null && pricing['discountType'] != 'none',
        'discountType': pricing['discountType'] ?? 'none',
        'discountValue': pricing['discountValue'] ?? 0,
        'nights': nights,
        'guestCount': pricing['guests'] ?? 0,
      };

      await analyticsRef.update({
        'outcome.resultedInBooking': true,
        'outcome.bookingId': bookingId,
        'outcome.timeToBooking': timeToBooking,
        'outcome.pricingAnalytics': pricingAnalytics,
        'metadata.conversationStatus': 'booked',
        'metadata.lastMessageAt': FieldValue.serverTimestamp(),
      });

      print('✅ Conversation marked as booked: $chatId');
    } catch (error) {
      print('Error marking conversation as booked: $error');
    }
  }

  /// Get booking probability for a conversation
  Future<double> getBookingProbability(String chatId) async {
    try {
      final analyticsRef = _firestore.collection('conversationAnalytics').doc(chatId);
      final analyticsDoc = await analyticsRef.get();

      if (!analyticsDoc.exists) {
        return 0;
      }

      final data = analyticsDoc.data() ?? {};
      final metrics = data['conversationMetrics'] as Map<String, dynamic>? ?? {};

      // Simple rule-based probability calculation (MVP)
      double probability = 0;

      // High intent score = higher probability
      final highestIntentScore = (metrics['highestIntentScore'] ?? 0).toDouble();
      probability += highestIntentScore * 0.4;

      // Multiple messages = engaged conversation
      final totalMessages = (metrics['totalMessages'] ?? 0).toInt();
      final messageCountScore = (totalMessages / 10).clamp(0.0, 1.0);
      probability += messageCountScore * 0.2;

      // Fast response time = higher interest
      final avgResponseTimeData = metrics['avgResponseTime'] as Map<String, dynamic>? ?? {};
      final hostResponseTime = (avgResponseTimeData['host'] ?? 1000).toDouble();
      final guestResponseTime = (avgResponseTimeData['guest'] ?? 1000).toDouble();
      final avgResponseTime = hostResponseTime + guestResponseTime;
      final responseTimeScore = (1 - (avgResponseTime / 3600)).clamp(0.0, 1.0);
      probability += responseTimeScore * 0.2;

      // Positive sentiment = higher probability
      final sentimentTrend = metrics['sentimentTrend'] ?? 'neutral';
      final sentimentScore = sentimentTrend == 'positive' ? 0.8 :
                           sentimentTrend == 'neutral' ? 0.5 : 0.2;
      probability += sentimentScore * 0.1;

      // Many topics discussed = serious inquiry
      final topicsDiscussed = List<String>.from(metrics['topicsDiscussed'] ?? []);
      final topicsScore = (topicsDiscussed.length / 3).clamp(0.0, 1.0);
      probability += topicsScore * 0.1;

      return probability.clamp(0.0, 1.0);
    } catch (error) {
      print('Error calculating booking probability: $error');
      return 0;
    }
  }

  /// Get conversation analytics
  Future<ConversationAnalytics?> getConversationAnalytics(String chatId) async {
    try {
      final analyticsRef = _firestore.collection('conversationAnalytics').doc(chatId);
      final analyticsDoc = await analyticsRef.get();

      if (!analyticsDoc.exists) {
        return null;
      }

      return ConversationAnalytics.fromMap(analyticsDoc.data() ?? {});
    } catch (error) {
      print('Error getting conversation analytics: $error');
      return null;
    }
  }
}
