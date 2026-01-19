/// Role of the message sender in AI chat
enum AIChatRole {
  user,
  assistant,
  system;

  String get value {
    switch (this) {
      case AIChatRole.user:
        return 'user';
      case AIChatRole.assistant:
        return 'assistant';
      case AIChatRole.system:
        return 'system';
    }
  }

  static AIChatRole fromString(String value) {
    switch (value) {
      case 'user':
        return AIChatRole.user;
      case 'assistant':
        return AIChatRole.assistant;
      case 'system':
        return AIChatRole.system;
      default:
        return AIChatRole.user;
    }
  }
}

/// Chat message entity for AI conversations
class AIChatMessage {
  final String id;
  final String conversationId;
  final String content;
  final AIChatRole role;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final List<String> listingIds;

  const AIChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.metadata,
    this.listingIds = const [],
  });

  /// Create from Firestore document
  factory AIChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return AIChatMessage(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      role: AIChatRole.fromString(map['role'] as String? ?? 'user'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      listingIds: List<String>.from(map['listingIds'] ?? []),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'content': content,
      'role': role.value,
      'createdAt': createdAt,
      if (metadata != null) 'metadata': metadata,
      if (listingIds.isNotEmpty) 'listingIds': listingIds,
    };
  }

  /// Create a user message
  factory AIChatMessage.user({
    required String conversationId,
    required String content,
    List<String> listingIds = const [],
  }) {
    return AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      content: content,
      role: AIChatRole.user,
      createdAt: DateTime.now(),
      listingIds: listingIds,
    );
  }

  /// Create an assistant message
  factory AIChatMessage.assistant({
    required String conversationId,
    required String content,
    List<String> listingIds = const [],
    Map<String, dynamic>? metadata,
  }) {
    return AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      content: content,
      role: AIChatRole.assistant,
      createdAt: DateTime.now(),
      listingIds: listingIds,
      metadata: metadata,
    );
  }

  /// Check if message is from user
  bool get isUser => role == AIChatRole.user;

  /// Check if message is from assistant
  bool get isAssistant => role == AIChatRole.assistant;

  AIChatMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    AIChatRole? role,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    List<String>? listingIds,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      listingIds: listingIds ?? this.listingIds,
    );
  }
}
